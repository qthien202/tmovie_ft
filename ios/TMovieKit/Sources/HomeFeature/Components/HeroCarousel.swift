import AppRouter
import DesignSystem
import FilmUI
import Models
import SwiftUI

/// Apple TV-style hero: full-bleed key art pages with parallax paging, a slow Ken Burns drift,
/// depth from device tilt, and a centred title / genre / Play + Add cluster over a fade.
struct HeroCarousel: View {
    let films: [FilmItem]
    let art: [String: URL]
    let tint: Color
    @Binding var page: String?

    @State private var tilt = TiltMotion()
    @AppStorage("heroAutoplay") private var autoplaySetting = true
    @AppStorage("heroMuted") private var muted = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var current: String? { page ?? films.first?.slug }

    /// Autoplay previews unless turned off, in Low Power Mode, or with Reduce Motion.
    private var autoplay: Bool {
        autoplaySetting && !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(films) { film in
                    HeroPage(film: film, art: art[film.slug] ?? film.thumbURL, tint: tint, tilt: tilt, motion: !reduceMotion,
                             preview: autoplay && film.slug == current, muted: $muted)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
        .scrollIndicators(.hidden)
        .containerRelativeFrame(.vertical) { h, _ in h * 0.74 }
        .overlay(alignment: .bottom) { dots }
        .redacted(reason: films.isEmpty ? .placeholder : [])
        // Stretch on pull-down; on scroll-up the art lags behind and softens.
        .visualEffect { [reduceMotion] content, geo in
            let y = geo.frame(in: .scrollView(axis: .vertical)).minY
            return content
                .scaleEffect(reduceMotion || y <= 0 ? 1 : 1 + y / geo.size.height, anchor: .bottom)
                .offset(y: reduceMotion || y > 0 ? 0 : -y * 0.35)
                .blur(radius: reduceMotion ? 0 : max(0, -y) / 50)
        }
        .sensoryFeedback(.selection, trigger: page)
        .onAppear { if !reduceMotion { tilt.start() } }
        .onDisappear { tilt.stop() }
        .task(id: "\(current ?? "")\(films.count)\(scenePhase == .active)") {
            // Auto-advance (longer while a preview plays); a manual swipe changes `page` and restarts the timer.
            guard films.count > 1, scenePhase == .active else { return }
            try? await Task.sleep(for: .seconds(autoplay ? 30 : 8))
            guard !Task.isCancelled else { return }
            let i = films.firstIndex { $0.slug == current } ?? 0
            withAnimation(reduceMotion ? nil : .cinematic) { page = films[(i + 1) % films.count].slug }
        }
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(films) { film in
                Capsule()
                    .fill(.white.opacity(film.slug == current ? 1 : 0.4))
                    .frame(width: film.slug == current ? 20 : 7, height: 7)
            }
        }
        .animation(.snappy, value: current)
        .padding(.bottom, 14)
        .opacity(films.count > 1 ? 1 : 0)
        .accessibilityHidden(true)
    }
}

private struct HeroPage: View {
    let film: FilmItem
    let art: URL?
    let tint: Color
    let tilt: TiltMotion
    let motion: Bool
    let preview: Bool
    @Binding var muted: Bool

    var body: some View {
        let route = FilmRoute(film: film, sourceID: "hero/\(film.slug)")
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                NavigationLink(value: route) {
                    RemoteImage(url: art, maxPoints: 1300)
                        // Ken Burns: a slow push-in that breathes back out.
                        .keyframeAnimator(initialValue: 1.0, repeating: motion) { content, scale in
                            content.scaleEffect(scale)
                        } keyframes: { _ in
                            CubicKeyframe(1.12, duration: 12)
                            CubicKeyframe(1.0, duration: 12)
                        }
                        .overlay { if preview { HeroPreview(slug: film.slug, muted: $muted) } }
                        .offset(x: tilt.roll * -22, y: tilt.pitch * -14)
                        .scaleEffect(1.08)  // bleed so tilt never shows an edge
                        // Paging parallax: the art moves slower than the page.
                        .scrollTransition(.interactive, axis: .horizontal) { [width = geo.size.width] content, phase in
                            content.offset(x: motion ? phase.value * -width * 0.4 : 0)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .overlay { scrim }
                        .contentShape(.rect)
                        .zoomSource(id: route.sourceID)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(film.name)

                caption
                    .offset(x: tilt.roll * 8, y: tilt.pitch * 5)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content
                            .opacity(1 - abs(phase.value) * 1.4)
                            .offset(x: phase.value * 60)
                            .blur(radius: motion ? abs(phase.value) * 8 : 0)
                    }
            }
        }
    }

    private var scrim: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.25))
            LinearGradient(stops: [
                .init(color: .clear, location: 0.35),
                .init(color: tint.opacity(0.25), location: 0.65),
                .init(color: .canvas, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
    }

    private var caption: some View {
        VStack(spacing: 10) {
            Text(captionLine)
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.75))
            Text(film.name)
                .font(.system(size: 38, weight: .heavy, design: .serif))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
            if let origin = film.originName, !origin.isEmpty, origin != film.name {
                Text(origin).font(.subheadline).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
            }
            HStack(spacing: 12) {
                PlayFilmButton(film: film, capsule: true)
                SaveButton(film: film, style: .circle)
                if preview {
                    Button { muted.toggle() } label: {
                        Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.title3.weight(.semibold))
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 50, height: 50)
                            .glassSurface(in: .circle, interactive: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(muted ? "Bật tiếng xem trước" : "Tắt tiếng xem trước")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.snappy, value: preview)
            .padding(.top, 6)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.bottom, 44)
    }

    /// "Phim bộ · Tình cảm · 2026 · ★ 8.4"
    private var captionLine: String {
        let kind: String? = switch film.type {
        case "series": "Phim bộ"
        case "single": "Phim lẻ"
        case "tvshows": "TV Show"
        case "hoathinh": "Hoạt hình"
        default: nil
        }
        let rating = film.rating.map { "★ " + $0.formatted(.number.precision(.fractionLength(1))) }
        return [kind, film.category?.first?.name, film.year.map(String.init), rating].compactMap { $0 }.joined(separator: " · ")
    }
}
