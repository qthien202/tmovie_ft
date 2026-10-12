import AppRouter
import DesignSystem
import Models
import Networking
import SwiftUI

/// "Thể loại ⌄" / "Quốc gia ⌄" pill that opens a Netflix-style full-screen list over frosted glass.
/// Picking opens that genre/country page, or, with `filter`, hands the pick back (nil = "Tất cả").
public struct GenrePickerButton: View {
    let selected: String?
    let kind: PhimAPI.Taxonomy
    let title: String?
    let filter: ((FilmCategory?) -> Void)?
    @State private var open = false
    @Environment(RouterPath.self) private var router

    public init(selected: String? = nil, kind: PhimAPI.Taxonomy = .genres, title: String? = nil, filter: ((FilmCategory?) -> Void)? = nil) {
        self.selected = selected
        self.kind = kind
        self.title = title
        self.filter = filter
    }

    public var body: some View {
        Button { open = true } label: {
            HStack(spacing: 4) { Text(title ?? (kind == .genres ? "Thể loại" : "Quốc gia")); Image(systemName: "chevron.down").imageScale(.small) }
                .modifier(PillLabel(selected: title != nil))
        }
        .buttonStyle(PressableStyle())
        .fullScreenCover(isPresented: $open) {
            GenrePicker(selected: selected, kind: kind, showsAll: filter != nil) { item in
                if let filter { return filter(item) }
                guard let item else { return }
                let slug = item.slug ?? ""
                router.push(ListRoute(title: item.name ?? "", source: kind == .genres ? .genre(slug) : .country(slug)))
            }
            .presentationBackground(.ultraThinMaterial)
        }
    }
}

struct GenrePicker: View {
    let selected: String?
    let kind: PhimAPI.Taxonomy
    let showsAll: Bool
    let pick: (FilmCategory?) -> Void

    @State private var genres: [FilmCategory] = []
    @State private var shown = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    if showsAll {
                        Button {
                            dismiss()
                            if selected != nil { pick(nil) }
                        } label: {
                            Text("Tất cả")
                                .font(selected == nil ? .title2.bold() : .title3.weight(.medium))
                                .foregroundStyle(selected == nil ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(Array(genres.enumerated()), id: \.element.slug) { i, genre in
                        let isSelected = genre.slug == selected
                        Button {
                            dismiss()
                            if !isSelected { pick(genre) }
                        } label: {
                            Text(genre.name ?? "")
                                .font(isSelected ? .title2.bold() : .title3.weight(.medium))
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .opacity(shown || reduceMotion ? 1 : 0)
                        .offset(y: shown || reduceMotion ? 0 : 16)
                        .animation(.cinematic.delay(Double(min(i, 14)) * 0.025), value: shown)
                    }
                }
                .padding(.top, 80)
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.08), .init(color: .black, location: 0.8), .init(color: .clear, location: 0.95)], startPoint: .top, endPoint: .bottom))

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 60, height: 60)
                    .background(.white, in: .circle)
                    .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Đóng")
            .padding(.bottom, 36)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: shown)
        .task {
            genres = (try? await PhimAPI.shared.taxonomy(kind)) ?? []
            shown = true
        }
    }
}
