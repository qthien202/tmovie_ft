import AppRouter
import DesignSystem
import SwiftUI

/// A titled horizontal rail that snaps to items and rises in as it scrolls into view.
public struct Shelf<Content: View>: View {
    let title: String
    let more: ListRoute?
    let spacing: CGFloat
    @ViewBuilder let content: Content

    public init(_ title: String, more: ListRoute? = nil, spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.title = title
        self.more = more
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RailHeader(title: title, more: more)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: spacing) { content.railItemMotion() }
                    .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
        .modifier(RiseIn())
    }
}

/// Section title with an optional "Tất cả" push.
public struct RailHeader: View {
    let title: String
    let more: ListRoute?

    public init(title: String, more: ListRoute? = nil) {
        self.title = title
        self.more = more
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.bold())
            Spacer()
            if let more {
                NavigationLink(value: more) {
                    HStack(spacing: 2) {
                        Text("Tất cả")
                        Image(systemName: "chevron.right").fontWeight(.semibold).imageScale(.small)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

/// Fades and lifts content in on first appearance. Skipped with Reduce Motion.
public struct RiseIn: ViewModifier {
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 28)
            .onAppear { withAnimation(.cinematic) { shown = true } }
    }
}
