package com.thientech.tmovie

import androidx.compose.animation.SharedTransitionLayout
import androidx.compose.animation.core.animateFloatAsState
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
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.VideoLibrary
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
import com.thientech.tmovie.core.ui.AccountCard
import com.thientech.tmovie.core.ui.FilmRoute
import com.thientech.tmovie.core.ui.HomeRoute
import com.thientech.tmovie.core.ui.ListRoute
import com.thientech.tmovie.core.ui.LocalAnimatedScope
import com.thientech.tmovie.core.ui.LocalNavigator
import com.thientech.tmovie.core.ui.LocalSharedScope
import com.thientech.tmovie.core.ui.Navigator
import com.thientech.tmovie.core.ui.NewHotRoute
import com.thientech.tmovie.core.ui.ProfileRoute
import com.thientech.tmovie.core.ui.SearchRoute
import com.thientech.tmovie.core.ui.route
import com.thientech.tmovie.feature.browse.CatalogScreen
import com.thientech.tmovie.feature.browse.NewHotScreen
import com.thientech.tmovie.feature.browse.SearchScreen
import com.thientech.tmovie.feature.detail.DetailScreen
import com.thientech.tmovie.feature.home.HomeScreen
import com.thientech.tmovie.feature.profile.ProfileScreen

private data class TabItem(val route: Any, val label: String, val icon: ImageVector)

private val tabs = listOf(
    TabItem(HomeRoute, "Trang chủ", Icons.Filled.Home),
    TabItem(NewHotRoute, "Mới & Hot", Icons.Filled.VideoLibrary),
    TabItem(SearchRoute, "Tìm kiếm", Icons.Filled.Search),
    TabItem(ProfileRoute, "Của tôi", Icons.Filled.AccountCircle),
)

/**
 * One NavHost for every screen. Features only emit FilmRoute / ListRoute through [LocalNavigator];
 * this maps them to screens and wraps everything in a SharedTransitionLayout for the poster → detail zoom.
 */
@Composable
fun AppNavHost(link: String?, onLinkHandled: () -> Unit) {
    val nav = rememberNavController()
    val entry by nav.currentBackStackEntryAsState()
    val navigator = remember(nav) {
        Navigator(
            openFilm = { nav.navigate(it) },
            openList = { nav.navigate(it) },
            back = { nav.popBackStack() },
        )
    }

    // tmovie://phim/{slug} and tmovie://the-loai/{slug}.
    LaunchedEffect(link) {
        val uri = link?.let(android.net.Uri::parse) ?: return@LaunchedEffect
        val slug = uri.pathSegments.firstOrNull() ?: return@LaunchedEffect onLinkHandled()
        when (uri.host) {
            "phim" -> runCatching { PhimApi.shared.detail(slug) }.getOrNull()?.let { nav.navigate(it.toItem().route("link/$slug")) }
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

/** Floating glass tab bar (the Android take on the iOS 26 Liquid Glass bar). */
@Composable
private fun BottomBar(selected: (TabItem) -> Boolean, onSelect: (TabItem) -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .navigationBarsPadding()
            .padding(horizontal = 20.dp, vertical = 10.dp)
            .clip(CircleShape)
            .background(Color(0xE6101418))
            .glass(CircleShape)
            .padding(6.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        tabs.forEach { tab ->
            val on = selected(tab)
            val scale by animateFloatAsState(if (on) 1f else 0.92f, label = "tab")
            Column(
                Modifier
                    .clip(CircleShape)
                    .background(if (on) Color.White.copy(alpha = 0.14f) else Color.Transparent)
                    .clickable { onSelect(tab) }
                    .width(78.dp)
                    .padding(vertical = 6.dp)
                    .graphicsLayer { scaleX = scale; scaleY = scale },
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(tab.icon, null, tint = if (on) TMovieColors.BrandLight else Color.White, modifier = Modifier.size(24.dp))
                Text(tab.label, color = if (on) TMovieColors.BrandLight else Color.White, fontSize = 11.sp, fontWeight = FontWeight.Medium,
                    modifier = Modifier.height(16.dp))
            }
        }
    }
}
