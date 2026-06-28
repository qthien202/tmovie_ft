import 'package:drift/drift.dart';

/// One row per film (catalog item). `json` keeps the full `FilmItem` payload;
/// the typed columns make films queryable locally and dedupe by [slug].
@DataClassName('FilmRow')
class FilmEntries extends Table {
  TextColumn get slug => text()();
  TextColumn get name => text().nullable()();
  TextColumn get type => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get posterUrl => text().nullable()();
  TextColumn get thumbUrl => text().nullable()();
  TextColumn get episodeCurrent => text().nullable()();
  TextColumn get json => text()();
  IntColumn get updatedAt => integer()(); // epoch ms

  @override
  Set<Column> get primaryKey => {slug};
}

/// A materialised list result: ordered [slugs] + list metadata (status/params).
@DataClassName('FilmListRow')
class FilmLists extends Table {
  TextColumn get listKey => text()();
  TextColumn get slugs => text()(); // JSON array of slugs, in order
  TextColumn get meta => text()(); // JSON: status/params/appDomainCdnImage/titlePage
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {listKey};
}

@DataClassName('FilmDetailRow')
class FilmDetails extends Table {
  TextColumn get slug => text()();
  TextColumn get json => text()();
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {slug};
}

@DataClassName('FilmPeopleRow')
class FilmPeoples extends Table {
  TextColumn get slug => text()();
  TextColumn get json => text()();
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {slug};
}

@DataClassName('FilmImagesRow')
class FilmImages extends Table {
  TextColumn get slug => text()();
  TextColumn get json => text()();
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {slug};
}

/// Device-local watch history (one row per film, newest first by [watchedAt]).
/// `json` holds the full `WatchHistoryEntry` payload.
@DataClassName('WatchHistoryRow')
class WatchHistories extends Table {
  TextColumn get slug => text()();
  TextColumn get json => text()();
  IntColumn get watchedAt => integer()(); // epoch ms

  @override
  Set<Column> get primaryKey => {slug};
}

/// Resume positions, keyed by `${filmSlug}_$episodeSlug`.
@DataClassName('PlaybackRow')
class PlaybackPositions extends Table {
  TextColumn get id => text()();
  IntColumn get positionSeconds => integer()();
  IntColumn get updatedAt => integer()(); // epoch ms

  @override
  Set<Column> get primaryKey => {id};
}

/// Device-local favourites (one row per film, newest first by [addedAt]).
@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get slug => text()();
  TextColumn get json => text()();
  IntColumn get addedAt => integer()(); // epoch ms

  @override
  Set<Column> get primaryKey => {slug};
}

/// Generic local cache (e.g. the daily hero list). [dateKey] (YYYY-MM-DD) lets
/// callers gate a refresh to once per day; [value] holds arbitrary JSON.
@DataClassName('AppCacheRow')
class AppCacheEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get value => text()();
  TextColumn get dateKey => text().nullable()();
  IntColumn get updatedAt => integer()(); // epoch ms

  @override
  Set<Column> get primaryKey => {cacheKey};
}
