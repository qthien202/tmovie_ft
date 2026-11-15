import AppRouter
import DesignSystem
import FilmUI
import Models
import Networking
import SwiftUI

/// Apple TV-style hero: full-bleed key art pages with parallax paging, a slow Ken Burns drift and
/// depth from device tilt; the caption sits bottom-left over a progressive blur: rank, title, facts
/// with badges, two lines of story, Play + Add. A vertical page indicator runs down the right edge.
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
                ForEach(Array(films.enumerated()), id: \.element.id) { i, film in
                    HeroPage(film: film, rank: i + 1, art: art[film.slug] ?? film.thumbURL, tint: tint, tilt: tilt, motion: !reduceMotion,
                             preview: autoplay && film.slug == current, muted: $muted)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
        .scrollIndicators(.hidden)
        .containerRelativeFrame(.vertical) { h, _ in h * 0.78 }
        .overlay(alignment: .bottomTrailing) { dots }
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

    /// Vertical, down the right edge, so it never competes with the caption.
    private var dots: some View {
        VStack(spacing: 5) {
            ForEach(films) { film in
                Capsule()
                    .fill(.white.opacity(film.slug == current ? 1 : 0.4))
                    .frame(width: 5, height: film.slug == current ? 24 : 6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 5)
        .glassSurface(in: .capsule)
        .animation(.snappy, value: current)
        .padding(.trailing, 12)
        .padding(.bottom, 40)
        .opacity(films.count > 1 ? 1 : 0)
        .accessibilityHidden(true)
    }
}

private struct HeroPage: View {
    let film: FilmItem
    let rank: Int
    let art: URL?
    let tint: Color
    let tilt: TiltMotion
    let motion: Bool
    let preview: Bool
    @Binding var muted: Bool
    @State private var story = ""

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
                        .overlay(alignment: .bottom) { veil(height: geo.size.height * 0.56) }
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
            LinearGradient(stops: [
                .init(color: .black.opacity(0.7), location: 0),
                .init(color: .black.opacity(0.25), location: 0.16),
                .init(color: .clear, location: 0.3),
            ], startPoint: .top, endPoint: .bottom)
            LinearGradient(stops: [
                .init(color: .clear, location: 0.5),
                .init(color: tint.opacity(0.2), location: 0.72),
                .init(color: .canvas, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
    }

    /// Apple TV's progressive blur: the art softens and darkens under the caption, so it reads on any still.
    private func veil(height: CGFloat) -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.45), .canvas], startPoint: .top, endPoint: .bottom))
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.42)], startPoint: .top, endPoint: .bottom))
            .frame(height: height)
            .allowsHitTesting(false)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("TOP \(rank)")
                    .font(.system(size: 10.5, weight: .black))
                    .tracking(0.6)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.white, in: .rect(cornerRadius: 6, style: .continuous))
                Text("Đang hot tuần này").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
            }
            // Long names step down in size rather than being cut.
            Text(film.name)
                .font(.system(size: film.name.count > 26 ? 28 : film.name.count > 16 ? 34 : 40, weight: .heavy))
                .tracking(-0.8)
                .lineLimit(film.name.count > 26 ? 3 : 2)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.35), radius: 14, y: 4)
                .padding(.top, 10)
            HStack(spacing: 6) {
                Text(facts).lineLimit(1).truncationMode(.tail)
                if let q = film.quality, !q.isEmpty { badge(q) }
                if let lang = film.lang, !lang.isEmpty { badge(lang.localizedCaseInsensitiveContains("thuyết") || lang.localizedCaseInsensitiveContains("lồng") ? "TM" : "VS") }
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.85))
            .padding(.top, 10)
            Text(story)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
                .frame(minHeight: 38, alignment: .top)
                .padding(.top, 8)
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
            .padding(.top, 16)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
        .padding(.trailing, 48)
        .padding(.bottom, 30)
        .task(id: film.slug) {
            guard story.isEmpty, let detail = try? await PhimAPI.shared.detail(slug: film.slug) else { return }
            story = (detail.content ?? "")
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 5)
            .frame(height: 18)
            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(.white.opacity(0.55), lineWidth: 1))
            .fixedSize()
    }

    /// "Phim bộ · Tình cảm · Hành động · 2026"
    private var facts: String {
        let kind: String? = switch film.type {
        case "series": "Phim bộ"
        case "single": "Phim lẻ"
        case "tvshows": "TV Show"
        case "hoathinh": "Hoạt hình"
        default: nil
        }
        return ([kind] + (film.category ?? []).prefix(2).map(\.name) + [film.year.map(String.init)]).compactMap { $0 }.joined(separator: " · ")
    }
}
