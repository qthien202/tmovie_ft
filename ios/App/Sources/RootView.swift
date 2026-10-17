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

/// The tabs under a docked bar in the style of the big streaming apps (and the Android app):
/// solid, edge to edge, a hairline on top, light symbols; the selected tab turns white and bolder.
/// It replaces the system's floating glass bar.
struct MainTabs: View {
    /// Reopens on the last tab.
    @AppStorage("tab") private var tab = 0
    /// One navigation stack per tab: home, new & hot, profile, search, live TV.
    @State private var routers = [RouterPath(), RouterPath(), RouterPath(), RouterPath(), RouterPath()]
    /// Tabs are built on first visit (live TV loads 11k channels), then kept alive.
    @State private var visited: Set<Int> = []

    /// Bar order: value (the stored `tab`), title, SF Symbol.
    static let items = [(0, "Trang chủ", "house"), (1, "Mới & Hot", "flame"), (4, "Truyền hình", "play.tv"),
                        (3, "Tìm kiếm", "magnifyingglass"), (2, "Của tôi", "person")]

    var body: some View {
        ZStack {
            ForEach(Self.items, id: \.0) { item in
                let i = item.0
                if visited.contains(i) || tab == i {
                    page(i)
                        .opacity(tab == i ? 1 : 0)
                        .allowsHitTesting(tab == i)
                        .accessibilityHidden(tab != i)
                        .onAppear { visited.insert(i) }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { TabBar(tab: $tab) { routers[$0].path = NavigationPath() } }
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

    @ViewBuilder private func page(_ i: Int) -> some View {
        switch i {
        case 0: stack(0) { HomeView() }
        case 1: stack(1) { NewHotView() }
        case 2: stack(2) { ProfileView() }
        case 3: stack(3) { SearchView() }
        default: stack(4) { LiveTVView() }
        }
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

private struct TabBar: View {
    @Binding var tab: Int
    /// Tapping the open tab again goes back to its first screen.
    var popToRoot: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabs.items, id: \.0) { value, title, symbol in
                let on = tab == value
                Button { if on { popToRoot(value) } else { tab = value } } label: {
                    VStack(spacing: 4) {
                        Image(systemName: symbol)
                            .font(.system(size: 20, weight: on ? .semibold : .light))
                            .frame(height: 24)
                        Text(title).font(.system(size: 10, weight: on ? .semibold : .regular))
                    }
                    .foregroundStyle(on ? Color.white : Color.white.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.top, 6)
        .background {
            Color.canvas
                .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5) }
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(.snappy(duration: 0.2), value: tab)
    }
}
