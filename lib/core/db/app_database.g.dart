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

class $IngredientNameCacheTable extends IngredientNameCache
    with TableInfo<$IngredientNameCacheTable, IngredientNameCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientNameCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDisplayNameMeta = const VerificationMeta(
    'isDisplayName',
  );
  @override
  late final GeneratedColumn<bool> isDisplayName = GeneratedColumn<bool>(
    'is_display_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_display_name" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
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
    ingredientId,
    name,
    locale,
    isDisplayName,
    createdAt,
    updatedAt,
    data,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_name_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientNameCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('is_display_name')) {
      context.handle(
        _isDisplayNameMeta,
        isDisplayName.isAcceptableOrUnknown(
          data['is_display_name']!,
          _isDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isDisplayNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  IngredientNameCacheData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientNameCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      isDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_display_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
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
  $IngredientNameCacheTable createAlias(String alias) {
    return $IngredientNameCacheTable(attachedDatabase, alias);
  }
}

class IngredientNameCacheData extends DataClass
    implements Insertable<IngredientNameCacheData> {
  final String id;
  final String ingredientId;
  final String name;
  final String locale;
  final bool isDisplayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String data;
  const IngredientNameCacheData({
    required this.id,
    required this.ingredientId,
    required this.name,
    required this.locale,
    required this.isDisplayName,
    required this.createdAt,
    required this.updatedAt,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['name'] = Variable<String>(name);
    map['locale'] = Variable<String>(locale);
    map['is_display_name'] = Variable<bool>(isDisplayName);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['data'] = Variable<String>(data);
    return map;
  }

  IngredientNameCacheCompanion toCompanion(bool nullToAbsent) {
    return IngredientNameCacheCompanion(
      id: Value(id),
      ingredientId: Value(ingredientId),
      name: Value(name),
      locale: Value(locale),
      isDisplayName: Value(isDisplayName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      data: Value(data),
    );
  }

  factory IngredientNameCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientNameCacheData(
      id: serializer.fromJson<String>(json['id']),
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      name: serializer.fromJson<String>(json['name']),
      locale: serializer.fromJson<String>(json['locale']),
      isDisplayName: serializer.fromJson<bool>(json['isDisplayName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ingredientId': serializer.toJson<String>(ingredientId),
      'name': serializer.toJson<String>(name),
      'locale': serializer.toJson<String>(locale),
      'isDisplayName': serializer.toJson<bool>(isDisplayName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'data': serializer.toJson<String>(data),
    };
  }

  IngredientNameCacheData copyWith({
    String? id,
    String? ingredientId,
    String? name,
    String? locale,
    bool? isDisplayName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? data,
  }) => IngredientNameCacheData(
    id: id ?? this.id,
    ingredientId: ingredientId ?? this.ingredientId,
    name: name ?? this.name,
    locale: locale ?? this.locale,
    isDisplayName: isDisplayName ?? this.isDisplayName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    data: data ?? this.data,
  );
  IngredientNameCacheData copyWithCompanion(IngredientNameCacheCompanion data) {
    return IngredientNameCacheData(
      id: data.id.present ? data.id.value : this.id,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      name: data.name.present ? data.name.value : this.name,
      locale: data.locale.present ? data.locale.value : this.locale,
      isDisplayName: data.isDisplayName.present
          ? data.isDisplayName.value
          : this.isDisplayName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientNameCacheData(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('name: $name, ')
          ..write('locale: $locale, ')
          ..write('isDisplayName: $isDisplayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ingredientId,
    name,
    locale,
    isDisplayName,
    createdAt,
    updatedAt,
    data,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientNameCacheData &&
          other.id == this.id &&
          other.ingredientId == this.ingredientId &&
          other.name == this.name &&
          other.locale == this.locale &&
          other.isDisplayName == this.isDisplayName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.data == this.data);
}

class IngredientNameCacheCompanion
    extends UpdateCompanion<IngredientNameCacheData> {
  final Value<String> id;
  final Value<String> ingredientId;
  final Value<String> name;
  final Value<String> locale;
  final Value<bool> isDisplayName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> data;
  final Value<int> rowid;
  const IngredientNameCacheCompanion({
    this.id = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.name = const Value.absent(),
    this.locale = const Value.absent(),
    this.isDisplayName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientNameCacheCompanion.insert({
    required String id,
    required String ingredientId,
    required String name,
    required String locale,
    required bool isDisplayName,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String data,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ingredientId = Value(ingredientId),
       name = Value(name),
       locale = Value(locale),
       isDisplayName = Value(isDisplayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       data = Value(data);
  static Insertable<IngredientNameCacheData> custom({
    Expression<String>? id,
    Expression<String>? ingredientId,
    Expression<String>? name,
    Expression<String>? locale,
    Expression<bool>? isDisplayName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (name != null) 'name': name,
      if (locale != null) 'locale': locale,
      if (isDisplayName != null) 'is_display_name': isDisplayName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientNameCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? ingredientId,
    Value<String>? name,
    Value<String>? locale,
    Value<bool>? isDisplayName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return IngredientNameCacheCompanion(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      locale: locale ?? this.locale,
      isDisplayName: isDisplayName ?? this.isDisplayName,
      createdAt: createdAt ?? this.createdAt,
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
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (isDisplayName.present) {
      map['is_display_name'] = Variable<bool>(isDisplayName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('IngredientNameCacheCompanion(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('name: $name, ')
          ..write('locale: $locale, ')
          ..write('isDisplayName: $isDisplayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeCacheTable extends RecipeCache
    with TableInfo<$RecipeCacheTable, RecipeCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeCacheTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleNormalizedMeta = const VerificationMeta(
    'titleNormalized',
  );
  @override
  late final GeneratedColumn<String> titleNormalized = GeneratedColumn<String>(
    'title_normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    titleNormalized,
    updatedAt,
    data,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeCacheData> instance, {
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
    if (data.containsKey('title_normalized')) {
      context.handle(
        _titleNormalizedMeta,
        titleNormalized.isAcceptableOrUnknown(
          data['title_normalized']!,
          _titleNormalizedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_titleNormalizedMeta);
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
  RecipeCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      titleNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_normalized'],
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
  $RecipeCacheTable createAlias(String alias) {
    return $RecipeCacheTable(attachedDatabase, alias);
  }
}

class RecipeCacheData extends DataClass implements Insertable<RecipeCacheData> {
  final String id;
  final String householdId;
  final String titleNormalized;
  final DateTime updatedAt;
  final String data;
  const RecipeCacheData({
    required this.id,
    required this.householdId,
    required this.titleNormalized,
    required this.updatedAt,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['title_normalized'] = Variable<String>(titleNormalized);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['data'] = Variable<String>(data);
    return map;
  }

  RecipeCacheCompanion toCompanion(bool nullToAbsent) {
    return RecipeCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      titleNormalized: Value(titleNormalized),
      updatedAt: Value(updatedAt),
      data: Value(data),
    );
  }

  factory RecipeCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeCacheData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      titleNormalized: serializer.fromJson<String>(json['titleNormalized']),
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
      'titleNormalized': serializer.toJson<String>(titleNormalized),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'data': serializer.toJson<String>(data),
    };
  }

  RecipeCacheData copyWith({
    String? id,
    String? householdId,
    String? titleNormalized,
    DateTime? updatedAt,
    String? data,
  }) => RecipeCacheData(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    titleNormalized: titleNormalized ?? this.titleNormalized,
    updatedAt: updatedAt ?? this.updatedAt,
    data: data ?? this.data,
  );
  RecipeCacheData copyWithCompanion(RecipeCacheCompanion data) {
    return RecipeCacheData(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      titleNormalized: data.titleNormalized.present
          ? data.titleNormalized.value
          : this.titleNormalized,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeCacheData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('titleNormalized: $titleNormalized, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, titleNormalized, updatedAt, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeCacheData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.titleNormalized == this.titleNormalized &&
          other.updatedAt == this.updatedAt &&
          other.data == this.data);
}

class RecipeCacheCompanion extends UpdateCompanion<RecipeCacheData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> titleNormalized;
  final Value<DateTime> updatedAt;
  final Value<String> data;
  final Value<int> rowid;
  const RecipeCacheCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.titleNormalized = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeCacheCompanion.insert({
    required String id,
    required String householdId,
    required String titleNormalized,
    required DateTime updatedAt,
    required String data,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       titleNormalized = Value(titleNormalized),
       updatedAt = Value(updatedAt),
       data = Value(data);
  static Insertable<RecipeCacheData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? titleNormalized,
    Expression<DateTime>? updatedAt,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (titleNormalized != null) 'title_normalized': titleNormalized,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? titleNormalized,
    Value<DateTime>? updatedAt,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return RecipeCacheCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      titleNormalized: titleNormalized ?? this.titleNormalized,
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
    if (titleNormalized.present) {
      map['title_normalized'] = Variable<String>(titleNormalized.value);
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
    return (StringBuffer('RecipeCacheCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('titleNormalized: $titleNormalized, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncWatermarksTable extends SyncWatermarks
    with TableInfo<$SyncWatermarksTable, SyncWatermark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncWatermarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entity, scope, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_watermarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncWatermark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, scope};
  @override
  SyncWatermark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncWatermark(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $SyncWatermarksTable createAlias(String alias) {
    return $SyncWatermarksTable(attachedDatabase, alias);
  }
}

class SyncWatermark extends DataClass implements Insertable<SyncWatermark> {
  final String entity;
  final String scope;
  final DateTime syncedAt;
  const SyncWatermark({
    required this.entity,
    required this.scope,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['scope'] = Variable<String>(scope);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  SyncWatermarksCompanion toCompanion(bool nullToAbsent) {
    return SyncWatermarksCompanion(
      entity: Value(entity),
      scope: Value(scope),
      syncedAt: Value(syncedAt),
    );
  }

  factory SyncWatermark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncWatermark(
      entity: serializer.fromJson<String>(json['entity']),
      scope: serializer.fromJson<String>(json['scope']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'scope': serializer.toJson<String>(scope),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  SyncWatermark copyWith({String? entity, String? scope, DateTime? syncedAt}) =>
      SyncWatermark(
        entity: entity ?? this.entity,
        scope: scope ?? this.scope,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  SyncWatermark copyWithCompanion(SyncWatermarksCompanion data) {
    return SyncWatermark(
      entity: data.entity.present ? data.entity.value : this.entity,
      scope: data.scope.present ? data.scope.value : this.scope,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncWatermark(')
          ..write('entity: $entity, ')
          ..write('scope: $scope, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, scope, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncWatermark &&
          other.entity == this.entity &&
          other.scope == this.scope &&
          other.syncedAt == this.syncedAt);
}

class SyncWatermarksCompanion extends UpdateCompanion<SyncWatermark> {
  final Value<String> entity;
  final Value<String> scope;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const SyncWatermarksCompanion({
    this.entity = const Value.absent(),
    this.scope = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncWatermarksCompanion.insert({
    required String entity,
    required String scope,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       scope = Value(scope),
       syncedAt = Value(syncedAt);
  static Insertable<SyncWatermark> custom({
    Expression<String>? entity,
    Expression<String>? scope,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (scope != null) 'scope': scope,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncWatermarksCompanion copyWith({
    Value<String>? entity,
    Value<String>? scope,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return SyncWatermarksCompanion(
      entity: entity ?? this.entity,
      scope: scope ?? this.scope,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncWatermarksCompanion(')
          ..write('entity: $entity, ')
          ..write('scope: $scope, ')
          ..write('syncedAt: $syncedAt, ')
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
  late final $IngredientNameCacheTable ingredientNameCache =
      $IngredientNameCacheTable(this);
  late final $RecipeCacheTable recipeCache = $RecipeCacheTable(this);
  late final $SyncWatermarksTable syncWatermarks = $SyncWatermarksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    shoppingListCache,
    unitCatalogCache,
    ingredientNameCache,
    recipeCache,
    syncWatermarks,
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
typedef $$IngredientNameCacheTableCreateCompanionBuilder =
    IngredientNameCacheCompanion Function({
      required String id,
      required String ingredientId,
      required String name,
      required String locale,
      required bool isDisplayName,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String data,
      Value<int> rowid,
    });
typedef $$IngredientNameCacheTableUpdateCompanionBuilder =
    IngredientNameCacheCompanion Function({
      Value<String> id,
      Value<String> ingredientId,
      Value<String> name,
      Value<String> locale,
      Value<bool> isDisplayName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> data,
      Value<int> rowid,
    });

class $$IngredientNameCacheTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientNameCacheTable> {
  $$IngredientNameCacheTableFilterComposer({
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

  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDisplayName => $composableBuilder(
    column: $table.isDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$IngredientNameCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientNameCacheTable> {
  $$IngredientNameCacheTableOrderingComposer({
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

  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDisplayName => $composableBuilder(
    column: $table.isDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$IngredientNameCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientNameCacheTable> {
  $$IngredientNameCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<bool> get isDisplayName => $composableBuilder(
    column: $table.isDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$IngredientNameCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientNameCacheTable,
          IngredientNameCacheData,
          $$IngredientNameCacheTableFilterComposer,
          $$IngredientNameCacheTableOrderingComposer,
          $$IngredientNameCacheTableAnnotationComposer,
          $$IngredientNameCacheTableCreateCompanionBuilder,
          $$IngredientNameCacheTableUpdateCompanionBuilder,
          (
            IngredientNameCacheData,
            BaseReferences<
              _$AppDatabase,
              $IngredientNameCacheTable,
              IngredientNameCacheData
            >,
          ),
          IngredientNameCacheData,
          PrefetchHooks Function()
        > {
  $$IngredientNameCacheTableTableManager(
    _$AppDatabase db,
    $IngredientNameCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientNameCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientNameCacheTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IngredientNameCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ingredientId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<bool> isDisplayName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientNameCacheCompanion(
                id: id,
                ingredientId: ingredientId,
                name: name,
                locale: locale,
                isDisplayName: isDisplayName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ingredientId,
                required String name,
                required String locale,
                required bool isDisplayName,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => IngredientNameCacheCompanion.insert(
                id: id,
                ingredientId: ingredientId,
                name: name,
                locale: locale,
                isDisplayName: isDisplayName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $IngredientNameCacheTable,
                    IngredientNameCacheData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $IngredientNameCacheTable,
                    IngredientNameCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngredientNameCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientNameCacheTable,
      IngredientNameCacheData,
      $$IngredientNameCacheTableFilterComposer,
      $$IngredientNameCacheTableOrderingComposer,
      $$IngredientNameCacheTableAnnotationComposer,
      $$IngredientNameCacheTableCreateCompanionBuilder,
      $$IngredientNameCacheTableUpdateCompanionBuilder,
      (
        IngredientNameCacheData,
        BaseReferences<
          _$AppDatabase,
          $IngredientNameCacheTable,
          IngredientNameCacheData
        >,
      ),
      IngredientNameCacheData,
      PrefetchHooks Function()
    >;
typedef $$RecipeCacheTableCreateCompanionBuilder =
    RecipeCacheCompanion Function({
      required String id,
      required String householdId,
      required String titleNormalized,
      required DateTime updatedAt,
      required String data,
      Value<int> rowid,
    });
typedef $$RecipeCacheTableUpdateCompanionBuilder =
    RecipeCacheCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> titleNormalized,
      Value<DateTime> updatedAt,
      Value<String> data,
      Value<int> rowid,
    });

class $$RecipeCacheTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeCacheTable> {
  $$RecipeCacheTableFilterComposer({
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

  ColumnFilters<String> get titleNormalized => $composableBuilder(
    column: $table.titleNormalized,
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

class $$RecipeCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeCacheTable> {
  $$RecipeCacheTableOrderingComposer({
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

  ColumnOrderings<String> get titleNormalized => $composableBuilder(
    column: $table.titleNormalized,
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

class $$RecipeCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeCacheTable> {
  $$RecipeCacheTableAnnotationComposer({
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

  GeneratedColumn<String> get titleNormalized => $composableBuilder(
    column: $table.titleNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$RecipeCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeCacheTable,
          RecipeCacheData,
          $$RecipeCacheTableFilterComposer,
          $$RecipeCacheTableOrderingComposer,
          $$RecipeCacheTableAnnotationComposer,
          $$RecipeCacheTableCreateCompanionBuilder,
          $$RecipeCacheTableUpdateCompanionBuilder,
          (
            RecipeCacheData,
            BaseReferences<_$AppDatabase, $RecipeCacheTable, RecipeCacheData>,
          ),
          RecipeCacheData,
          PrefetchHooks Function()
        > {
  $$RecipeCacheTableTableManager(_$AppDatabase db, $RecipeCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> titleNormalized = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeCacheCompanion(
                id: id,
                householdId: householdId,
                titleNormalized: titleNormalized,
                updatedAt: updatedAt,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String titleNormalized,
                required DateTime updatedAt,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => RecipeCacheCompanion.insert(
                id: id,
                householdId: householdId,
                titleNormalized: titleNormalized,
                updatedAt: updatedAt,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipeCacheTable, RecipeCacheData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecipeCacheTable,
                    RecipeCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeCacheTable,
      RecipeCacheData,
      $$RecipeCacheTableFilterComposer,
      $$RecipeCacheTableOrderingComposer,
      $$RecipeCacheTableAnnotationComposer,
      $$RecipeCacheTableCreateCompanionBuilder,
      $$RecipeCacheTableUpdateCompanionBuilder,
      (
        RecipeCacheData,
        BaseReferences<_$AppDatabase, $RecipeCacheTable, RecipeCacheData>,
      ),
      RecipeCacheData,
      PrefetchHooks Function()
    >;
typedef $$SyncWatermarksTableCreateCompanionBuilder =
    SyncWatermarksCompanion Function({
      required String entity,
      required String scope,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$SyncWatermarksTableUpdateCompanionBuilder =
    SyncWatermarksCompanion Function({
      Value<String> entity,
      Value<String> scope,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$SyncWatermarksTableFilterComposer
    extends Composer<_$AppDatabase, $SyncWatermarksTable> {
  $$SyncWatermarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncWatermarksTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncWatermarksTable> {
  $$SyncWatermarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncWatermarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncWatermarksTable> {
  $$SyncWatermarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SyncWatermarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncWatermarksTable,
          SyncWatermark,
          $$SyncWatermarksTableFilterComposer,
          $$SyncWatermarksTableOrderingComposer,
          $$SyncWatermarksTableAnnotationComposer,
          $$SyncWatermarksTableCreateCompanionBuilder,
          $$SyncWatermarksTableUpdateCompanionBuilder,
          (
            SyncWatermark,
            BaseReferences<_$AppDatabase, $SyncWatermarksTable, SyncWatermark>,
          ),
          SyncWatermark,
          PrefetchHooks Function()
        > {
  $$SyncWatermarksTableTableManager(
    _$AppDatabase db,
    $SyncWatermarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncWatermarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncWatermarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncWatermarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncWatermarksCompanion(
                entity: entity,
                scope: scope,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entity,
                required String scope,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncWatermarksCompanion.insert(
                entity: entity,
                scope: scope,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncWatermarksTable, SyncWatermark>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncWatermarksTable,
                    SyncWatermark
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncWatermarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncWatermarksTable,
      SyncWatermark,
      $$SyncWatermarksTableFilterComposer,
      $$SyncWatermarksTableOrderingComposer,
      $$SyncWatermarksTableAnnotationComposer,
      $$SyncWatermarksTableCreateCompanionBuilder,
      $$SyncWatermarksTableUpdateCompanionBuilder,
      (
        SyncWatermark,
        BaseReferences<_$AppDatabase, $SyncWatermarksTable, SyncWatermark>,
      ),
      SyncWatermark,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ShoppingListCacheTableTableManager get shoppingListCache =>
      $$ShoppingListCacheTableTableManager(_db, _db.shoppingListCache);
  $$UnitCatalogCacheTableTableManager get unitCatalogCache =>
      $$UnitCatalogCacheTableTableManager(_db, _db.unitCatalogCache);
  $$IngredientNameCacheTableTableManager get ingredientNameCache =>
      $$IngredientNameCacheTableTableManager(_db, _db.ingredientNameCache);
  $$RecipeCacheTableTableManager get recipeCache =>
      $$RecipeCacheTableTableManager(_db, _db.recipeCache);
  $$SyncWatermarksTableTableManager get syncWatermarks =>
      $$SyncWatermarksTableTableManager(_db, _db.syncWatermarks);
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
