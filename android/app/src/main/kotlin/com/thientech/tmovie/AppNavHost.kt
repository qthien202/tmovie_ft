package com.thientech.tmovie

import androidx.compose.animation.SharedTransitionLayout
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.offset
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.LiveTv
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.LiveTv
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmCategory
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.player.Player
import com.thientech.tmovie.core.ui.AccountCard
import com.thientech.tmovie.core.ui.FilmRoute
import com.thientech.tmovie.core.ui.HomeRoute
import com.thientech.tmovie.core.ui.ListRoute
import com.thientech.tmovie.core.ui.LiveRoute
import com.thientech.tmovie.core.ui.LocalAnimatedScope
import com.thientech.tmovie.core.ui.LocalNavigator
import com.thientech.tmovie.core.ui.LocalSharedScope
import com.thientech.tmovie.core.ui.Navigator
import com.thientech.tmovie.core.ui.NewHotRoute
import com.thientech.tmovie.core.ui.ProfileRoute
import com.thientech.tmovie.core.ui.SearchRoute
import com.thientech.tmovie.core.ui.route
import com.thientech.tmovie.feature.browse.CatalogScreen
import com.thientech.tmovie.feature.browse.LiveTvScreen
import com.thientech.tmovie.feature.browse.NewHotScreen
import com.thientech.tmovie.feature.browse.SearchScreen
import com.thientech.tmovie.feature.detail.DetailScreen
import com.thientech.tmovie.feature.home.HomeScreen
import com.thientech.tmovie.feature.profile.ProfileScreen

/** Outlined icon at rest, the rounded filled one when selected (as iOS's SF Symbols do). */
private data class TabItem(val route: Any, val label: String, val icon: ImageVector, val selectedIcon: ImageVector)

private val tabs = listOf(
    TabItem(HomeRoute, "Trang chủ", Icons.Outlined.Home, Icons.Rounded.Home),
    TabItem(NewHotRoute, "Mới & Hot", Icons.Outlined.LocalFireDepartment, Icons.Rounded.LocalFireDepartment),
    TabItem(LiveRoute, "Truyền hình", Icons.Outlined.LiveTv, Icons.Rounded.LiveTv),
    TabItem(SearchRoute, "Tìm kiếm", Icons.Outlined.Search, Icons.Rounded.Search),
    TabItem(ProfileRoute, "Của tôi", Icons.Outlined.Person, Icons.Rounded.Person),
)
private val TabWidth = 70.dp
private val TabGap = 2.dp

/**
 * One NavHost for every screen. Features only emit FilmRoute / ListRoute through [LocalNavigator];
 * this maps them to screens and wraps everything in a SharedTransitionLayout for the poster → detail zoom.
 */
