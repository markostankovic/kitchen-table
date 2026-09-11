// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ShoppingListCacheTable extends ShoppingListCache
    with TableInfo<$ShoppingListCacheTable, ShoppingListCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
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
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    generatedAt,
    updatedAt,
    data,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingListCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {householdId},
  ];
  @override
  ShoppingListCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $ShoppingListCacheTable createAlias(String alias) {
    return $ShoppingListCacheTable(attachedDatabase, alias);
  }
}

class ShoppingListCacheData extends DataClass
    implements Insertable<ShoppingListCacheData> {
  final String id;
  final String householdId;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final String data;
  const ShoppingListCacheData({
    required this.id,
    required this.householdId,
    required this.generatedAt,
    required this.updatedAt,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['data'] = Variable<String>(data);
    return map;
  }

  ShoppingListCacheCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      generatedAt: Value(generatedAt),
      updatedAt: Value(updatedAt),
      data: Value(data),
    );
  }

  factory ShoppingListCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListCacheData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'data': serializer.toJson<String>(data),
    };
  }

  ShoppingListCacheData copyWith({
    String? id,
    String? householdId,
    DateTime? generatedAt,
    DateTime? updatedAt,
    String? data,
  }) => ShoppingListCacheData(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    generatedAt: generatedAt ?? this.generatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    data: data ?? this.data,
  );
  ShoppingListCacheData copyWithCompanion(ShoppingListCacheCompanion data) {
    return ShoppingListCacheData(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListCacheData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, generatedAt, updatedAt, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListCacheData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.generatedAt == this.generatedAt &&
          other.updatedAt == this.updatedAt &&
          other.data == this.data);
}

