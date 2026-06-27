// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FilmEntriesTable extends FilmEntries
    with TableInfo<$FilmEntriesTable, FilmRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta(
    'posterUrl',
  );
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbUrlMeta = const VerificationMeta(
    'thumbUrl',
  );
  @override
  late final GeneratedColumn<String> thumbUrl = GeneratedColumn<String>(
    'thumb_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeCurrentMeta = const VerificationMeta(
    'episodeCurrent',
  );
  @override
  late final GeneratedColumn<String> episodeCurrent = GeneratedColumn<String>(
    'episode_current',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    slug,
    name,
    type,
    year,
    posterUrl,
    thumbUrl,
    episodeCurrent,
    json,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('poster_url')) {
      context.handle(
        _posterUrlMeta,
        posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta),
      );
    }
    if (data.containsKey('thumb_url')) {
      context.handle(
        _thumbUrlMeta,
        thumbUrl.isAcceptableOrUnknown(data['thumb_url']!, _thumbUrlMeta),
      );
    }
    if (data.containsKey('episode_current')) {
      context.handle(
        _episodeCurrentMeta,
        episodeCurrent.isAcceptableOrUnknown(
          data['episode_current']!,
          _episodeCurrentMeta,
        ),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  FilmRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmRow(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      posterUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_url'],
      ),
      thumbUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_url'],
      ),
      episodeCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_current'],
      ),
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FilmEntriesTable createAlias(String alias) {
    return $FilmEntriesTable(attachedDatabase, alias);
  }
}

