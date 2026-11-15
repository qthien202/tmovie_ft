import Foundation

/// The frame on screen when the viewer paused or left a film, for its "Xem tiếp" card.
/// Written by the player (`PlayerModel.snapshot()`), read by `ContinueCard`; one JPEG per film in Caches.
public enum ContinueFrame {
    public static let directory: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "continue-frames")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    public static func url(for slug: String) -> URL {
        directory.appending(path: slug.replacingOccurrences(of: "/", with: "_") + ".jpg")
    }
}
