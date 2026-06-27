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
  tables: [FilmEntries, FilmLists, FilmDetails, FilmPeoples, FilmImages],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

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
