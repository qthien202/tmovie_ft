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
