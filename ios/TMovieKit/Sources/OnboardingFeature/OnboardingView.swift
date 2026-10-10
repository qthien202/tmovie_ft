import DesignSystem
import Models
import Networking
import SwiftUI

/// First-launch intro over a slowly drifting wall of real posters.
public struct OnboardingView: View {
    let done: () -> Void

    public init(done: @escaping () -> Void) { self.done = done }

    @State private var page = 0
    @State private var posters: [FilmItem] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = [
        ("Cả thế giới điện ảnh\ntrong túi bạn", "Phim bộ, phim lẻ, TV Shows cập nhật mỗi ngày.", "sparkles.tv"),
        ("Sắc nét đến\ntừng khung hình", "Phát Full HD, Hình trong hình và AirPlay lên TV.", "pip"),
        ("Tiếp tục xem\nđúng chỗ bạn dừng", "Lịch sử và danh sách của bạn luôn sẵn sàng.", "play.circle"),
    ]

    public var body: some View {
        ZStack(alignment: .bottom) {
            PosterWall(films: posters, animate: !reduceMotion)
                .overlay(LinearGradient(colors: [.canvas.opacity(0.2), .canvas.opacity(0.85), .canvas], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()

            VStack(spacing: 24) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 14) {
                            Image(systemName: pages[i].2)
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(Color.brand)
                                .symbolEffect(.bounce, value: page == i)
                            Text(pages[i].0).font(.system(.largeTitle, design: .serif).bold()).multilineTextAlignment(.center)
                            Text(pages[i].1).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 330)

                Button {
                    if page < pages.count - 1 { withAnimation(.cinematic) { page += 1 } } else { done() }
                } label: {
                    Text(page < pages.count - 1 ? "Tiếp tục" : "Bắt đầu xem")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundStyle(.white)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PressableStyle())
                .sensoryFeedback(.impact(weight: .light), trigger: page)
                .padding(.horizontal, 24)
                Button("Bỏ qua", action: done).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
        }
        .background(Color.canvas)
        .task { posters = (try? await PhimAPI.shared.list(.type("phim-moi-cap-nhat")).items) ?? [] }
    }
}
