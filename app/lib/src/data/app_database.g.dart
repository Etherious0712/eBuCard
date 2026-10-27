// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OwnCardsTable extends OwnCards with TableInfo<$OwnCardsTable, OwnCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, sortOrder, updatedAt, dirty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'own_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OwnCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $OwnCardsTable createAlias(String alias) {
    return $OwnCardsTable(attachedDatabase, alias);
  }
}

class OwnCard extends DataClass implements Insertable<OwnCard> {
  /// The card's UUID ([BusinessCard.id]).
  final String id;

  /// The whole card as `BusinessCard.toJson()` text.
  final String json;

  /// Position in the My Cards list; new cards go last.
  final int sortOrder;

  /// Copy of [BusinessCard.updatedAt], for sync.
  final DateTime updatedAt;

  /// Changed on this phone and not yet sent to the account (see sync).
  final bool dirty;
  const OwnCard({
    required this.id,
    required this.json,
    required this.sortOrder,
    required this.updatedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  OwnCardsCompanion toCompanion(bool nullToAbsent) {
    return OwnCardsCompanion(
      id: Value(id),
      json: Value(json),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
    );
  }

  factory OwnCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnCard(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  OwnCard copyWith({
    String? id,
    String? json,
    int? sortOrder,
    DateTime? updatedAt,
    bool? dirty,
  }) => OwnCard(
    id: id ?? this.id,
    json: json ?? this.json,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
  );
  OwnCard copyWithCompanion(OwnCardsCompanion data) {
    return OwnCard(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnCard(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, sortOrder, updatedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnCard &&
          other.id == this.id &&
          other.json == this.json &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty);
}

class OwnCardsCompanion extends UpdateCompanion<OwnCard> {
  final Value<String> id;
  final Value<String> json;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const OwnCardsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OwnCardsCompanion.insert({
    required String id,
    required String json,
    required int sortOrder,
    required DateTime updatedAt,
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       sortOrder = Value(sortOrder),
       updatedAt = Value(updatedAt);
  static Insertable<OwnCard> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OwnCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return OwnCardsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnCardsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceivedCardsTable extends ReceivedCards
    with TableInfo<$ReceivedCardsTable, ReceivedCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceivedCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    json,
    searchText,
    receivedAt,
    updatedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'received_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceivedCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTextMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceivedCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceivedCardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $ReceivedCardsTable createAlias(String alias) {
    return $ReceivedCardsTable(attachedDatabase, alias);
  }
}

class ReceivedCardRow extends DataClass implements Insertable<ReceivedCardRow> {
  /// The Inbox entry's UUID ([ReceivedCard.id]).
  final String id;

  /// The whole entry as `ReceivedCard.toJson()` text.
  final String json;

  /// Lower-case name, company and emails, for Inbox search.
  final String searchText;

  /// Copy of [ReceivedCard.receivedAt]; the Inbox is sorted newest first.
  final DateTime receivedAt;

  /// Copy of [ReceivedCard.updatedAt], for sync.
  final DateTime updatedAt;

  /// Changed on this phone and not yet sent to the account (see sync).
  final bool dirty;
  const ReceivedCardRow({
    required this.id,
    required this.json,
    required this.searchText,
    required this.receivedAt,
    required this.updatedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['search_text'] = Variable<String>(searchText);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ReceivedCardsCompanion toCompanion(bool nullToAbsent) {
    return ReceivedCardsCompanion(
      id: Value(id),
      json: Value(json),
      searchText: Value(searchText),
      receivedAt: Value(receivedAt),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
    );
  }

  factory ReceivedCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceivedCardRow(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      searchText: serializer.fromJson<String>(json['searchText']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'searchText': serializer.toJson<String>(searchText),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  ReceivedCardRow copyWith({
    String? id,
    String? json,
    String? searchText,
    DateTime? receivedAt,
    DateTime? updatedAt,
    bool? dirty,
  }) => ReceivedCardRow(
    id: id ?? this.id,
    json: json ?? this.json,
    searchText: searchText ?? this.searchText,
    receivedAt: receivedAt ?? this.receivedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
  );
  ReceivedCardRow copyWithCompanion(ReceivedCardsCompanion data) {
    return ReceivedCardRow(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceivedCardRow(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('searchText: $searchText, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, json, searchText, receivedAt, updatedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceivedCardRow &&
          other.id == this.id &&
          other.json == this.json &&
          other.searchText == this.searchText &&
          other.receivedAt == this.receivedAt &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty);
}

class ReceivedCardsCompanion extends UpdateCompanion<ReceivedCardRow> {
  final Value<String> id;
  final Value<String> json;
  final Value<String> searchText;
  final Value<DateTime> receivedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ReceivedCardsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.searchText = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceivedCardsCompanion.insert({
    required String id,
    required String json,
    required String searchText,
    required DateTime receivedAt,
    required DateTime updatedAt,
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       searchText = Value(searchText),
       receivedAt = Value(receivedAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReceivedCardRow> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<String>? searchText,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (searchText != null) 'search_text': searchText,
      if (receivedAt != null) 'received_at': receivedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceivedCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<String>? searchText,
    Value<DateTime>? receivedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return ReceivedCardsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      searchText: searchText ?? this.searchText,
      receivedAt: receivedAt ?? this.receivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceivedCardsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('searchText: $searchText, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  /// Setting name; see the constants in `settings_repository.dart`.
  final String key;

  /// Setting value as text.
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingDeletionsTable extends PendingDeletions
    with TableInfo<$PendingDeletionsTable, PendingDeletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingDeletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, id, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_deletions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingDeletionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, id};
  @override
  PendingDeletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingDeletionRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $PendingDeletionsTable createAlias(String alias) {
    return $PendingDeletionsTable(attachedDatabase, alias);
  }
}

class PendingDeletionRow extends DataClass
    implements Insertable<PendingDeletionRow> {
  /// Which kind of record: `cards` or `received`.
  final String kind;

  /// The deleted record's id.
  final String id;

  /// When it was deleted, so a newer edit elsewhere can win.
  final DateTime deletedAt;
  const PendingDeletionRow({
    required this.kind,
    required this.id,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['id'] = Variable<String>(id);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  PendingDeletionsCompanion toCompanion(bool nullToAbsent) {
    return PendingDeletionsCompanion(
      kind: Value(kind),
      id: Value(id),
      deletedAt: Value(deletedAt),
    );
  }

  factory PendingDeletionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingDeletionRow(
      kind: serializer.fromJson<String>(json['kind']),
      id: serializer.fromJson<String>(json['id']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'id': serializer.toJson<String>(id),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  PendingDeletionRow copyWith({
    String? kind,
    String? id,
    DateTime? deletedAt,
  }) => PendingDeletionRow(
    kind: kind ?? this.kind,
    id: id ?? this.id,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  PendingDeletionRow copyWithCompanion(PendingDeletionsCompanion data) {
    return PendingDeletionRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      id: data.id.present ? data.id.value : this.id,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingDeletionRow(')
          ..write('kind: $kind, ')
          ..write('id: $id, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, id, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingDeletionRow &&
          other.kind == this.kind &&
          other.id == this.id &&
          other.deletedAt == this.deletedAt);
}

class PendingDeletionsCompanion extends UpdateCompanion<PendingDeletionRow> {
  final Value<String> kind;
  final Value<String> id;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const PendingDeletionsCompanion({
    this.kind = const Value.absent(),
    this.id = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingDeletionsCompanion.insert({
    required String kind,
    required String id,
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       id = Value(id),
       deletedAt = Value(deletedAt);
  static Insertable<PendingDeletionRow> custom({
    Expression<String>? kind,
    Expression<String>? id,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (id != null) 'id': id,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingDeletionsCompanion copyWith({
    Value<String>? kind,
    Value<String>? id,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return PendingDeletionsCompanion(
      kind: kind ?? this.kind,
      id: id ?? this.id,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingDeletionsCompanion(')
          ..write('kind: $kind, ')
          ..write('id: $id, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OwnCardsTable ownCards = $OwnCardsTable(this);
  late final $ReceivedCardsTable receivedCards = $ReceivedCardsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PendingDeletionsTable pendingDeletions = $PendingDeletionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ownCards,
    receivedCards,
    settings,
    pendingDeletions,
  ];
}

typedef $$OwnCardsTableCreateCompanionBuilder =
    OwnCardsCompanion Function({
      required String id,
      required String json,
      required int sortOrder,
      required DateTime updatedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$OwnCardsTableUpdateCompanionBuilder =
    OwnCardsCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<int> sortOrder,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });

class $$OwnCardsTableFilterComposer
    extends Composer<_$AppDatabase, $OwnCardsTable> {
  $$OwnCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $OwnCardsTable> {
  $$OwnCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OwnCardsTable> {
  $$OwnCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$OwnCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OwnCardsTable,
          OwnCard,
          $$OwnCardsTableFilterComposer,
          $$OwnCardsTableOrderingComposer,
          $$OwnCardsTableAnnotationComposer,
          $$OwnCardsTableCreateCompanionBuilder,
          $$OwnCardsTableUpdateCompanionBuilder,
          (OwnCard, BaseReferences<_$AppDatabase, $OwnCardsTable, OwnCard>),
          OwnCard,
          PrefetchHooks Function()
        > {
  $$OwnCardsTableTableManager(_$AppDatabase db, $OwnCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnCardsCompanion(
                id: id,
                json: json,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required int sortOrder,
                required DateTime updatedAt,
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnCardsCompanion.insert(
                id: id,
                json: json,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OwnCardsTable, OwnCard>(table),
                  BaseReferences<_$AppDatabase, $OwnCardsTable, OwnCard>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OwnCardsTable,
      OwnCard,
      $$OwnCardsTableFilterComposer,
      $$OwnCardsTableOrderingComposer,
      $$OwnCardsTableAnnotationComposer,
      $$OwnCardsTableCreateCompanionBuilder,
      $$OwnCardsTableUpdateCompanionBuilder,
      (OwnCard, BaseReferences<_$AppDatabase, $OwnCardsTable, OwnCard>),
      OwnCard,
      PrefetchHooks Function()
    >;
typedef $$ReceivedCardsTableCreateCompanionBuilder =
    ReceivedCardsCompanion Function({
      required String id,
      required String json,
      required String searchText,
      required DateTime receivedAt,
      required DateTime updatedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$ReceivedCardsTableUpdateCompanionBuilder =
    ReceivedCardsCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<String> searchText,
      Value<DateTime> receivedAt,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });

class $$ReceivedCardsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceivedCardsTable> {
  $$ReceivedCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceivedCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceivedCardsTable> {
  $$ReceivedCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceivedCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceivedCardsTable> {
  $$ReceivedCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$ReceivedCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceivedCardsTable,
          ReceivedCardRow,
          $$ReceivedCardsTableFilterComposer,
          $$ReceivedCardsTableOrderingComposer,
          $$ReceivedCardsTableAnnotationComposer,
          $$ReceivedCardsTableCreateCompanionBuilder,
          $$ReceivedCardsTableUpdateCompanionBuilder,
          (
            ReceivedCardRow,
            BaseReferences<_$AppDatabase, $ReceivedCardsTable, ReceivedCardRow>,
          ),
          ReceivedCardRow,
          PrefetchHooks Function()
        > {
  $$ReceivedCardsTableTableManager(_$AppDatabase db, $ReceivedCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceivedCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceivedCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceivedCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceivedCardsCompanion(
                id: id,
                json: json,
                searchText: searchText,
                receivedAt: receivedAt,
                updatedAt: updatedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required String searchText,
                required DateTime receivedAt,
                required DateTime updatedAt,
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceivedCardsCompanion.insert(
                id: id,
                json: json,
                searchText: searchText,
                receivedAt: receivedAt,
                updatedAt: updatedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceivedCardsTable, ReceivedCardRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReceivedCardsTable,
                    ReceivedCardRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceivedCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceivedCardsTable,
      ReceivedCardRow,
      $$ReceivedCardsTableFilterComposer,
      $$ReceivedCardsTableOrderingComposer,
      $$ReceivedCardsTableAnnotationComposer,
      $$ReceivedCardsTableCreateCompanionBuilder,
      $$ReceivedCardsTableUpdateCompanionBuilder,
      (
        ReceivedCardRow,
        BaseReferences<_$AppDatabase, $ReceivedCardsTable, ReceivedCardRow>,
      ),
      ReceivedCardRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$PendingDeletionsTableCreateCompanionBuilder =
    PendingDeletionsCompanion Function({
      required String kind,
      required String id,
      required DateTime deletedAt,
      Value<int> rowid,
    });
typedef $$PendingDeletionsTableUpdateCompanionBuilder =
    PendingDeletionsCompanion Function({
      Value<String> kind,
      Value<String> id,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$PendingDeletionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingDeletionsTable> {
  $$PendingDeletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingDeletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingDeletionsTable> {
  $$PendingDeletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingDeletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingDeletionsTable> {
  $$PendingDeletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PendingDeletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingDeletionsTable,
          PendingDeletionRow,
          $$PendingDeletionsTableFilterComposer,
          $$PendingDeletionsTableOrderingComposer,
          $$PendingDeletionsTableAnnotationComposer,
          $$PendingDeletionsTableCreateCompanionBuilder,
          $$PendingDeletionsTableUpdateCompanionBuilder,
          (
            PendingDeletionRow,
            BaseReferences<
              _$AppDatabase,
              $PendingDeletionsTable,
              PendingDeletionRow
            >,
          ),
          PendingDeletionRow,
          PrefetchHooks Function()
        > {
  $$PendingDeletionsTableTableManager(
    _$AppDatabase db,
    $PendingDeletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingDeletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingDeletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingDeletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingDeletionsCompanion(
                kind: kind,
                id: id,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String id,
                required DateTime deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingDeletionsCompanion.insert(
                kind: kind,
                id: id,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingDeletionsTable, PendingDeletionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingDeletionsTable,
                    PendingDeletionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingDeletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingDeletionsTable,
      PendingDeletionRow,
      $$PendingDeletionsTableFilterComposer,
      $$PendingDeletionsTableOrderingComposer,
      $$PendingDeletionsTableAnnotationComposer,
      $$PendingDeletionsTableCreateCompanionBuilder,
      $$PendingDeletionsTableUpdateCompanionBuilder,
      (
        PendingDeletionRow,
        BaseReferences<
          _$AppDatabase,
          $PendingDeletionsTable,
          PendingDeletionRow
        >,
      ),
      PendingDeletionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OwnCardsTableTableManager get ownCards =>
      $$OwnCardsTableTableManager(_db, _db.ownCards);
  $$ReceivedCardsTableTableManager get receivedCards =>
      $$ReceivedCardsTableTableManager(_db, _db.receivedCards);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$PendingDeletionsTableTableManager get pendingDeletions =>
      $$PendingDeletionsTableTableManager(_db, _db.pendingDeletions);
}
