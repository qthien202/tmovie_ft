import AppRouter
import BrowseFeature
import DesignSystem
import HomeFeature
import Models
import Networking
import OnboardingFeature
import Persistence
import PlayerFeature
import ProfileFeature
import SwiftUI

/// Splash → onboarding (first launch) → tabs.
struct RootView: View {
    @AppStorage("onboarded") private var onboarded = false
    @State private var splashDone = false

    var body: some View {
        ZStack {
            if !splashDone {
                SplashView { withAnimation(.easeOut(duration: 0.4)) { splashDone = true } }
            } else if !onboarded {
                OnboardingView { withAnimation(.cinematic) { onboarded = true } }
                    .transition(.opacity)
            } else {
                MainTabs().transition(.opacity.combined(with: .scale(scale: 1.04)))
            }
        }
        .modelContainer(Library.container)
    }
}

/// iOS 26 renders this as the floating Liquid Glass tab bar, with search as its own glass button.
struct MainTabs: View {
    /// Reopens on the last tab.
    @AppStorage("tab") private var tab = 0
    /// One navigation stack per tab: home, new & hot, profile, search, live TV.
    @State private var routers = [RouterPath(), RouterPath(), RouterPath(), RouterPath(), RouterPath()]

    var body: some View {
        Group {
            if #available(iOS 18, *) {
                TabView(selection: $tab) {
                    Tab(value: 0) { stack(0) { HomeView() } } label: { tabLabel("Trang chủ", "house.fill") }
                    Tab(value: 1) { stack(1) { NewHotView() } } label: { tabLabel("Mới & Hot", "flame.fill") }
                    Tab(value: 4) { stack(4) { LiveTVView() } } label: { tabLabel("Truyền hình", "play.tv.fill") }
                    Tab(value: 2) { stack(2) { ProfileView() } } label: { tabLabel("Của tôi", "person.fill") }
                    Tab(value: 3, role: .search) { stack(3) { SearchView() } }
                }
            } else {
                TabView(selection: $tab) {
                    stack(0) { HomeView() }.tabItem { Label("Trang chủ", systemImage: "house") }.tag(0)
                    stack(1) { NewHotView() }.tabItem { Label("Mới & Hot", systemImage: "flame") }.tag(1)
                    stack(4) { LiveTVView() }.tabItem { Label("Truyền hình", systemImage: "play.tv") }.tag(4)
                    stack(2) { ProfileView() }.tabItem { Label("Của tôi", systemImage: "person.crop.circle") }.tag(2)
                    stack(3) { SearchView() }.tabItem { Label("Tìm kiếm", systemImage: "magnifyingglass") }.tag(3)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: tab)
        .onAppear {
            // Reads `tab` when called, so it pushes onto whichever tab is showing then.
            Player.showDetail = { detail in
                routers[tab].push(FilmRoute(film: FilmItem(detail), sourceID: "player/\(detail.slug)"))
            }
        }
        .onOpenURL { url in Task { await open(url) } }
        #if DEBUG
        // `-openURL tmovie://phim/{slug}` launch argument, for screenshots without the system prompt.
        .task {
            if let link = UserDefaults.standard.string(forKey: "openURL"), let url = URL(string: link) { await open(url) }
        }
        #endif
    }

    /// Icons only: the glass bar reads cleaner without titles (VoiceOver still reads them).
    private func tabLabel(_ title: String, _ symbol: String) -> some View {
        Label(title, systemImage: symbol).labelStyle(.iconOnly)
    }

    private func stack(_ i: Int, @ViewBuilder root: () -> some View) -> some View {
        @Bindable var router = routers[i]
        return NavigationStack(path: $router.path) { root().withAppDestinations() }
            .environment(router)
    }

    /// `tmovie://phim/{slug}[?play=1]` opens (and optionally plays) a film, `tmovie://the-loai/{slug}` a genre page, both on Home.
    private func open(_ url: URL) async {
        guard url.scheme == "tmovie", let slug = url.pathComponents.dropFirst().first else { return }
        switch url.host() {
        case "phim":
            guard let detail = try? await PhimAPI.shared.detail(slug: slug) else { return }
            tab = 0
            routers[0].push(FilmRoute(film: FilmItem(detail), sourceID: "link/\(slug)"))
            // `?play=1` starts (or resumes) playback straight away.
            if URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "play" }) == true {
                Player.start(detail, fromDetail: true)
            }
        case "the-loai":
            let name = (try? await PhimAPI.shared.taxonomy(.genres))?.first { $0.slug == slug }?.name ?? slug
            tab = 0
            routers[0].push(ListRoute(title: name, source: .genre(slug)))
        default:
            break
        }
    }
}
