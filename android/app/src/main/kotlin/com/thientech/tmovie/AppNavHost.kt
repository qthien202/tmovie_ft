package com.thientech.tmovie

import androidx.compose.animation.SharedTransitionLayout
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
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

/**
 * Thin line icons (Lucide, ISC licence; 24-unit grid): the stock Material glyphs read heavy. The
 * selected tab draws the same shape with a bolder stroke.
 */
private fun lineIcon(name: String, stroke: Float, vararg paths: String): ImageVector =
    ImageVector.Builder(name, 24.dp, 24.dp, 24f, 24f).apply {
        paths.forEach {
            addPath(
                PathParser().parsePathString(it).toNodes(), stroke = SolidColor(Color.White), strokeLineWidth = stroke,
                strokeLineCap = StrokeCap.Round, strokeLineJoin = StrokeJoin.Round,
            )
        }
    }.build()

private class TabItem(val route: Any, val label: String, vararg paths: String) {
    val icon = lineIcon(label, 1.6f, *paths)
    val selectedIcon = lineIcon(label, 2.3f, *paths)
}

private val tabs = listOf(
    TabItem(HomeRoute, "Trang chủ", "M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8",
        "M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"),
    TabItem(NewHotRoute, "Mới & Hot",
        "M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"),
    TabItem(LiveRoute, "Truyền hình", "M4 7h16a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z", "M17 2l-5 5-5-5"),
    TabItem(SearchRoute, "Tìm kiếm", "M3 11a8 8 0 1 0 16 0a8 8 0 1 0-16 0", "M21 21l-4.3-4.3"),
    TabItem(ProfileRoute, "Của tôi", "M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2", "M8 7a4 4 0 1 0 8 0a4 4 0 1 0-8 0"),
)

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
 * Docked tab bar in the style of the big streaming apps (Netflix, Disney+): solid, edge to edge,
 * a hairline on top, thin line icons; the selected tab turns white with a bolder stroke. No glass,
 * no floating capsule, no glow.
 */
@Composable
private fun BottomBar(selected: (TabItem) -> Boolean, onSelect: (TabItem) -> Unit, modifier: Modifier = Modifier) {
    val haptics = LocalHapticFeedback.current
    Column(modifier.fillMaxWidth().background(TMovieColors.Canvas)) {
        Box(Modifier.fillMaxWidth().height(0.5.dp).background(Color.White.copy(alpha = 0.1f)))
        Row(Modifier.fillMaxWidth().navigationBarsPadding().height(58.dp)) {
            tabs.forEach { tab ->
                val on = selected(tab)
                val tint by animateColorAsState(if (on) Color.White else Color.White.copy(alpha = 0.5f), tween(180), label = "tab")
                Column(
                    Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .clickable(remember { MutableInteractionSource() }, indication = null) {
                            if (!on) haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            onSelect(tab)
                        }
                        .semantics { role = Role.Tab; this.selected = on },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Icon(if (on) tab.selectedIcon else tab.icon, null, tint = tint, modifier = Modifier.size(24.dp))
                    Text(
                        tab.label, color = tint, fontSize = 10.sp, maxLines = 1, softWrap = false,
                        fontWeight = if (on) FontWeight.SemiBold else FontWeight.Normal,
                        modifier = Modifier.padding(top = 4.dp),
                    )
                }
            }
        }
    }
}
