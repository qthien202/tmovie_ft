import SwiftUI

/// Scale-down on press for cards and custom buttons.
public struct PressableStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// White "Xem ngay" capsule, Apple TV style.
public struct PlayCapsuleLabel: View {
    let title: String

    public init(_ title: String = "Xem ngay") { self.title = title }

    public var body: some View {
        Label(title, systemImage: "play.fill")
            .font(.headline)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 28)
            .frame(minHeight: 50)
            .foregroundStyle(.black)
            .background(.white, in: .capsule)
    }
}

/// Full-width white "Phát" label.
public struct PlayWideLabel: View {
    let title: String

    public init(_ title: String = "Phát") { self.title = title }

    public var body: some View {
        Label(title, systemImage: "play.fill")
            .font(.headline)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(.black)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// Icon over caption, for detail action rows ("Danh sách", "Chia sẻ").
public struct ActionLabel: View {
    let title: String
    let systemImage: String

    public init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.title3.weight(.semibold))
            Text(title).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
        }
        .frame(minWidth: 64, minHeight: 48)
    }
}

/// Outlined glass capsule used for category pills.
public struct PillLabel: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .glassSurface(interactive: true)
    }
}

/// Thin progress bar along the bottom of a thumbnail.
public struct ProgressStrip: View {
    let value: Double

    public init(_ value: Double) { self.value = value }

    public var body: some View {
        GeometryReader { geo in
            Rectangle().fill(.white.opacity(0.25))
                .overlay(alignment: .leading) { Rectangle().fill(Color.brand).frame(width: geo.size.width * min(1, max(0, value))) }
        }
        .frame(height: 3)
        .accessibilityValue(Text("\(Int(value * 100))%"))
    }
}

public struct Wordmark: View {
    let size: CGFloat

    public init(size: CGFloat = 26) { self.size = size }

    public var body: some View {
        Text("TMOVIE")
            .font(.system(size: size, weight: .black, design: .rounded))
            .tracking(size * 0.06)
            .foregroundStyle(.brandGradient)
            .accessibilityLabel("TMovie")
            .accessibilityAddTraits(.isHeader)
    }
}
