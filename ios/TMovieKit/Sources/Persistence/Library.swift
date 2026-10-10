import Foundation
import Models
import SwiftData

/// Reads and writes the on-device library. Views observe it with `@Query`; the player writes through here.
@MainActor
public enum Library {
    public static let container: ModelContainer = {
        do { return try ModelContainer(for: SavedFilm.self, WatchRecord.self) }
        catch { fatalError("SwiftData store failed to open: \(error)") }
    }()

    public static var context: ModelContext { container.mainContext }

    public static func saved(_ slug: String) -> SavedFilm? {
        try? context.fetch(FetchDescriptor<SavedFilm>(predicate: #Predicate { $0.slug == slug })).first
    }

    public static func record(_ slug: String) -> WatchRecord? {
        try? context.fetch(FetchDescriptor<WatchRecord>(predicate: #Predicate { $0.slug == slug })).first
    }

    /// Adds or removes from My List; returns the new state.
    @discardableResult
    public static func toggleSaved(_ film: FilmItem) -> Bool {
        if let existing = saved(film.slug) {
            context.delete(existing)
            return false
        }
        context.insert(SavedFilm(film: film))
        return true
    }

    /// Called by the player on start, every 10s, on episode switch and on close.
    public static func save(film: FilmItem, server: Int, episode: Int, episodeName: String, episodeSlug: String, position: Double, duration: Double) {
        let r = record(film.slug) ?? {
            let new = WatchRecord(film: film)
            context.insert(new)
            return new
        }()
        r.serverIndex = server
        r.episodeIndex = episode
        r.episodeName = episodeName
        r.lastEpisodeSlug = episodeSlug
        if position.isFinite, position > 0 { r.positions[episodeSlug] = position }
        if duration.isFinite, duration > 0 { r.durations[episodeSlug] = duration }
        r.updatedAt = .now
    }

    public static func remove(_ record: WatchRecord) { context.delete(record) }
    public static func clearHistory() { try? context.delete(model: WatchRecord.self) }
    public static func clearSaved() { try? context.delete(model: SavedFilm.self) }
}
