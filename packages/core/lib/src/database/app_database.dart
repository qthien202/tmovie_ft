import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Local SQLite database (Drift) — source of truth for the film catalog.
/// The app reads from here; the network is only used to sync new data in.
@DriftDatabase(
  tables: [
    FilmEntries,
    FilmLists,
    FilmDetails,
    FilmPeoples,
    FilmImages,
    WatchHistories,
    PlaybackPositions,
    Favorites,
    AppCacheEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2: device-local watch history + resume positions.
      if (from < 2) {
        await m.createTable(watchHistories);
        await m.createTable(playbackPositions);
      }
      // v3: device-local favourites.
      if (from < 3) {
        await m.createTable(favorites);
      }
      // v4: generic app cache (daily hero list, etc.).
      if (from < 4) {
        await m.createTable(appCacheEntries);
      }
    },
  );

  // ── Generic app cache ──
  Future<AppCacheRow?> getAppCache(String key) =>
      (select(appCacheEntries)..where((t) => t.cacheKey.equals(key)))
          .getSingleOrNull();

  Future<void> putAppCache(AppCacheEntriesCompanion row) =>
      into(appCacheEntries).insertOnConflictUpdate(row);

  // ── Watch history (local) ──
  /// Newest first.
  Future<List<WatchHistoryRow>> getWatchHistory() =>
      (select(watchHistories)
            ..orderBy([(t) => OrderingTerm.desc(t.watchedAt)]))
          .get();

  Future<void> upsertWatchHistory(WatchHistoriesCompanion row) =>
      into(watchHistories).insertOnConflictUpdate(row);

  /// Keep only the [keep] most-recent entries.
  Future<void> trimWatchHistory(int keep) async {
    final rows = await (select(
      watchHistories,
    )..orderBy([(t) => OrderingTerm.desc(t.watchedAt)])).get();
    if (rows.length <= keep) return;
    final stale = rows.skip(keep).map((r) => r.slug).toList();
    await (delete(watchHistories)..where((t) => t.slug.isIn(stale))).go();
  }

  Future<void> clearWatchHistory() => delete(watchHistories).go();

  // ── Resume positions ──
  Future<PlaybackRow?> getPlayback(String id) =>
      (select(playbackPositions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertPlayback(PlaybackPositionsCompanion row) =>
      into(playbackPositions).insertOnConflictUpdate(row);

  // ── Favourites (local) ──
  /// Newest first.
  Future<List<FavoriteRow>> getFavorites() =>
      (select(favorites)..orderBy([(t) => OrderingTerm.desc(t.addedAt)])).get();

  Future<void> upsertFavorite(FavoritesCompanion row) =>
      into(favorites).insertOnConflictUpdate(row);

  Future<void> deleteFavorite(String slug) =>
      (delete(favorites)..where((t) => t.slug.equals(slug))).go();

  Future<bool> favoriteExists(String slug) async {
    final row = await (select(
      favorites,
    )..where((t) => t.slug.equals(slug))).getSingleOrNull();
    return row != null;
  }

  Future<void> clearFavorites() => delete(favorites).go();

  // ── Films ──
  Future<void> upsertFilms(List<FilmEntriesCompanion> rows) async {
    await batch((b) {
      for (final r in rows) {
        b.insert(filmEntries, r, onConflict: DoUpdate((_) => r));
      }
    });
  }

  /// Films for [slugs], preserving the given order, skipping any missing.
  Future<List<FilmRow>> filmsBySlugs(List<String> slugs) async {
    if (slugs.isEmpty) return [];
    final rows =
        await (select(filmEntries)..where((t) => t.slug.isIn(slugs))).get();
    final bySlug = {for (final r in rows) r.slug: r};
    return [
      for (final s in slugs)
        if (bySlug[s] != null) bySlug[s]!,
    ];
  }

  // ── Lists ──
  Future<FilmListRow?> getList(String key) =>
      (select(filmLists)..where((t) => t.listKey.equals(key)))
          .getSingleOrNull();

  Future<void> upsertList(FilmListsCompanion row) =>
      into(filmLists).insertOnConflictUpdate(row);

  // ── Detail / peoples / images ──
  Future<FilmDetailRow?> getDetail(String slug) =>
      (select(filmDetails)..where((t) => t.slug.equals(slug)))
          .getSingleOrNull();
  Future<void> upsertDetail(FilmDetailsCompanion row) =>
      into(filmDetails).insertOnConflictUpdate(row);

  Future<FilmPeopleRow?> getPeople(String slug) =>
      (select(filmPeoples)..where((t) => t.slug.equals(slug)))
          .getSingleOrNull();
  Future<void> upsertPeople(FilmPeoplesCompanion row) =>
      into(filmPeoples).insertOnConflictUpdate(row);

  Future<FilmImagesRow?> getImages(String slug) =>
      (select(filmImages)..where((t) => t.slug.equals(slug)))
          .getSingleOrNull();
  Future<void> upsertImages(FilmImagesCompanion row) =>
      into(filmImages).insertOnConflictUpdate(row);
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'tmovie.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
