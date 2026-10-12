import AppRouter
import DesignSystem
import Networking
import SwiftUI

/// "Phim theo quốc gia": one tap into a country's page; the last tile opens the full country list.
public struct CountryShelf: View {
    static let countries: [(flag: String, name: String, slug: String)] = [
        ("🇰🇷", "Hàn Quốc", "han-quoc"), ("🇨🇳", "Trung Quốc", "trung-quoc"), ("🇺🇸", "Âu Mỹ", "au-my"),
        ("🇯🇵", "Nhật Bản", "nhat-ban"), ("🇹🇭", "Thái Lan", "thai-lan"), ("🇻🇳", "Việt Nam", "viet-nam"),
        ("🇹🇼", "Đài Loan", "dai-loan"), ("🇭🇰", "Hồng Kông", "hong-kong"), ("🇮🇳", "Ấn Độ", "an-do"),
    ]

    @State private var showAll = false
    @Environment(RouterPath.self) private var router

    public init() {}

    public var body: some View {
        Shelf("Phim theo quốc gia") {
            ForEach(Self.countries, id: \.slug) { c in
                NavigationLink(value: ListRoute(title: c.name, source: .country(c.slug))) { tile(c.flag, c.name) }
                    .buttonStyle(PressableStyle())
            }
            Button { showAll = true } label: { tile("🌏", "Tất cả") }
                .buttonStyle(PressableStyle())
        }
        .fullScreenCover(isPresented: $showAll) {
            GenrePicker(selected: nil, kind: .countries, showsAll: false) { item in
                guard let item, let slug = item.slug else { return }
                router.push(ListRoute(title: item.name ?? "", source: .country(slug)))
            }
            .presentationBackground(.ultraThinMaterial)
        }
    }

    private func tile(_ flag: String, _ name: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(flag).font(.system(size: 30))
            Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
        }
        .padding(12)
        .frame(width: 124, height: 84, alignment: .bottomLeading)
        .background(.white.opacity(0.08), in: .rect(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.1)))
    }
}