class ShoppingListCacheCompanion
    extends UpdateCompanion<ShoppingListCacheData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<DateTime> generatedAt;
  final Value<DateTime> updatedAt;
  final Value<String> data;
  final Value<int> rowid;
  const ShoppingListCacheCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListCacheCompanion.insert({
    required String id,
    required String householdId,
    required DateTime generatedAt,
    required DateTime updatedAt,
    required String data,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       generatedAt = Value(generatedAt),
       updatedAt = Value(updatedAt),
       data = Value(data);
  static Insertable<ShoppingListCacheData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<DateTime>? generatedAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<DateTime>? generatedAt,
    Value<DateTime>? updatedAt,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return ShoppingListCacheCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      generatedAt: generatedAt ?? this.generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListCacheCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitCatalogCacheTable extends UnitCatalogCache
    with TableInfo<$UnitCatalogCacheTable, UnitCatalogCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitCatalogCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fetchedAt, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unit_catalog_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnitCatalogCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnitCatalogCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitCatalogCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $UnitCatalogCacheTable createAlias(String alias) {
    return $UnitCatalogCacheTable(attachedDatabase, alias);
  }
}

class UnitCatalogCacheData extends DataClass
    implements Insertable<UnitCatalogCacheData> {
  final String id;
  final DateTime fetchedAt;
  final String data;
  const UnitCatalogCacheData({
    required this.id,
    required this.fetchedAt,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['data'] = Variable<String>(data);
    return map;
  }

  UnitCatalogCacheCompanion toCompanion(bool nullToAbsent) {
    return UnitCatalogCacheCompanion(
      id: Value(id),
      fetchedAt: Value(fetchedAt),
      data: Value(data),
    );
  }

  factory UnitCatalogCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitCatalogCacheData(
      id: serializer.fromJson<String>(json['id']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'data': serializer.toJson<String>(data),
    };
  }

  UnitCatalogCacheData copyWith({
    String? id,
    DateTime? fetchedAt,
    String? data,
  }) => UnitCatalogCacheData(
    id: id ?? this.id,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    data: data ?? this.data,
  );
  UnitCatalogCacheData copyWithCompanion(UnitCatalogCacheCompanion data) {
    return UnitCatalogCacheData(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitCatalogCacheData(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fetchedAt, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitCatalogCacheData &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.data == this.data);
}

class UnitCatalogCacheCompanion extends UpdateCompanion<UnitCatalogCacheData> {
  final Value<String> id;
  final Value<DateTime> fetchedAt;
  final Value<String> data;
  final Value<int> rowid;
  const UnitCatalogCacheCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitCatalogCacheCompanion.insert({
    required String id,
    required DateTime fetchedAt,
    required String data,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fetchedAt = Value(fetchedAt),
       data = Value(data);
  static Insertable<UnitCatalogCacheData> custom({
    Expression<String>? id,
    Expression<DateTime>? fetchedAt,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitCatalogCacheCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? fetchedAt,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return UnitCatalogCacheCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitCatalogCacheCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ShoppingListCacheTable shoppingListCache =
      $ShoppingListCacheTable(this);
  late final $UnitCatalogCacheTable unitCatalogCache = $UnitCatalogCacheTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    shoppingListCache,
    unitCatalogCache,
  ];
}

typedef $$ShoppingListCacheTableCreateCompanionBuilder =
    ShoppingListCacheCompanion Function({
      required String id,
      required String householdId,
      required DateTime generatedAt,
      required DateTime updatedAt,
      required String data,
      Value<int> rowid,
    });
typedef $$ShoppingListCacheTableUpdateCompanionBuilder =
    ShoppingListCacheCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<DateTime> generatedAt,
      Value<DateTime> updatedAt,
      Value<String> data,
      Value<int> rowid,
    });

class $$ShoppingListCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListCacheTable> {
  $$ShoppingListCacheTableFilterComposer({
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

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingListCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListCacheTable> {
  $$ShoppingListCacheTableOrderingComposer({
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

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListCacheTable> {
  $$ShoppingListCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$ShoppingListCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListCacheTable,
          ShoppingListCacheData,
          $$ShoppingListCacheTableFilterComposer,
          $$ShoppingListCacheTableOrderingComposer,
          $$ShoppingListCacheTableAnnotationComposer,
          $$ShoppingListCacheTableCreateCompanionBuilder,
          $$ShoppingListCacheTableUpdateCompanionBuilder,
          (
            ShoppingListCacheData,
            BaseReferences<
              _$AppDatabase,
              $ShoppingListCacheTable,
              ShoppingListCacheData
            >,
          ),
          ShoppingListCacheData,
          PrefetchHooks Function()
        > {
  $$ShoppingListCacheTableTableManager(
    _$AppDatabase db,
    $ShoppingListCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListCacheCompanion(
                id: id,
                householdId: householdId,
                generatedAt: generatedAt,
                updatedAt: updatedAt,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required DateTime generatedAt,
                required DateTime updatedAt,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListCacheCompanion.insert(
                id: id,
                householdId: householdId,
                generatedAt: generatedAt,
                updatedAt: updatedAt,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShoppingListCacheTable, ShoppingListCacheData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ShoppingListCacheTable,
                    ShoppingListCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingListCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListCacheTable,
      ShoppingListCacheData,
      $$ShoppingListCacheTableFilterComposer,
      $$ShoppingListCacheTableOrderingComposer,
      $$ShoppingListCacheTableAnnotationComposer,
      $$ShoppingListCacheTableCreateCompanionBuilder,
      $$ShoppingListCacheTableUpdateCompanionBuilder,
      (
        ShoppingListCacheData,
        BaseReferences<
          _$AppDatabase,
          $ShoppingListCacheTable,
          ShoppingListCacheData
        >,
      ),
      ShoppingListCacheData,
      PrefetchHooks Function()
    >;
typedef $$UnitCatalogCacheTableCreateCompanionBuilder =
    UnitCatalogCacheCompanion Function({
      required String id,
      required DateTime fetchedAt,
      required String data,
      Value<int> rowid,
    });
typedef $$UnitCatalogCacheTableUpdateCompanionBuilder =
    UnitCatalogCacheCompanion Function({
      Value<String> id,
      Value<DateTime> fetchedAt,
      Value<String> data,
      Value<int> rowid,
    });

class $$UnitCatalogCacheTableFilterComposer
    extends Composer<_$AppDatabase, $UnitCatalogCacheTable> {
  $$UnitCatalogCacheTableFilterComposer({
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

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnitCatalogCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitCatalogCacheTable> {
  $$UnitCatalogCacheTableOrderingComposer({
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

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnitCatalogCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitCatalogCacheTable> {
  $$UnitCatalogCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$UnitCatalogCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnitCatalogCacheTable,
          UnitCatalogCacheData,
          $$UnitCatalogCacheTableFilterComposer,
          $$UnitCatalogCacheTableOrderingComposer,
          $$UnitCatalogCacheTableAnnotationComposer,
          $$UnitCatalogCacheTableCreateCompanionBuilder,
          $$UnitCatalogCacheTableUpdateCompanionBuilder,
          (
            UnitCatalogCacheData,
            BaseReferences<
              _$AppDatabase,
              $UnitCatalogCacheTable,
              UnitCatalogCacheData
            >,
          ),
          UnitCatalogCacheData,
          PrefetchHooks Function()
        > {
  $$UnitCatalogCacheTableTableManager(
    _$AppDatabase db,
    $UnitCatalogCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitCatalogCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitCatalogCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitCatalogCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitCatalogCacheCompanion(
                id: id,
                fetchedAt: fetchedAt,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime fetchedAt,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => UnitCatalogCacheCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnitCatalogCacheTable, UnitCatalogCacheData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $UnitCatalogCacheTable,
                    UnitCatalogCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnitCatalogCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnitCatalogCacheTable,
      UnitCatalogCacheData,
      $$UnitCatalogCacheTableFilterComposer,
      $$UnitCatalogCacheTableOrderingComposer,
      $$UnitCatalogCacheTableAnnotationComposer,
      $$UnitCatalogCacheTableCreateCompanionBuilder,
      $$UnitCatalogCacheTableUpdateCompanionBuilder,
      (
        UnitCatalogCacheData,
        BaseReferences<
          _$AppDatabase,
          $UnitCatalogCacheTable,
          UnitCatalogCacheData
        >,
      ),
      UnitCatalogCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ShoppingListCacheTableTableManager get shoppingListCache =>
      $$ShoppingListCacheTableTableManager(_db, _db.shoppingListCache);
  $$UnitCatalogCacheTableTableManager get unitCatalogCache =>
      $$UnitCatalogCacheTableTableManager(_db, _db.unitCatalogCache);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive`: this owns an open SQLite connection, and reopening it per
/// listener would thrash the file. Never invalidated -- the sign-out wipe
/// above is an explicit call, not a provider rebuild, so two connections can
/// never race over the same file.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// `keepAlive`: this owns an open SQLite connection, and reopening it per
/// listener would thrash the file. Never invalidated -- the sign-out wipe
/// above is an explicit call, not a provider rebuild, so two connections can
/// never race over the same file.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// `keepAlive`: this owns an open SQLite connection, and reopening it per
  /// listener would thrash the file. Never invalidated -- the sign-out wipe
  /// above is an explicit call, not a provider rebuild, so two connections can
  /// never race over the same file.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'8c7fb583737b35e44dd8ca0588453404ef77bcc3';