class FilmRow extends DataClass implements Insertable<FilmRow> {
  final String slug;
  final String? name;
  final String? type;
  final int? year;
  final String? posterUrl;
  final String? thumbUrl;
  final String? episodeCurrent;
  final String json;
  final int updatedAt;
  const FilmRow({
    required this.slug,
    this.name,
    this.type,
    this.year,
    this.posterUrl,
    this.thumbUrl,
    this.episodeCurrent,
    required this.json,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || thumbUrl != null) {
      map['thumb_url'] = Variable<String>(thumbUrl);
    }
    if (!nullToAbsent || episodeCurrent != null) {
      map['episode_current'] = Variable<String>(episodeCurrent);
    }
    map['json'] = Variable<String>(json);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FilmEntriesCompanion toCompanion(bool nullToAbsent) {
    return FilmEntriesCompanion(
      slug: Value(slug),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      thumbUrl: thumbUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbUrl),
      episodeCurrent: episodeCurrent == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeCurrent),
      json: Value(json),
      updatedAt: Value(updatedAt),
    );
  }

  factory FilmRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmRow(
      slug: serializer.fromJson<String>(json['slug']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      year: serializer.fromJson<int?>(json['year']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      thumbUrl: serializer.fromJson<String?>(json['thumbUrl']),
      episodeCurrent: serializer.fromJson<String?>(json['episodeCurrent']),
      json: serializer.fromJson<String>(json['json']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<String?>(type),
      'year': serializer.toJson<int?>(year),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'thumbUrl': serializer.toJson<String?>(thumbUrl),
      'episodeCurrent': serializer.toJson<String?>(episodeCurrent),
      'json': serializer.toJson<String>(json),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  FilmRow copyWith({
    String? slug,
    Value<String?> name = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> posterUrl = const Value.absent(),
    Value<String?> thumbUrl = const Value.absent(),
    Value<String?> episodeCurrent = const Value.absent(),
    String? json,
    int? updatedAt,
  }) => FilmRow(
    slug: slug ?? this.slug,
    name: name.present ? name.value : this.name,
    type: type.present ? type.value : this.type,
    year: year.present ? year.value : this.year,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    thumbUrl: thumbUrl.present ? thumbUrl.value : this.thumbUrl,
    episodeCurrent: episodeCurrent.present
        ? episodeCurrent.value
        : this.episodeCurrent,
    json: json ?? this.json,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FilmRow copyWithCompanion(FilmEntriesCompanion data) {
    return FilmRow(
      slug: data.slug.present ? data.slug.value : this.slug,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      year: data.year.present ? data.year.value : this.year,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      thumbUrl: data.thumbUrl.present ? data.thumbUrl.value : this.thumbUrl,
      episodeCurrent: data.episodeCurrent.present
          ? data.episodeCurrent.value
          : this.episodeCurrent,
      json: data.json.present ? data.json.value : this.json,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmRow(')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('year: $year, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('episodeCurrent: $episodeCurrent, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    slug,
    name,
    type,
    year,
    posterUrl,
    thumbUrl,
    episodeCurrent,
    json,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmRow &&
          other.slug == this.slug &&
          other.name == this.name &&
          other.type == this.type &&
          other.year == this.year &&
          other.posterUrl == this.posterUrl &&
          other.thumbUrl == this.thumbUrl &&
          other.episodeCurrent == this.episodeCurrent &&
          other.json == this.json &&
          other.updatedAt == this.updatedAt);
}

class FilmEntriesCompanion extends UpdateCompanion<FilmRow> {
  final Value<String> slug;
  final Value<String?> name;
  final Value<String?> type;
  final Value<int?> year;
  final Value<String?> posterUrl;
  final Value<String?> thumbUrl;
  final Value<String?> episodeCurrent;
  final Value<String> json;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FilmEntriesCompanion({
    this.slug = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.year = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.thumbUrl = const Value.absent(),
    this.episodeCurrent = const Value.absent(),
    this.json = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilmEntriesCompanion.insert({
    required String slug,
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.year = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.thumbUrl = const Value.absent(),
    this.episodeCurrent = const Value.absent(),
    required String json,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       json = Value(json),
       updatedAt = Value(updatedAt);
  static Insertable<FilmRow> custom({
    Expression<String>? slug,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? year,
    Expression<String>? posterUrl,
    Expression<String>? thumbUrl,
    Expression<String>? episodeCurrent,
    Expression<String>? json,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (year != null) 'year': year,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (thumbUrl != null) 'thumb_url': thumbUrl,
      if (episodeCurrent != null) 'episode_current': episodeCurrent,
      if (json != null) 'json': json,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilmEntriesCompanion copyWith({
    Value<String>? slug,
    Value<String?>? name,
    Value<String?>? type,
    Value<int?>? year,
    Value<String?>? posterUrl,
    Value<String?>? thumbUrl,
    Value<String?>? episodeCurrent,
    Value<String>? json,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return FilmEntriesCompanion(
      slug: slug ?? this.slug,
      name: name ?? this.name,
      type: type ?? this.type,
      year: year ?? this.year,
      posterUrl: posterUrl ?? this.posterUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      episodeCurrent: episodeCurrent ?? this.episodeCurrent,
      json: json ?? this.json,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (thumbUrl.present) {
      map['thumb_url'] = Variable<String>(thumbUrl.value);
    }
    if (episodeCurrent.present) {
      map['episode_current'] = Variable<String>(episodeCurrent.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmEntriesCompanion(')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('year: $year, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('episodeCurrent: $episodeCurrent, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilmListsTable extends FilmLists
    with TableInfo<$FilmListsTable, FilmListRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listKeyMeta = const VerificationMeta(
    'listKey',
  );
  @override
  late final GeneratedColumn<String> listKey = GeneratedColumn<String>(
    'list_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugsMeta = const VerificationMeta('slugs');
  @override
  late final GeneratedColumn<String> slugs = GeneratedColumn<String>(
    'slugs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metaMeta = const VerificationMeta('meta');
  @override
  late final GeneratedColumn<String> meta = GeneratedColumn<String>(
    'meta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [listKey, slugs, meta, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmListRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_key')) {
      context.handle(
        _listKeyMeta,
        listKey.isAcceptableOrUnknown(data['list_key']!, _listKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_listKeyMeta);
    }
    if (data.containsKey('slugs')) {
      context.handle(
        _slugsMeta,
        slugs.isAcceptableOrUnknown(data['slugs']!, _slugsMeta),
      );
    } else if (isInserting) {
      context.missing(_slugsMeta);
    }
    if (data.containsKey('meta')) {
      context.handle(
        _metaMeta,
        meta.isAcceptableOrUnknown(data['meta']!, _metaMeta),
      );
    } else if (isInserting) {
      context.missing(_metaMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listKey};
  @override
  FilmListRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmListRow(
      listKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_key'],
      )!,
      slugs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slugs'],
      )!,
      meta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $FilmListsTable createAlias(String alias) {
    return $FilmListsTable(attachedDatabase, alias);
  }
}

class FilmListRow extends DataClass implements Insertable<FilmListRow> {
  final String listKey;
  final String slugs;
  final String meta;
  final int fetchedAt;
  const FilmListRow({
    required this.listKey,
    required this.slugs,
    required this.meta,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_key'] = Variable<String>(listKey);
    map['slugs'] = Variable<String>(slugs);
    map['meta'] = Variable<String>(meta);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  FilmListsCompanion toCompanion(bool nullToAbsent) {
    return FilmListsCompanion(
      listKey: Value(listKey),
      slugs: Value(slugs),
      meta: Value(meta),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory FilmListRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmListRow(
      listKey: serializer.fromJson<String>(json['listKey']),
      slugs: serializer.fromJson<String>(json['slugs']),
      meta: serializer.fromJson<String>(json['meta']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listKey': serializer.toJson<String>(listKey),
      'slugs': serializer.toJson<String>(slugs),
      'meta': serializer.toJson<String>(meta),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  FilmListRow copyWith({
    String? listKey,
    String? slugs,
    String? meta,
    int? fetchedAt,
  }) => FilmListRow(
    listKey: listKey ?? this.listKey,
    slugs: slugs ?? this.slugs,
    meta: meta ?? this.meta,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  FilmListRow copyWithCompanion(FilmListsCompanion data) {
    return FilmListRow(
      listKey: data.listKey.present ? data.listKey.value : this.listKey,
      slugs: data.slugs.present ? data.slugs.value : this.slugs,
      meta: data.meta.present ? data.meta.value : this.meta,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmListRow(')
          ..write('listKey: $listKey, ')
          ..write('slugs: $slugs, ')
          ..write('meta: $meta, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(listKey, slugs, meta, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmListRow &&
          other.listKey == this.listKey &&
          other.slugs == this.slugs &&
          other.meta == this.meta &&
          other.fetchedAt == this.fetchedAt);
}

class FilmListsCompanion extends UpdateCompanion<FilmListRow> {
  final Value<String> listKey;
  final Value<String> slugs;
  final Value<String> meta;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const FilmListsCompanion({
    this.listKey = const Value.absent(),
    this.slugs = const Value.absent(),
    this.meta = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilmListsCompanion.insert({
    required String listKey,
    required String slugs,
    required String meta,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : listKey = Value(listKey),
       slugs = Value(slugs),
       meta = Value(meta),
       fetchedAt = Value(fetchedAt);
  static Insertable<FilmListRow> custom({
    Expression<String>? listKey,
    Expression<String>? slugs,
    Expression<String>? meta,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listKey != null) 'list_key': listKey,
      if (slugs != null) 'slugs': slugs,
      if (meta != null) 'meta': meta,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilmListsCompanion copyWith({
    Value<String>? listKey,
    Value<String>? slugs,
    Value<String>? meta,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return FilmListsCompanion(
      listKey: listKey ?? this.listKey,
      slugs: slugs ?? this.slugs,
      meta: meta ?? this.meta,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listKey.present) {
      map['list_key'] = Variable<String>(listKey.value);
    }
    if (slugs.present) {
      map['slugs'] = Variable<String>(slugs.value);
    }
    if (meta.present) {
      map['meta'] = Variable<String>(meta.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmListsCompanion(')
          ..write('listKey: $listKey, ')
          ..write('slugs: $slugs, ')
          ..write('meta: $meta, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilmDetailsTable extends FilmDetails
    with TableInfo<$FilmDetailsTable, FilmDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [slug, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmDetailRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  FilmDetailRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmDetailRow(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $FilmDetailsTable createAlias(String alias) {
    return $FilmDetailsTable(attachedDatabase, alias);
  }
}

class FilmDetailRow extends DataClass implements Insertable<FilmDetailRow> {
  final String slug;
  final String json;
  final int fetchedAt;
  const FilmDetailRow({
    required this.slug,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  FilmDetailsCompanion toCompanion(bool nullToAbsent) {
    return FilmDetailsCompanion(
      slug: Value(slug),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory FilmDetailRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmDetailRow(
      slug: serializer.fromJson<String>(json['slug']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  FilmDetailRow copyWith({String? slug, String? json, int? fetchedAt}) =>
      FilmDetailRow(
        slug: slug ?? this.slug,
        json: json ?? this.json,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  FilmDetailRow copyWithCompanion(FilmDetailsCompanion data) {
    return FilmDetailRow(
      slug: data.slug.present ? data.slug.value : this.slug,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmDetailRow(')
          ..write('slug: $slug, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slug, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmDetailRow &&
          other.slug == this.slug &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class FilmDetailsCompanion extends UpdateCompanion<FilmDetailRow> {
  final Value<String> slug;
  final Value<String> json;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const FilmDetailsCompanion({
    this.slug = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilmDetailsCompanion.insert({
    required String slug,
    required String json,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<FilmDetailRow> custom({
    Expression<String>? slug,
    Expression<String>? json,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilmDetailsCompanion copyWith({
    Value<String>? slug,
    Value<String>? json,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return FilmDetailsCompanion(
      slug: slug ?? this.slug,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmDetailsCompanion(')
          ..write('slug: $slug, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilmPeoplesTable extends FilmPeoples
    with TableInfo<$FilmPeoplesTable, FilmPeopleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmPeoplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [slug, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_peoples';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmPeopleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  FilmPeopleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmPeopleRow(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $FilmPeoplesTable createAlias(String alias) {
    return $FilmPeoplesTable(attachedDatabase, alias);
  }
}

class FilmPeopleRow extends DataClass implements Insertable<FilmPeopleRow> {
  final String slug;
  final String json;
  final int fetchedAt;
  const FilmPeopleRow({
    required this.slug,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  FilmPeoplesCompanion toCompanion(bool nullToAbsent) {
    return FilmPeoplesCompanion(
      slug: Value(slug),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory FilmPeopleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmPeopleRow(
      slug: serializer.fromJson<String>(json['slug']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  FilmPeopleRow copyWith({String? slug, String? json, int? fetchedAt}) =>
      FilmPeopleRow(
        slug: slug ?? this.slug,
        json: json ?? this.json,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  FilmPeopleRow copyWithCompanion(FilmPeoplesCompanion data) {
    return FilmPeopleRow(
      slug: data.slug.present ? data.slug.value : this.slug,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmPeopleRow(')
          ..write('slug: $slug, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slug, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmPeopleRow &&
          other.slug == this.slug &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class FilmPeoplesCompanion extends UpdateCompanion<FilmPeopleRow> {
  final Value<String> slug;
  final Value<String> json;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const FilmPeoplesCompanion({
    this.slug = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilmPeoplesCompanion.insert({
    required String slug,
    required String json,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<FilmPeopleRow> custom({
    Expression<String>? slug,
    Expression<String>? json,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilmPeoplesCompanion copyWith({
    Value<String>? slug,
    Value<String>? json,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return FilmPeoplesCompanion(
      slug: slug ?? this.slug,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmPeoplesCompanion(')
          ..write('slug: $slug, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilmImagesTable extends FilmImages
    with TableInfo<$FilmImagesTable, FilmImagesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [slug, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmImagesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  FilmImagesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmImagesRow(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $FilmImagesTable createAlias(String alias) {
    return $FilmImagesTable(attachedDatabase, alias);
  }
}

class FilmImagesRow extends DataClass implements Insertable<FilmImagesRow> {
  final String slug;
  final String json;
  final int fetchedAt;
  const FilmImagesRow({
    required this.slug,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  FilmImagesCompanion toCompanion(bool nullToAbsent) {
    return FilmImagesCompanion(
      slug: Value(slug),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory FilmImagesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmImagesRow(
      slug: serializer.fromJson<String>(json['slug']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  FilmImagesRow copyWith({String? slug, String? json, int? fetchedAt}) =>
      FilmImagesRow(
        slug: slug ?? this.slug,
        json: json ?? this.json,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  FilmImagesRow copyWithCompanion(FilmImagesCompanion data) {
    return FilmImagesRow(
      slug: data.slug.present ? data.slug.value : this.slug,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmImagesRow(')
          ..write('slug: $slug, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slug, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmImagesRow &&
          other.slug == this.slug &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class FilmImagesCompanion extends UpdateCompanion<FilmImagesRow> {
  final Value<String> slug;
  final Value<String> json;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const FilmImagesCompanion({
    this.slug = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilmImagesCompanion.insert({
    required String slug,
    required String json,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<FilmImagesRow> custom({
    Expression<String>? slug,
    Expression<String>? json,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilmImagesCompanion copyWith({
    Value<String>? slug,
    Value<String>? json,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return FilmImagesCompanion(
      slug: slug ?? this.slug,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmImagesCompanion(')
          ..write('slug: $slug, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FilmEntriesTable filmEntries = $FilmEntriesTable(this);
  late final $FilmListsTable filmLists = $FilmListsTable(this);
  late final $FilmDetailsTable filmDetails = $FilmDetailsTable(this);
  late final $FilmPeoplesTable filmPeoples = $FilmPeoplesTable(this);
  late final $FilmImagesTable filmImages = $FilmImagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    filmEntries,
    filmLists,
    filmDetails,
    filmPeoples,
    filmImages,
  ];
}

typedef $$FilmEntriesTableCreateCompanionBuilder =
    FilmEntriesCompanion Function({
      required String slug,
      Value<String?> name,
      Value<String?> type,
      Value<int?> year,
      Value<String?> posterUrl,
      Value<String?> thumbUrl,
      Value<String?> episodeCurrent,
      required String json,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$FilmEntriesTableUpdateCompanionBuilder =
    FilmEntriesCompanion Function({
      Value<String> slug,
      Value<String?> name,
      Value<String?> type,
      Value<int?> year,
      Value<String?> posterUrl,
      Value<String?> thumbUrl,
      Value<String?> episodeCurrent,
      Value<String> json,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$FilmEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FilmEntriesTable> {
  $$FilmEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbUrl => $composableBuilder(
    column: $table.thumbUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeCurrent => $composableBuilder(
    column: $table.episodeCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilmEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmEntriesTable> {
  $$FilmEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbUrl => $composableBuilder(
    column: $table.thumbUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeCurrent => $composableBuilder(
    column: $table.episodeCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilmEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmEntriesTable> {
  $$FilmEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get thumbUrl =>
      $composableBuilder(column: $table.thumbUrl, builder: (column) => column);

  GeneratedColumn<String> get episodeCurrent => $composableBuilder(
    column: $table.episodeCurrent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FilmEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmEntriesTable,
          FilmRow,
          $$FilmEntriesTableFilterComposer,
          $$FilmEntriesTableOrderingComposer,
          $$FilmEntriesTableAnnotationComposer,
          $$FilmEntriesTableCreateCompanionBuilder,
          $$FilmEntriesTableUpdateCompanionBuilder,
          (FilmRow, BaseReferences<_$AppDatabase, $FilmEntriesTable, FilmRow>),
          FilmRow,
          PrefetchHooks Function()
        > {
  $$FilmEntriesTableTableManager(_$AppDatabase db, $FilmEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slug = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> thumbUrl = const Value.absent(),
                Value<String?> episodeCurrent = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmEntriesCompanion(
                slug: slug,
                name: name,
                type: type,
                year: year,
                posterUrl: posterUrl,
                thumbUrl: thumbUrl,
                episodeCurrent: episodeCurrent,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                Value<String?> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> thumbUrl = const Value.absent(),
                Value<String?> episodeCurrent = const Value.absent(),
                required String json,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FilmEntriesCompanion.insert(
                slug: slug,
                name: name,
                type: type,
                year: year,
                posterUrl: posterUrl,
                thumbUrl: thumbUrl,
                episodeCurrent: episodeCurrent,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilmEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmEntriesTable,
      FilmRow,
      $$FilmEntriesTableFilterComposer,
      $$FilmEntriesTableOrderingComposer,
      $$FilmEntriesTableAnnotationComposer,
      $$FilmEntriesTableCreateCompanionBuilder,
      $$FilmEntriesTableUpdateCompanionBuilder,
      (FilmRow, BaseReferences<_$AppDatabase, $FilmEntriesTable, FilmRow>),
      FilmRow,
      PrefetchHooks Function()
    >;
typedef $$FilmListsTableCreateCompanionBuilder =
    FilmListsCompanion Function({
      required String listKey,
      required String slugs,
      required String meta,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$FilmListsTableUpdateCompanionBuilder =
    FilmListsCompanion Function({
      Value<String> listKey,
      Value<String> slugs,
      Value<String> meta,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$FilmListsTableFilterComposer
    extends Composer<_$AppDatabase, $FilmListsTable> {
  $$FilmListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get listKey => $composableBuilder(
    column: $table.listKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slugs => $composableBuilder(
    column: $table.slugs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilmListsTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmListsTable> {
  $$FilmListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get listKey => $composableBuilder(
    column: $table.listKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slugs => $composableBuilder(
    column: $table.slugs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilmListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmListsTable> {
  $$FilmListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get listKey =>
      $composableBuilder(column: $table.listKey, builder: (column) => column);

  GeneratedColumn<String> get slugs =>
      $composableBuilder(column: $table.slugs, builder: (column) => column);

  GeneratedColumn<String> get meta =>
      $composableBuilder(column: $table.meta, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FilmListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmListsTable,
          FilmListRow,
          $$FilmListsTableFilterComposer,
          $$FilmListsTableOrderingComposer,
          $$FilmListsTableAnnotationComposer,
          $$FilmListsTableCreateCompanionBuilder,
          $$FilmListsTableUpdateCompanionBuilder,
          (
            FilmListRow,
            BaseReferences<_$AppDatabase, $FilmListsTable, FilmListRow>,
          ),
          FilmListRow,
          PrefetchHooks Function()
        > {
  $$FilmListsTableTableManager(_$AppDatabase db, $FilmListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> listKey = const Value.absent(),
                Value<String> slugs = const Value.absent(),
                Value<String> meta = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmListsCompanion(
                listKey: listKey,
                slugs: slugs,
                meta: meta,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listKey,
                required String slugs,
                required String meta,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => FilmListsCompanion.insert(
                listKey: listKey,
                slugs: slugs,
                meta: meta,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilmListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmListsTable,
      FilmListRow,
      $$FilmListsTableFilterComposer,
      $$FilmListsTableOrderingComposer,
      $$FilmListsTableAnnotationComposer,
      $$FilmListsTableCreateCompanionBuilder,
      $$FilmListsTableUpdateCompanionBuilder,
      (
        FilmListRow,
        BaseReferences<_$AppDatabase, $FilmListsTable, FilmListRow>,
      ),
      FilmListRow,
      PrefetchHooks Function()
    >;
typedef $$FilmDetailsTableCreateCompanionBuilder =
    FilmDetailsCompanion Function({
      required String slug,
      required String json,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$FilmDetailsTableUpdateCompanionBuilder =
    FilmDetailsCompanion Function({
      Value<String> slug,
      Value<String> json,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$FilmDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $FilmDetailsTable> {
  $$FilmDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilmDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmDetailsTable> {
  $$FilmDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilmDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmDetailsTable> {
  $$FilmDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FilmDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmDetailsTable,
          FilmDetailRow,
          $$FilmDetailsTableFilterComposer,
          $$FilmDetailsTableOrderingComposer,
          $$FilmDetailsTableAnnotationComposer,
          $$FilmDetailsTableCreateCompanionBuilder,
          $$FilmDetailsTableUpdateCompanionBuilder,
          (
            FilmDetailRow,
            BaseReferences<_$AppDatabase, $FilmDetailsTable, FilmDetailRow>,
          ),
          FilmDetailRow,
          PrefetchHooks Function()
        > {
  $$FilmDetailsTableTableManager(_$AppDatabase db, $FilmDetailsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slug = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmDetailsCompanion(
                slug: slug,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                required String json,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => FilmDetailsCompanion.insert(
                slug: slug,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilmDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmDetailsTable,
      FilmDetailRow,
      $$FilmDetailsTableFilterComposer,
      $$FilmDetailsTableOrderingComposer,
      $$FilmDetailsTableAnnotationComposer,
      $$FilmDetailsTableCreateCompanionBuilder,
      $$FilmDetailsTableUpdateCompanionBuilder,
      (
        FilmDetailRow,
        BaseReferences<_$AppDatabase, $FilmDetailsTable, FilmDetailRow>,
      ),
      FilmDetailRow,
      PrefetchHooks Function()
    >;
typedef $$FilmPeoplesTableCreateCompanionBuilder =
    FilmPeoplesCompanion Function({
      required String slug,
      required String json,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$FilmPeoplesTableUpdateCompanionBuilder =
    FilmPeoplesCompanion Function({
      Value<String> slug,
      Value<String> json,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$FilmPeoplesTableFilterComposer
    extends Composer<_$AppDatabase, $FilmPeoplesTable> {
  $$FilmPeoplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilmPeoplesTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmPeoplesTable> {
  $$FilmPeoplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilmPeoplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmPeoplesTable> {
  $$FilmPeoplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FilmPeoplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmPeoplesTable,
          FilmPeopleRow,
          $$FilmPeoplesTableFilterComposer,
          $$FilmPeoplesTableOrderingComposer,
          $$FilmPeoplesTableAnnotationComposer,
          $$FilmPeoplesTableCreateCompanionBuilder,
          $$FilmPeoplesTableUpdateCompanionBuilder,
          (
            FilmPeopleRow,
            BaseReferences<_$AppDatabase, $FilmPeoplesTable, FilmPeopleRow>,
          ),
          FilmPeopleRow,
          PrefetchHooks Function()
        > {
  $$FilmPeoplesTableTableManager(_$AppDatabase db, $FilmPeoplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmPeoplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmPeoplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmPeoplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slug = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmPeoplesCompanion(
                slug: slug,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                required String json,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => FilmPeoplesCompanion.insert(
                slug: slug,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilmPeoplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmPeoplesTable,
      FilmPeopleRow,
      $$FilmPeoplesTableFilterComposer,
      $$FilmPeoplesTableOrderingComposer,
      $$FilmPeoplesTableAnnotationComposer,
      $$FilmPeoplesTableCreateCompanionBuilder,
      $$FilmPeoplesTableUpdateCompanionBuilder,
      (
        FilmPeopleRow,
        BaseReferences<_$AppDatabase, $FilmPeoplesTable, FilmPeopleRow>,
      ),
      FilmPeopleRow,
      PrefetchHooks Function()
    >;
typedef $$FilmImagesTableCreateCompanionBuilder =
    FilmImagesCompanion Function({
      required String slug,
      required String json,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$FilmImagesTableUpdateCompanionBuilder =
    FilmImagesCompanion Function({
      Value<String> slug,
      Value<String> json,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$FilmImagesTableFilterComposer
    extends Composer<_$AppDatabase, $FilmImagesTable> {
  $$FilmImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilmImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmImagesTable> {
  $$FilmImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilmImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmImagesTable> {
  $$FilmImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FilmImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmImagesTable,
          FilmImagesRow,
          $$FilmImagesTableFilterComposer,
          $$FilmImagesTableOrderingComposer,
          $$FilmImagesTableAnnotationComposer,
          $$FilmImagesTableCreateCompanionBuilder,
          $$FilmImagesTableUpdateCompanionBuilder,
          (
            FilmImagesRow,
            BaseReferences<_$AppDatabase, $FilmImagesTable, FilmImagesRow>,
          ),
          FilmImagesRow,
          PrefetchHooks Function()
        > {
  $$FilmImagesTableTableManager(_$AppDatabase db, $FilmImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slug = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilmImagesCompanion(
                slug: slug,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                required String json,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => FilmImagesCompanion.insert(
                slug: slug,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilmImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmImagesTable,
      FilmImagesRow,
      $$FilmImagesTableFilterComposer,
      $$FilmImagesTableOrderingComposer,
      $$FilmImagesTableAnnotationComposer,
      $$FilmImagesTableCreateCompanionBuilder,
      $$FilmImagesTableUpdateCompanionBuilder,
      (
        FilmImagesRow,
        BaseReferences<_$AppDatabase, $FilmImagesTable, FilmImagesRow>,
      ),
      FilmImagesRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FilmEntriesTableTableManager get filmEntries =>
      $$FilmEntriesTableTableManager(_db, _db.filmEntries);
  $$FilmListsTableTableManager get filmLists =>
      $$FilmListsTableTableManager(_db, _db.filmLists);
  $$FilmDetailsTableTableManager get filmDetails =>
      $$FilmDetailsTableTableManager(_db, _db.filmDetails);
  $$FilmPeoplesTableTableManager get filmPeoples =>
      $$FilmPeoplesTableTableManager(_db, _db.filmPeoples);
  $$FilmImagesTableTableManager get filmImages =>
      $$FilmImagesTableTableManager(_db, _db.filmImages);
}
