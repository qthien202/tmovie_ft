package com.thientech.tmovie.tv

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.LiveTv
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.LiveTv
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieTheme
import com.thientech.tmovie.core.designsystem.Wordmark
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.ui.UpdatePrompt

class TvActivity : ComponentActivity() {
    /** A film opened from the TV home screen's Watch Next row. */
    private var link by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        link = intent.filmSlug()
        setContent {
            TMovieTheme {
                TvApp(onExit = ::finish, link = link, onLinkOpened = { link = null })
                UpdatePrompt(BuildConfig.VERSION_NAME, BuildConfig.DEBUG, R.mipmap.ic_launcher_foreground, keyword = "tv")
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.filmSlug()?.let { link = it }
    }
}

private fun Intent.filmSlug() = data?.takeIf { it.scheme == "tmovie" && it.host == "film" }?.lastPathSegment

enum class Tab(val label: String, val icon: ImageVector, val selectedIcon: ImageVector) {
    Home("Trang chủ", Icons.Outlined.Home, Icons.Rounded.Home),
    Search("Tìm kiếm", Icons.Outlined.Search, Icons.Rounded.Search),
    Live("Truyền hình", Icons.Outlined.LiveTv, Icons.Rounded.LiveTv),
}

/** What can be stacked over the tabs. */
sealed interface Page {
    data class Film(val film: FilmItem) : Page
    data class Catalog(val title: String, val source: Source) : Page
}

/**
 * Side nav + tab content, with film / list pages stacked on top. Pages under the top one stay composed
 * (scroll and focus intact) but undrawn; Back pops a page and refocuses the card that opened it.
 */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun TvApp(onExit: () -> Unit, link: String? = null, onLinkOpened: () -> Unit = {}) {
    var tab by rememberSaveable { mutableStateOf(Tab.Home) }
    val context = LocalContext.current
    val pages = remember { mutableStateListOf<Page>() }
    var lastBack by remember { mutableLongStateOf(0L) }
    var searchRequest by remember { mutableIntStateOf(0) }
    val openers = remember { mutableListOf<FocusRequester?>() }
    var restore by remember { mutableStateOf<FocusRequester?>(null) }
    val memory = remember { FocusMemory() }
    val navFocus = remember { Tab.entries.associateWith { FocusRequester() } }
    val content = remember { FocusRequester() }
    var navFocused by remember { mutableStateOf(false) }
    val holder = rememberSaveableStateHolder()

    fun push(page: Page) {
        openers += memory.last
        pages += page
    }
    fun open(film: FilmItem) = push(Page.Film(film))
    fun openList(title: String, source: Source) = push(Page.Catalog(title, source))

    // Back: close the top page → step out to the nav → leave a tab for Home → exit.
    fun back() {
        when {
            pages.isNotEmpty() -> { pages.removeAt(pages.lastIndex); restore = openers.removeAt(openers.lastIndex) }
            !navFocused -> runCatching { navFocus.getValue(tab).requestFocus() }
            tab != Tab.Home -> { tab = Tab.Home; runCatching { navFocus.getValue(Tab.Home).requestFocus() } }
            // TV remotes make Back easy to hit by accident: the second press within 2 s exits.
            System.currentTimeMillis() - lastBack < 2_000 -> onExit()
            else -> {
                lastBack = System.currentTimeMillis()
                Toast.makeText(context, "Nhấn Quay lại lần nữa để thoát", Toast.LENGTH_SHORT).show()
            }
        }
    }
    BackHandler(onBack = ::back)
    LaunchedEffect(link) {
        val slug = link ?: return@LaunchedEffect
        pages.clear(); openers.clear()
        open(Library.record(slug)?.film ?: FilmItem(name = "", slug = slug))
        onLinkOpened()
    }
    LaunchedEffect(restore) {
        val r = restore ?: return@LaunchedEffect
        withFrameNanos {}  // after the page leaves the tree
        runCatching { r.requestFocus() }
        restore = null
    }

    CompositionLocalProvider(LocalFocusMemory provides memory) {
        // Back is taken here before focus sees it: Compose spends a focused Back on clearing focus.
        Box(
            Modifier
                .fillMaxSize()
                .background(TMovieColors.Canvas)
                .onPreviewKeyEvent { e ->
                    when (e.key) {
                        Key.Back -> { if (e.type == KeyEventType.KeyUp) back(); true }
                        // The remote's search / mic key: straight to typing a search.
                        Key.Search -> {
                            if (e.type == KeyEventType.KeyUp) { pages.clear(); openers.clear(); tab = Tab.Search; searchRequest++ }
                            true
                        }
                        else -> false
                    }
                },
        ) {
            Box(Modifier.fillMaxSize().graphicsLayer { alpha = if (pages.isEmpty()) 1f else 0f }) {
                // ► from the nav lands back on the card focused last in this tab (or its first one).
                Box(Modifier.fillMaxSize().focusRequester(content).focusRestorer().focusGroup()) {
                    holder.SaveableStateProvider(tab) {
                        when (tab) {
                            Tab.Home -> HomeTab(::open, ::openList)
                            Tab.Search -> SearchTab(::open, searchRequest)
                            Tab.Live -> LiveTab()
                        }
                    }
                }
                SideNav(tab, navFocus, onFocused = { navFocused = it }, onRight = { runCatching { content.requestFocus() } }) { tab = it }
            }
            pages.forEachIndexed { i, page ->
                // Each page traps focus so the remote can't wander into what's under it.
                Box(
                    Modifier
                        .fillMaxSize()
                        .graphicsLayer { alpha = if (i == pages.lastIndex) 1f else 0f }
                        .focusProperties { exit = { FocusRequester.Cancel } }
                        .focusGroup(),
                ) {
                    when (page) {
                        is Page.Film -> DetailPage(page.film, top = i == pages.lastIndex, onOpen = ::open)
                        is Page.Catalog -> Box(Modifier.fillMaxSize().background(TMovieColors.Canvas)) { CatalogPage(page.title, page.source, ::open) }
                    }
                }
            }
        }
    }
}

/**
 * Netflix's TV menu: a quiet icon rail; focusing it dims the whole screen (darkest on the left)
 * and spells out the tabs. Coming back into the nav lands on the current tab.
 *
 * Only the dim fades; the rail snaps between widths, as an animated width relayouts every frame.
 */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun SideNav(tab: Tab, focus: Map<Tab, FocusRequester>, onFocused: (Boolean) -> Unit, onRight: () -> Unit, onSelect: (Tab) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    val shown by animateFloatAsState(if (expanded) 1f else 0f, tween(200), label = "nav")
    Box(Modifier.fillMaxSize()) {
        // Collapsed: a short fade so rows scrolling left pass under the icons cleanly.
        Box(Modifier.fillMaxHeight().width(Tv.Start).background(Brush.horizontalGradient(listOf(TMovieColors.Canvas, TMovieColors.Canvas.copy(alpha = 0.8f), Color.Transparent))))
        Box(
            Modifier.fillMaxSize().graphicsLayer { alpha = shown }.background(
                Brush.horizontalGradient(0f to TMovieColors.Canvas, 0.28f to TMovieColors.Canvas.copy(alpha = 0.96f), 0.6f to TMovieColors.Canvas.copy(alpha = 0.75f), 1f to TMovieColors.Canvas.copy(alpha = 0.6f)),
            ),
        )
        Column(
            Modifier
                .fillMaxHeight()
                .width(if (expanded) 320.dp else 80.dp)
                .onFocusChanged { expanded = it.hasFocus; onFocused(it.hasFocus) }
                // The expanded nav overlaps the content, which leaves nothing "to the right" for focus search.
                .onPreviewKeyEvent { e -> (e.key == Key.DirectionRight).also { if (it && e.type == KeyEventType.KeyDown) onRight() } }
                .focusRestorer(focus.getValue(tab))
                .focusGroup()
                .padding(start = 16.dp, top = 40.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Box(Modifier.height(36.dp).padding(start = 16.dp).graphicsLayer { alpha = shown }) {
                if (expanded) Wordmark(size = 24, colors = Tv.LogoColors)
            }
            Spacer(Modifier.weight(1f))
            Tab.entries.forEach { t -> NavItem(t, t == tab, expanded, shown, focus.getValue(t)) { onSelect(t) } }
            Spacer(Modifier.weight(1.4f))
        }
    }
}

@Composable
private fun NavItem(tab: Tab, selected: Boolean, expanded: Boolean, shown: Float, focus: FocusRequester, onSelect: () -> Unit) {
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    // Moving onto a tab opens it, like Google TV's nav.
    LaunchedEffect(focused) { if (focused && !selected) onSelect() }
    val fg = if (focused || selected) Color.White else Color.White.copy(alpha = 0.5f)
    Row(
        Modifier
            .fillMaxWidth()
            .padding(end = 16.dp)
            .height(52.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(if (focused) Color.White.copy(alpha = 0.14f) else Color.Transparent)
            .focusRequester(focus)
            .clickable(interaction, indication = null, onClick = onSelect),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // The current tab's mark, collapsed or not.
        Box(Modifier.padding(start = 4.dp).size(3.dp, 22.dp).clip(CircleShape).background(if (selected) TMovieColors.BrandLight else Color.Transparent))
        Icon(if (selected || focused) tab.selectedIcon else tab.icon, tab.label, tint = fg, modifier = Modifier.padding(start = 9.dp).size(26.dp))
        if (expanded) {
            Text(tab.label, color = fg, fontSize = 20.sp, fontWeight = if (focused || selected) FontWeight.Bold else FontWeight.Medium,
                maxLines = 1, modifier = Modifier.padding(start = 18.dp).graphicsLayer { alpha = shown })
        }
    }
}
