import DesignSystem
import FilmUI
import Models
import Persistence
import SwiftData
import SwiftUI

/// "Của tôi": My List, history and data settings (Netflix's My Netflix tab).
public struct ProfileView: View {
    public init() {}

    @Query(sort: \WatchRecord.updatedAt, order: .reverse) private var history: [WatchRecord]
    @Query(sort: \SavedFilm.addedAt, order: .reverse) private var saved: [SavedFilm]
    @AppStorage("profileName") private var name = "Bạn"
    @AppStorage("heroAutoplay") private var heroAutoplay = true
    @State private var confirm: Confirm?

    enum Confirm: Identifiable { case history, saved; var id: Self { self } }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                avatar
                if !history.isEmpty {
                    Shelf("Xem gần đây") {
                        ForEach(history.prefix(20)) { ContinueCard(record: $0) }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    RailHeader(title: "Danh sách của tôi")
                    if saved.isEmpty {
                        Text("Nhấn + Danh sách ở một bộ phim để lưu lại.")
                            .font(.subheadline).foregroundStyle(.secondary).padding(.horizontal, 16)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                            ForEach(saved.compactMap(\.film)) { PosterCard(film: $0, sourceID: "profile-list/\($0.slug)", width: nil) }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                settings
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .background(Color.canvas)
        .navigationTitle("Của tôi")
        .confirmationDialog("Xác nhận", isPresented: Binding(get: { confirm != nil }, set: { if !$0 { confirm = nil } }), presenting: confirm) { c in
            switch c {
            case .history: Button("Xoá lịch sử xem", role: .destructive) { Library.clearHistory() }
            case .saved: Button("Xoá danh sách của tôi", role: .destructive) { Library.clearSaved() }
            }
        }
    }

    private var avatar: some View {
        HStack(spacing: 14) {
            Text(String(name.prefix(1)).uppercased())
                .font(.title.bold())
                .frame(width: 64, height: 64)
                .background(LinearGradient(colors: [Color.brand, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                TextField("Tên hồ sơ", text: $name).font(.title2.bold())
                Text("\(saved.count) phim đã lưu · \(history.count) phim đã xem").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
    }

    private var settings: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $heroAutoplay) { Label("Tự phát xem trước", systemImage: "play.rectangle.on.rectangle") }
                .padding(16)
            Divider().padding(.leading, 52)
            row("Xoá lịch sử xem", "clock.arrow.circlepath") { confirm = .history }
            Divider().padding(.leading, 52)
            row("Xoá danh sách của tôi", "trash") { confirm = .saved }
            Divider().padding(.leading, 52)
            HStack {
                Label("Phiên bản", systemImage: "info.circle")
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0").foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .glassSurface(in: .rect(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func row(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