@Composable
fun AppNavHost(link: String?, onLinkHandled: () -> Unit) {
    val nav = rememberNavController()
    val context = androidx.compose.ui.platform.LocalContext.current
    val entry by nav.currentBackStackEntryAsState()
    val navigator = remember(nav) {
        Navigator(
            openFilm = { nav.navigate(it) },
            openList = { nav.navigate(it) },
            back = { nav.popBackStack() },
        )
    }

    // tmovie://phim/{slug}[?play=1] and tmovie://the-loai/{slug}.
    LaunchedEffect(link) {
        val uri = link?.let(android.net.Uri::parse) ?: return@LaunchedEffect
        val slug = uri.pathSegments.firstOrNull() ?: return@LaunchedEffect onLinkHandled()
        when (uri.host) {
            "phim" -> runCatching { PhimApi.shared.detail(slug) }.getOrNull()?.let { detail ->
                nav.navigate(detail.toItem().route("link/$slug"))
                // `?play=1` starts (or resumes) playback straight away.
                if (uri.getQueryParameter("play") != null) Player.start(context, detail, fromDetail = true)
            }
            "the-loai" -> {
                val name = runCatching { PhimApi.shared.taxonomy(PhimApi.Taxonomy.Genres) }.getOrDefault(emptyList<FilmCategory>())
                    .firstOrNull { it.slug == slug }?.name ?: slug
                nav.navigate(ListRoute.genre(name, slug))
            }
        }
        onLinkHandled()
    }

    CompositionLocalProvider(LocalNavigator provides navigator) {
        Box(Modifier.fillMaxSize().background(TMovieColors.Canvas)) {
            SharedTransitionLayout {
                CompositionLocalProvider(LocalSharedScope provides this) {
                    NavHost(nav, startDestination = HomeRoute) {
                        composable<HomeRoute> { CompositionLocalProvider(LocalAnimatedScope provides this) { HomeScreen() } }
                        composable<NewHotRoute> { CompositionLocalProvider(LocalAnimatedScope provides this) { NewHotScreen() } }
                        composable<LiveRoute> { LiveTvScreen() }
                        composable<SearchRoute> { CompositionLocalProvider(LocalAnimatedScope provides this) { SearchScreen() } }
                        composable<ProfileRoute> { CompositionLocalProvider(LocalAnimatedScope provides this) { ProfileScreen(account = { AccountCard() }) } }
                        composable<FilmRoute> { back ->
                            CompositionLocalProvider(LocalAnimatedScope provides this) { DetailScreen(back.toRoute()) }
                        }
                        composable<ListRoute> { back ->
                            CompositionLocalProvider(LocalAnimatedScope provides this) { CatalogScreen(back.toRoute()) }
                        }
                    }
                }
            }
            BottomBar(
                selected = { tab -> entry?.destination?.hasRoute(tab.route::class) == true },
                onSelect = { tab ->
                    nav.navigate(tab.route) {
                        popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                },
                modifier = Modifier.align(Alignment.BottomCenter),
            )
        }
    }
}

/**
 * Floating glass tab bar (the Android take on the iOS 26 Liquid Glass bar): one highlight that
 * springs between tabs, thin outlined icons that fill in when selected, a light tick on change.
 */
@Composable
private fun BottomBar(selected: (TabItem) -> Boolean, onSelect: (TabItem) -> Unit, modifier: Modifier = Modifier) {
    val haptics = LocalHapticFeedback.current
    val index = tabs.indexOfFirst(selected)
    val highlightX by animateDpAsState((TabWidth + TabGap) * index.coerceAtLeast(0), spring(dampingRatio = 0.75f, stiffness = 500f), label = "tab")
    Box(
        modifier
            .navigationBarsPadding()
            .padding(horizontal = 8.dp, vertical = 10.dp)
            .clip(CircleShape)
            .background(Color(0xF00B0F12))
            .glass(CircleShape)
            .border(0.5.dp, Color.White.copy(alpha = 0.12f), CircleShape)
            .padding(5.dp),
    ) {
        if (index >= 0) {
            Box(
                Modifier.offset(x = highlightX).width(TabWidth).height(52.dp)
                    .clip(CircleShape).background(Color.White.copy(alpha = 0.12f)),
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(TabGap)) {
            tabs.forEach { tab ->
                val on = selected(tab)
                val tint by animateColorAsState(if (on) TMovieColors.BrandLight else Color.White.copy(alpha = 0.62f), label = "tint")
                val scale by animateFloatAsState(if (on) 1f else 0.94f, spring(dampingRatio = 0.6f, stiffness = 600f), label = "scale")
                Column(
                    Modifier
                        .width(TabWidth)
                        .height(52.dp)
                        .clip(CircleShape)
                        .clickable(remember { MutableInteractionSource() }, indication = null) {
                            if (!on) haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            onSelect(tab)
                        }
                        .graphicsLayer { scaleX = scale; scaleY = scale },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Icon(if (on) tab.selectedIcon else tab.icon, null, tint = tint, modifier = Modifier.size(22.dp))
                    Text(
                        tab.label, color = tint, fontSize = 10.5.sp, maxLines = 1, softWrap = false,
                        fontWeight = if (on) FontWeight.SemiBold else FontWeight.Medium,
                        modifier = Modifier.padding(top = 3.dp),
                    )
                }
            }
        }
    }
}
