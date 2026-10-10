import SwiftUI
import UIKit

/// AsyncImage with an in-memory decoded cache, so scrolling back never flashes a placeholder.
/// Bytes are cached by URLCache (phimimg.com sends `max-age=2592000, immutable`).
public struct RemoteImage: View {
    let url: URL?
    /// Longest edge in points to decode at; keeps posters from decoding at full size.
    let maxPoints: CGFloat

    @State private var image: UIImage?
    @Environment(\.displayScale) private var scale

    public init(url: URL?, maxPoints: CGFloat = 400) {
        self.url = url
        self.maxPoints = maxPoints
    }

    public var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill().transition(.opacity)
                }
            }
            .clipped()
            .task(id: url) {
                guard let url else { return }
                if let hit = ImageCache.shared.object(forKey: url as NSURL) { image = hit; return }
                guard let data = try? await URLSession.shared.data(from: url).0,
                      let raw = UIImage(data: data),
                      let decoded = await raw.byPreparingThumbnail(ofSize: fitted(raw.size, edge: maxPoints * scale))
                else { return }
                ImageCache.shared.setObject(decoded, forKey: url as NSURL)
                withAnimation(.easeOut(duration: 0.25)) { image = decoded }
            }
    }

    private func fitted(_ size: CGSize, edge: CGFloat) -> CGSize {
        let k = min(1, edge / max(size.width, size.height, 1))
        return CGSize(width: size.width * k, height: size.height * k)
    }
}

enum ImageCache {
    nonisolated(unsafe) static let shared: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.countLimit = 300
        return c
    }()
}
