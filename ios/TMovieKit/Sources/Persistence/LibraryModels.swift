import Foundation
import Models
import SwiftData

// On-device library (replaces the Flutter Drift tables): My List, watch history and resume points.

@Model
public final class SavedFilm {
    @Attribute(.unique) public var slug: String
    var filmData: Data
    public var addedAt: Date

    init(film: FilmItem) {
        slug = film.slug
        filmData = (try? JSONEncoder().encode(film)) ?? Data()
        addedAt = .now
    }

    public var film: FilmItem? { try? JSONDecoder().decode(FilmItem.self, from: filmData) }
}

@Model
public final class WatchRecord {
    @Attribute(.unique) public var slug: String
    var filmData: Data
    public var serverIndex: Int
    public var episodeIndex: Int
    public var episodeName: String
    public var lastEpisodeSlug: String
    /// Seconds watched / total, per episode slug, for resume and progress bars.
    public var positions: [String: Double]
    public var durations: [String: Double]
    public var updatedAt: Date

    init(film: FilmItem) {
        slug = film.slug
        filmData = (try? JSONEncoder().encode(film)) ?? Data()
        serverIndex = 0
        episodeIndex = 0
        episodeName = ""
        lastEpisodeSlug = ""
        positions = [:]
        durations = [:]
        updatedAt = .now
    }

    public var film: FilmItem? { try? JSONDecoder().decode(FilmItem.self, from: filmData) }

    public func progress(_ episodeSlug: String) -> Double {
        guard let d = durations[episodeSlug], d > 0 else { return 0 }
        return min(1, (positions[episodeSlug] ?? 0) / d)
    }

    /// Progress of the episode last played, for "Xem tiếp" cards.
    public var lastProgress: Double { progress(lastEpisodeSlug) }
}
