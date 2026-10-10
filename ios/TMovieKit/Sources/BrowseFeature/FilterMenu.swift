import AppRouter
import Models
import Networking
import SwiftUI

/// Toolbar menu that filters a `Pager` by sort, year, genre and country.
struct FilterMenu: View {
    @Bindable var pager: Pager
    let source: PhimAPI.Source

    @State private var countries: [FilmCategory] = []
    @State private var genres: [FilmCategory] = []

    var body: some View {
        Menu {
            Picker("Sắp xếp", selection: $pager.filter.sortField) {
                Text("Mới cập nhật").tag(String?.none)
                Text("Năm phát hành").tag(String?("year"))
                Text("Mới thêm").tag(String?("_id"))
            }
            Menu("Năm") {
                Picker("Năm", selection: $pager.filter.year) {
                    Text("Tất cả").tag(Int?.none)
                    ForEach((2000...Calendar.current.component(.year, from: .now)).reversed(), id: \.self) { Text(String($0)).tag(Int?($0)) }
                }
            }
            if case .genre = source {} else {
                Menu("Thể loại") {
                    Picker("Thể loại", selection: $pager.filter.category) {
                        Text("Tất cả").tag(String?.none)
                        ForEach(genres, id: \.slug) { Text($0.name ?? "").tag($0.slug) }
                    }
                }
            }
            if case .country = source {} else {
                Menu("Quốc gia") {
                    Picker("Quốc gia", selection: $pager.filter.country) {
                        Text("Tất cả").tag(String?.none)
                        ForEach(countries, id: \.slug) { Text($0.name ?? "").tag($0.slug) }
                    }
                }
            }
            if pager.filter != PhimAPI.Filter() {
                Button("Bỏ lọc", systemImage: "xmark", role: .destructive) { pager.filter = .init() }
            }
        } label: {
            Image(systemName: pager.filter == PhimAPI.Filter() ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
        }
        .accessibilityLabel("Bộ lọc")
        .task {
            async let c = try? PhimAPI.shared.taxonomy(.countries)
            async let g = try? PhimAPI.shared.taxonomy(.genres)
            (countries, genres) = (await c ?? [], await g ?? [])
        }
    }
}
