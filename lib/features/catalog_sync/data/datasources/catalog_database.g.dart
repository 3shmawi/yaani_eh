// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _traitSchemaMeta = const VerificationMeta(
    'traitSchema',
  );
  @override
  late final GeneratedColumn<String> traitSchema = GeneratedColumn<String>(
    'trait_schema',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    slug,
    nameAr,
    nameEn,
    icon,
    traitSchema,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('trait_schema')) {
      context.handle(
        _traitSchemaMeta,
        traitSchema.isAcceptableOrUnknown(
          data['trait_schema']!,
          _traitSchemaMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      traitSchema: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trait_schema'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String? parentId;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String? icon;

  /// JSON list (sections only).
  final String? traitSchema;
  final int sortOrder;
  const CategoryRow({
    required this.id,
    this.parentId,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    this.icon,
    this.traitSchema,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['slug'] = Variable<String>(slug);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || traitSchema != null) {
      map['trait_schema'] = Variable<String>(traitSchema);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      slug: Value(slug),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      traitSchema: traitSchema == null && nullToAbsent
          ? const Value.absent()
          : Value(traitSchema),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      slug: serializer.fromJson<String>(json['slug']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      icon: serializer.fromJson<String?>(json['icon']),
      traitSchema: serializer.fromJson<String?>(json['traitSchema']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'slug': serializer.toJson<String>(slug),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'icon': serializer.toJson<String?>(icon),
      'traitSchema': serializer.toJson<String?>(traitSchema),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryRow copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? slug,
    String? nameAr,
    String? nameEn,
    Value<String?> icon = const Value.absent(),
    Value<String?> traitSchema = const Value.absent(),
    int? sortOrder,
  }) => CategoryRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    slug: slug ?? this.slug,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    icon: icon.present ? icon.value : this.icon,
    traitSchema: traitSchema.present ? traitSchema.value : this.traitSchema,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      slug: data.slug.present ? data.slug.value : this.slug,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      icon: data.icon.present ? data.icon.value : this.icon,
      traitSchema: data.traitSchema.present
          ? data.traitSchema.value
          : this.traitSchema,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('icon: $icon, ')
          ..write('traitSchema: $traitSchema, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    slug,
    nameAr,
    nameEn,
    icon,
    traitSchema,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.slug == this.slug &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.icon == this.icon &&
          other.traitSchema == this.traitSchema &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> slug;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<String?> icon;
  final Value<String?> traitSchema;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.slug = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.icon = const Value.absent(),
    this.traitSchema = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String slug,
    required String nameAr,
    required String nameEn,
    this.icon = const Value.absent(),
    this.traitSchema = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slug = Value(slug),
       nameAr = Value(nameAr),
       nameEn = Value(nameEn);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? slug,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? icon,
    Expression<String>? traitSchema,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (slug != null) 'slug': slug,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (icon != null) 'icon': icon,
      if (traitSchema != null) 'trait_schema': traitSchema,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? slug,
    Value<String>? nameAr,
    Value<String>? nameEn,
    Value<String?>? icon,
    Value<String?>? traitSchema,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      slug: slug ?? this.slug,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      traitSchema: traitSchema ?? this.traitSchema,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (traitSchema.present) {
      map['trait_schema'] = Variable<String>(traitSchema.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('icon: $icon, ')
          ..write('traitSchema: $traitSchema, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _menuNameMeta = const VerificationMeta(
    'menuName',
  );
  @override
  late final GeneratedColumn<String> menuName = GeneratedColumn<String>(
    'menu_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _menuNameArMeta = const VerificationMeta(
    'menuNameAr',
  );
  @override
  late final GeneratedColumn<String> menuNameAr = GeneratedColumn<String>(
    'menu_name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationArMeta = const VerificationMeta(
    'explanationAr',
  );
  @override
  late final GeneratedColumn<String> explanationAr = GeneratedColumn<String>(
    'explanation_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationEnMeta = const VerificationMeta(
    'explanationEn',
  );
  @override
  late final GeneratedColumn<String> explanationEn = GeneratedColumn<String>(
    'explanation_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gistArMeta = const VerificationMeta('gistAr');
  @override
  late final GeneratedColumn<String> gistAr = GeneratedColumn<String>(
    'gist_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gistEnMeta = const VerificationMeta('gistEn');
  @override
  late final GeneratedColumn<String> gistEn = GeneratedColumn<String>(
    'gist_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMlMeta = const VerificationMeta('sizeMl');
  @override
  late final GeneratedColumn<int> sizeMl = GeneratedColumn<int>(
    'size_ml',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMinEgpMeta = const VerificationMeta(
    'priceMinEgp',
  );
  @override
  late final GeneratedColumn<int> priceMinEgp = GeneratedColumn<int>(
    'price_min_egp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMaxEgpMeta = const VerificationMeta(
    'priceMaxEgp',
  );
  @override
  late final GeneratedColumn<int> priceMaxEgp = GeneratedColumn<int>(
    'price_max_egp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceUpdatedAtMeta = const VerificationMeta(
    'priceUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> priceUpdatedAt =
      GeneratedColumn<DateTime>(
        'price_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioBaristaPathMeta = const VerificationMeta(
    'audioBaristaPath',
  );
  @override
  late final GeneratedColumn<String> audioBaristaPath = GeneratedColumn<String>(
    'audio_barista_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioOriginalPathMeta = const VerificationMeta(
    'audioOriginalPath',
  );
  @override
  late final GeneratedColumn<String> audioOriginalPath =
      GeneratedColumn<String>(
        'audio_original_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _traitsMeta = const VerificationMeta('traits');
  @override
  late final GeneratedColumn<String> traits = GeneratedColumn<String>(
    'traits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    slug,
    menuName,
    menuNameAr,
    explanationAr,
    explanationEn,
    gistAr,
    gistEn,
    calories,
    sizeMl,
    priceMinEgp,
    priceMaxEgp,
    priceUpdatedAt,
    imagePath,
    audioBaristaPath,
    audioOriginalPath,
    traits,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('menu_name')) {
      context.handle(
        _menuNameMeta,
        menuName.isAcceptableOrUnknown(data['menu_name']!, _menuNameMeta),
      );
    } else if (isInserting) {
      context.missing(_menuNameMeta);
    }
    if (data.containsKey('menu_name_ar')) {
      context.handle(
        _menuNameArMeta,
        menuNameAr.isAcceptableOrUnknown(
          data['menu_name_ar']!,
          _menuNameArMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_menuNameArMeta);
    }
    if (data.containsKey('explanation_ar')) {
      context.handle(
        _explanationArMeta,
        explanationAr.isAcceptableOrUnknown(
          data['explanation_ar']!,
          _explanationArMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationArMeta);
    }
    if (data.containsKey('explanation_en')) {
      context.handle(
        _explanationEnMeta,
        explanationEn.isAcceptableOrUnknown(
          data['explanation_en']!,
          _explanationEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationEnMeta);
    }
    if (data.containsKey('gist_ar')) {
      context.handle(
        _gistArMeta,
        gistAr.isAcceptableOrUnknown(data['gist_ar']!, _gistArMeta),
      );
    }
    if (data.containsKey('gist_en')) {
      context.handle(
        _gistEnMeta,
        gistEn.isAcceptableOrUnknown(data['gist_en']!, _gistEnMeta),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('size_ml')) {
      context.handle(
        _sizeMlMeta,
        sizeMl.isAcceptableOrUnknown(data['size_ml']!, _sizeMlMeta),
      );
    }
    if (data.containsKey('price_min_egp')) {
      context.handle(
        _priceMinEgpMeta,
        priceMinEgp.isAcceptableOrUnknown(
          data['price_min_egp']!,
          _priceMinEgpMeta,
        ),
      );
    }
    if (data.containsKey('price_max_egp')) {
      context.handle(
        _priceMaxEgpMeta,
        priceMaxEgp.isAcceptableOrUnknown(
          data['price_max_egp']!,
          _priceMaxEgpMeta,
        ),
      );
    }
    if (data.containsKey('price_updated_at')) {
      context.handle(
        _priceUpdatedAtMeta,
        priceUpdatedAt.isAcceptableOrUnknown(
          data['price_updated_at']!,
          _priceUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('audio_barista_path')) {
      context.handle(
        _audioBaristaPathMeta,
        audioBaristaPath.isAcceptableOrUnknown(
          data['audio_barista_path']!,
          _audioBaristaPathMeta,
        ),
      );
    }
    if (data.containsKey('audio_original_path')) {
      context.handle(
        _audioOriginalPathMeta,
        audioOriginalPath.isAcceptableOrUnknown(
          data['audio_original_path']!,
          _audioOriginalPathMeta,
        ),
      );
    }
    if (data.containsKey('traits')) {
      context.handle(
        _traitsMeta,
        traits.isAcceptableOrUnknown(data['traits']!, _traitsMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      menuName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}menu_name'],
      )!,
      menuNameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}menu_name_ar'],
      )!,
      explanationAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_ar'],
      )!,
      explanationEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_en'],
      )!,
      gistAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gist_ar'],
      ),
      gistEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gist_en'],
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      ),
      sizeMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_ml'],
      ),
      priceMinEgp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_min_egp'],
      ),
      priceMaxEgp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_max_egp'],
      ),
      priceUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}price_updated_at'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      audioBaristaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_barista_path'],
      ),
      audioOriginalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_original_path'],
      ),
      traits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}traits'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final String id;
  final String categoryId;
  final String slug;
  final String menuName;
  final String menuNameAr;
  final String explanationAr;
  final String explanationEn;
  final String? gistAr;
  final String? gistEn;
  final int? calories;
  final int? sizeMl;
  final int? priceMinEgp;
  final int? priceMaxEgp;
  final DateTime? priceUpdatedAt;
  final String? imagePath;
  final String? audioBaristaPath;
  final String? audioOriginalPath;

  /// JSON object.
  final String traits;
  final int sortOrder;
  const ItemRow({
    required this.id,
    required this.categoryId,
    required this.slug,
    required this.menuName,
    required this.menuNameAr,
    required this.explanationAr,
    required this.explanationEn,
    this.gistAr,
    this.gistEn,
    this.calories,
    this.sizeMl,
    this.priceMinEgp,
    this.priceMaxEgp,
    this.priceUpdatedAt,
    this.imagePath,
    this.audioBaristaPath,
    this.audioOriginalPath,
    required this.traits,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['slug'] = Variable<String>(slug);
    map['menu_name'] = Variable<String>(menuName);
    map['menu_name_ar'] = Variable<String>(menuNameAr);
    map['explanation_ar'] = Variable<String>(explanationAr);
    map['explanation_en'] = Variable<String>(explanationEn);
    if (!nullToAbsent || gistAr != null) {
      map['gist_ar'] = Variable<String>(gistAr);
    }
    if (!nullToAbsent || gistEn != null) {
      map['gist_en'] = Variable<String>(gistEn);
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    if (!nullToAbsent || sizeMl != null) {
      map['size_ml'] = Variable<int>(sizeMl);
    }
    if (!nullToAbsent || priceMinEgp != null) {
      map['price_min_egp'] = Variable<int>(priceMinEgp);
    }
    if (!nullToAbsent || priceMaxEgp != null) {
      map['price_max_egp'] = Variable<int>(priceMaxEgp);
    }
    if (!nullToAbsent || priceUpdatedAt != null) {
      map['price_updated_at'] = Variable<DateTime>(priceUpdatedAt);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || audioBaristaPath != null) {
      map['audio_barista_path'] = Variable<String>(audioBaristaPath);
    }
    if (!nullToAbsent || audioOriginalPath != null) {
      map['audio_original_path'] = Variable<String>(audioOriginalPath);
    }
    map['traits'] = Variable<String>(traits);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      slug: Value(slug),
      menuName: Value(menuName),
      menuNameAr: Value(menuNameAr),
      explanationAr: Value(explanationAr),
      explanationEn: Value(explanationEn),
      gistAr: gistAr == null && nullToAbsent
          ? const Value.absent()
          : Value(gistAr),
      gistEn: gistEn == null && nullToAbsent
          ? const Value.absent()
          : Value(gistEn),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      sizeMl: sizeMl == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeMl),
      priceMinEgp: priceMinEgp == null && nullToAbsent
          ? const Value.absent()
          : Value(priceMinEgp),
      priceMaxEgp: priceMaxEgp == null && nullToAbsent
          ? const Value.absent()
          : Value(priceMaxEgp),
      priceUpdatedAt: priceUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUpdatedAt),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      audioBaristaPath: audioBaristaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioBaristaPath),
      audioOriginalPath: audioOriginalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioOriginalPath),
      traits: Value(traits),
      sortOrder: Value(sortOrder),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      slug: serializer.fromJson<String>(json['slug']),
      menuName: serializer.fromJson<String>(json['menuName']),
      menuNameAr: serializer.fromJson<String>(json['menuNameAr']),
      explanationAr: serializer.fromJson<String>(json['explanationAr']),
      explanationEn: serializer.fromJson<String>(json['explanationEn']),
      gistAr: serializer.fromJson<String?>(json['gistAr']),
      gistEn: serializer.fromJson<String?>(json['gistEn']),
      calories: serializer.fromJson<int?>(json['calories']),
      sizeMl: serializer.fromJson<int?>(json['sizeMl']),
      priceMinEgp: serializer.fromJson<int?>(json['priceMinEgp']),
      priceMaxEgp: serializer.fromJson<int?>(json['priceMaxEgp']),
      priceUpdatedAt: serializer.fromJson<DateTime?>(json['priceUpdatedAt']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      audioBaristaPath: serializer.fromJson<String?>(json['audioBaristaPath']),
      audioOriginalPath: serializer.fromJson<String?>(
        json['audioOriginalPath'],
      ),
      traits: serializer.fromJson<String>(json['traits']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'slug': serializer.toJson<String>(slug),
      'menuName': serializer.toJson<String>(menuName),
      'menuNameAr': serializer.toJson<String>(menuNameAr),
      'explanationAr': serializer.toJson<String>(explanationAr),
      'explanationEn': serializer.toJson<String>(explanationEn),
      'gistAr': serializer.toJson<String?>(gistAr),
      'gistEn': serializer.toJson<String?>(gistEn),
      'calories': serializer.toJson<int?>(calories),
      'sizeMl': serializer.toJson<int?>(sizeMl),
      'priceMinEgp': serializer.toJson<int?>(priceMinEgp),
      'priceMaxEgp': serializer.toJson<int?>(priceMaxEgp),
      'priceUpdatedAt': serializer.toJson<DateTime?>(priceUpdatedAt),
      'imagePath': serializer.toJson<String?>(imagePath),
      'audioBaristaPath': serializer.toJson<String?>(audioBaristaPath),
      'audioOriginalPath': serializer.toJson<String?>(audioOriginalPath),
      'traits': serializer.toJson<String>(traits),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ItemRow copyWith({
    String? id,
    String? categoryId,
    String? slug,
    String? menuName,
    String? menuNameAr,
    String? explanationAr,
    String? explanationEn,
    Value<String?> gistAr = const Value.absent(),
    Value<String?> gistEn = const Value.absent(),
    Value<int?> calories = const Value.absent(),
    Value<int?> sizeMl = const Value.absent(),
    Value<int?> priceMinEgp = const Value.absent(),
    Value<int?> priceMaxEgp = const Value.absent(),
    Value<DateTime?> priceUpdatedAt = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    Value<String?> audioBaristaPath = const Value.absent(),
    Value<String?> audioOriginalPath = const Value.absent(),
    String? traits,
    int? sortOrder,
  }) => ItemRow(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    slug: slug ?? this.slug,
    menuName: menuName ?? this.menuName,
    menuNameAr: menuNameAr ?? this.menuNameAr,
    explanationAr: explanationAr ?? this.explanationAr,
    explanationEn: explanationEn ?? this.explanationEn,
    gistAr: gistAr.present ? gistAr.value : this.gistAr,
    gistEn: gistEn.present ? gistEn.value : this.gistEn,
    calories: calories.present ? calories.value : this.calories,
    sizeMl: sizeMl.present ? sizeMl.value : this.sizeMl,
    priceMinEgp: priceMinEgp.present ? priceMinEgp.value : this.priceMinEgp,
    priceMaxEgp: priceMaxEgp.present ? priceMaxEgp.value : this.priceMaxEgp,
    priceUpdatedAt: priceUpdatedAt.present
        ? priceUpdatedAt.value
        : this.priceUpdatedAt,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    audioBaristaPath: audioBaristaPath.present
        ? audioBaristaPath.value
        : this.audioBaristaPath,
    audioOriginalPath: audioOriginalPath.present
        ? audioOriginalPath.value
        : this.audioOriginalPath,
    traits: traits ?? this.traits,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      slug: data.slug.present ? data.slug.value : this.slug,
      menuName: data.menuName.present ? data.menuName.value : this.menuName,
      menuNameAr: data.menuNameAr.present
          ? data.menuNameAr.value
          : this.menuNameAr,
      explanationAr: data.explanationAr.present
          ? data.explanationAr.value
          : this.explanationAr,
      explanationEn: data.explanationEn.present
          ? data.explanationEn.value
          : this.explanationEn,
      gistAr: data.gistAr.present ? data.gistAr.value : this.gistAr,
      gistEn: data.gistEn.present ? data.gistEn.value : this.gistEn,
      calories: data.calories.present ? data.calories.value : this.calories,
      sizeMl: data.sizeMl.present ? data.sizeMl.value : this.sizeMl,
      priceMinEgp: data.priceMinEgp.present
          ? data.priceMinEgp.value
          : this.priceMinEgp,
      priceMaxEgp: data.priceMaxEgp.present
          ? data.priceMaxEgp.value
          : this.priceMaxEgp,
      priceUpdatedAt: data.priceUpdatedAt.present
          ? data.priceUpdatedAt.value
          : this.priceUpdatedAt,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      audioBaristaPath: data.audioBaristaPath.present
          ? data.audioBaristaPath.value
          : this.audioBaristaPath,
      audioOriginalPath: data.audioOriginalPath.present
          ? data.audioOriginalPath.value
          : this.audioOriginalPath,
      traits: data.traits.present ? data.traits.value : this.traits,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('slug: $slug, ')
          ..write('menuName: $menuName, ')
          ..write('menuNameAr: $menuNameAr, ')
          ..write('explanationAr: $explanationAr, ')
          ..write('explanationEn: $explanationEn, ')
          ..write('gistAr: $gistAr, ')
          ..write('gistEn: $gistEn, ')
          ..write('calories: $calories, ')
          ..write('sizeMl: $sizeMl, ')
          ..write('priceMinEgp: $priceMinEgp, ')
          ..write('priceMaxEgp: $priceMaxEgp, ')
          ..write('priceUpdatedAt: $priceUpdatedAt, ')
          ..write('imagePath: $imagePath, ')
          ..write('audioBaristaPath: $audioBaristaPath, ')
          ..write('audioOriginalPath: $audioOriginalPath, ')
          ..write('traits: $traits, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    slug,
    menuName,
    menuNameAr,
    explanationAr,
    explanationEn,
    gistAr,
    gistEn,
    calories,
    sizeMl,
    priceMinEgp,
    priceMaxEgp,
    priceUpdatedAt,
    imagePath,
    audioBaristaPath,
    audioOriginalPath,
    traits,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.slug == this.slug &&
          other.menuName == this.menuName &&
          other.menuNameAr == this.menuNameAr &&
          other.explanationAr == this.explanationAr &&
          other.explanationEn == this.explanationEn &&
          other.gistAr == this.gistAr &&
          other.gistEn == this.gistEn &&
          other.calories == this.calories &&
          other.sizeMl == this.sizeMl &&
          other.priceMinEgp == this.priceMinEgp &&
          other.priceMaxEgp == this.priceMaxEgp &&
          other.priceUpdatedAt == this.priceUpdatedAt &&
          other.imagePath == this.imagePath &&
          other.audioBaristaPath == this.audioBaristaPath &&
          other.audioOriginalPath == this.audioOriginalPath &&
          other.traits == this.traits &&
          other.sortOrder == this.sortOrder);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> slug;
  final Value<String> menuName;
  final Value<String> menuNameAr;
  final Value<String> explanationAr;
  final Value<String> explanationEn;
  final Value<String?> gistAr;
  final Value<String?> gistEn;
  final Value<int?> calories;
  final Value<int?> sizeMl;
  final Value<int?> priceMinEgp;
  final Value<int?> priceMaxEgp;
  final Value<DateTime?> priceUpdatedAt;
  final Value<String?> imagePath;
  final Value<String?> audioBaristaPath;
  final Value<String?> audioOriginalPath;
  final Value<String> traits;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.slug = const Value.absent(),
    this.menuName = const Value.absent(),
    this.menuNameAr = const Value.absent(),
    this.explanationAr = const Value.absent(),
    this.explanationEn = const Value.absent(),
    this.gistAr = const Value.absent(),
    this.gistEn = const Value.absent(),
    this.calories = const Value.absent(),
    this.sizeMl = const Value.absent(),
    this.priceMinEgp = const Value.absent(),
    this.priceMaxEgp = const Value.absent(),
    this.priceUpdatedAt = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.audioBaristaPath = const Value.absent(),
    this.audioOriginalPath = const Value.absent(),
    this.traits = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String categoryId,
    required String slug,
    required String menuName,
    required String menuNameAr,
    required String explanationAr,
    required String explanationEn,
    this.gistAr = const Value.absent(),
    this.gistEn = const Value.absent(),
    this.calories = const Value.absent(),
    this.sizeMl = const Value.absent(),
    this.priceMinEgp = const Value.absent(),
    this.priceMaxEgp = const Value.absent(),
    this.priceUpdatedAt = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.audioBaristaPath = const Value.absent(),
    this.audioOriginalPath = const Value.absent(),
    this.traits = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       slug = Value(slug),
       menuName = Value(menuName),
       menuNameAr = Value(menuNameAr),
       explanationAr = Value(explanationAr),
       explanationEn = Value(explanationEn);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? slug,
    Expression<String>? menuName,
    Expression<String>? menuNameAr,
    Expression<String>? explanationAr,
    Expression<String>? explanationEn,
    Expression<String>? gistAr,
    Expression<String>? gistEn,
    Expression<int>? calories,
    Expression<int>? sizeMl,
    Expression<int>? priceMinEgp,
    Expression<int>? priceMaxEgp,
    Expression<DateTime>? priceUpdatedAt,
    Expression<String>? imagePath,
    Expression<String>? audioBaristaPath,
    Expression<String>? audioOriginalPath,
    Expression<String>? traits,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (slug != null) 'slug': slug,
      if (menuName != null) 'menu_name': menuName,
      if (menuNameAr != null) 'menu_name_ar': menuNameAr,
      if (explanationAr != null) 'explanation_ar': explanationAr,
      if (explanationEn != null) 'explanation_en': explanationEn,
      if (gistAr != null) 'gist_ar': gistAr,
      if (gistEn != null) 'gist_en': gistEn,
      if (calories != null) 'calories': calories,
      if (sizeMl != null) 'size_ml': sizeMl,
      if (priceMinEgp != null) 'price_min_egp': priceMinEgp,
      if (priceMaxEgp != null) 'price_max_egp': priceMaxEgp,
      if (priceUpdatedAt != null) 'price_updated_at': priceUpdatedAt,
      if (imagePath != null) 'image_path': imagePath,
      if (audioBaristaPath != null) 'audio_barista_path': audioBaristaPath,
      if (audioOriginalPath != null) 'audio_original_path': audioOriginalPath,
      if (traits != null) 'traits': traits,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String>? slug,
    Value<String>? menuName,
    Value<String>? menuNameAr,
    Value<String>? explanationAr,
    Value<String>? explanationEn,
    Value<String?>? gistAr,
    Value<String?>? gistEn,
    Value<int?>? calories,
    Value<int?>? sizeMl,
    Value<int?>? priceMinEgp,
    Value<int?>? priceMaxEgp,
    Value<DateTime?>? priceUpdatedAt,
    Value<String?>? imagePath,
    Value<String?>? audioBaristaPath,
    Value<String?>? audioOriginalPath,
    Value<String>? traits,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      slug: slug ?? this.slug,
      menuName: menuName ?? this.menuName,
      menuNameAr: menuNameAr ?? this.menuNameAr,
      explanationAr: explanationAr ?? this.explanationAr,
      explanationEn: explanationEn ?? this.explanationEn,
      gistAr: gistAr ?? this.gistAr,
      gistEn: gistEn ?? this.gistEn,
      calories: calories ?? this.calories,
      sizeMl: sizeMl ?? this.sizeMl,
      priceMinEgp: priceMinEgp ?? this.priceMinEgp,
      priceMaxEgp: priceMaxEgp ?? this.priceMaxEgp,
      priceUpdatedAt: priceUpdatedAt ?? this.priceUpdatedAt,
      imagePath: imagePath ?? this.imagePath,
      audioBaristaPath: audioBaristaPath ?? this.audioBaristaPath,
      audioOriginalPath: audioOriginalPath ?? this.audioOriginalPath,
      traits: traits ?? this.traits,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (menuName.present) {
      map['menu_name'] = Variable<String>(menuName.value);
    }
    if (menuNameAr.present) {
      map['menu_name_ar'] = Variable<String>(menuNameAr.value);
    }
    if (explanationAr.present) {
      map['explanation_ar'] = Variable<String>(explanationAr.value);
    }
    if (explanationEn.present) {
      map['explanation_en'] = Variable<String>(explanationEn.value);
    }
    if (gistAr.present) {
      map['gist_ar'] = Variable<String>(gistAr.value);
    }
    if (gistEn.present) {
      map['gist_en'] = Variable<String>(gistEn.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (sizeMl.present) {
      map['size_ml'] = Variable<int>(sizeMl.value);
    }
    if (priceMinEgp.present) {
      map['price_min_egp'] = Variable<int>(priceMinEgp.value);
    }
    if (priceMaxEgp.present) {
      map['price_max_egp'] = Variable<int>(priceMaxEgp.value);
    }
    if (priceUpdatedAt.present) {
      map['price_updated_at'] = Variable<DateTime>(priceUpdatedAt.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (audioBaristaPath.present) {
      map['audio_barista_path'] = Variable<String>(audioBaristaPath.value);
    }
    if (audioOriginalPath.present) {
      map['audio_original_path'] = Variable<String>(audioOriginalPath.value);
    }
    if (traits.present) {
      map['traits'] = Variable<String>(traits.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('slug: $slug, ')
          ..write('menuName: $menuName, ')
          ..write('menuNameAr: $menuNameAr, ')
          ..write('explanationAr: $explanationAr, ')
          ..write('explanationEn: $explanationEn, ')
          ..write('gistAr: $gistAr, ')
          ..write('gistEn: $gistEn, ')
          ..write('calories: $calories, ')
          ..write('sizeMl: $sizeMl, ')
          ..write('priceMinEgp: $priceMinEgp, ')
          ..write('priceMaxEgp: $priceMaxEgp, ')
          ..write('priceUpdatedAt: $priceUpdatedAt, ')
          ..write('imagePath: $imagePath, ')
          ..write('audioBaristaPath: $audioBaristaPath, ')
          ..write('audioOriginalPath: $audioOriginalPath, ')
          ..write('traits: $traits, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemTermsTable extends ItemTerms
    with TableInfo<$ItemTermsTable, ItemTermRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemTermsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, term, lang, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_terms';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemTermRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, term, lang};
  @override
  ItemTermRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemTermRow(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $ItemTermsTable createAlias(String alias) {
    return $ItemTermsTable(attachedDatabase, alias);
  }
}

class ItemTermRow extends DataClass implements Insertable<ItemTermRow> {
  final String itemId;
  final String term;
  final String lang;
  final String kind;
  const ItemTermRow({
    required this.itemId,
    required this.term,
    required this.lang,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['term'] = Variable<String>(term);
    map['lang'] = Variable<String>(lang);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  ItemTermsCompanion toCompanion(bool nullToAbsent) {
    return ItemTermsCompanion(
      itemId: Value(itemId),
      term: Value(term),
      lang: Value(lang),
      kind: Value(kind),
    );
  }

  factory ItemTermRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemTermRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      term: serializer.fromJson<String>(json['term']),
      lang: serializer.fromJson<String>(json['lang']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'term': serializer.toJson<String>(term),
      'lang': serializer.toJson<String>(lang),
      'kind': serializer.toJson<String>(kind),
    };
  }

  ItemTermRow copyWith({
    String? itemId,
    String? term,
    String? lang,
    String? kind,
  }) => ItemTermRow(
    itemId: itemId ?? this.itemId,
    term: term ?? this.term,
    lang: lang ?? this.lang,
    kind: kind ?? this.kind,
  );
  ItemTermRow copyWithCompanion(ItemTermsCompanion data) {
    return ItemTermRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      term: data.term.present ? data.term.value : this.term,
      lang: data.lang.present ? data.lang.value : this.lang,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemTermRow(')
          ..write('itemId: $itemId, ')
          ..write('term: $term, ')
          ..write('lang: $lang, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, term, lang, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemTermRow &&
          other.itemId == this.itemId &&
          other.term == this.term &&
          other.lang == this.lang &&
          other.kind == this.kind);
}

class ItemTermsCompanion extends UpdateCompanion<ItemTermRow> {
  final Value<String> itemId;
  final Value<String> term;
  final Value<String> lang;
  final Value<String> kind;
  final Value<int> rowid;
  const ItemTermsCompanion({
    this.itemId = const Value.absent(),
    this.term = const Value.absent(),
    this.lang = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemTermsCompanion.insert({
    required String itemId,
    required String term,
    required String lang,
    required String kind,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       term = Value(term),
       lang = Value(lang),
       kind = Value(kind);
  static Insertable<ItemTermRow> custom({
    Expression<String>? itemId,
    Expression<String>? term,
    Expression<String>? lang,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (term != null) 'term': term,
      if (lang != null) 'lang': lang,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemTermsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? term,
    Value<String>? lang,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return ItemTermsCompanion(
      itemId: itemId ?? this.itemId,
      term: term ?? this.term,
      lang: lang ?? this.lang,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemTermsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('term: $term, ')
          ..write('lang: $lang, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaRow> instance, {
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
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
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
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final String key;
  final String value;
  const SyncMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
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

  SyncMetaRow copyWith({String? key, String? value}) =>
      SyncMetaRow(key: key ?? this.key, value: value ?? this.value);
  SyncMetaRow copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
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
      (other is SyncMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetaRow> custom({
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

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
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
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CatalogDatabase extends GeneratedDatabase {
  _$CatalogDatabase(QueryExecutor e) : super(e);
  $CatalogDatabaseManager get managers => $CatalogDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ItemTermsTable itemTerms = $ItemTermsTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    items,
    itemTerms,
    syncMeta,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  Value<String?> parentId,
  required String slug,
  required String nameAr,
  required String nameEn,
  Value<String?> icon,
  Value<String?> traitSchema,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> slug,
  Value<String> nameAr,
  Value<String> nameEn,
  Value<String?> icon,
  Value<String?> traitSchema,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$CatalogDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get traitSchema => $composableBuilder(
    column: $table.traitSchema,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$CatalogDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get traitSchema => $composableBuilder(
    column: $table.traitSchema,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get traitSchema => $composableBuilder(
    column: $table.traitSchema,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$CatalogDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$CatalogDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> traitSchema = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                parentId: parentId,
                slug: slug,
                nameAr: nameAr,
                nameEn: nameEn,
                icon: icon,
                traitSchema: traitSchema,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String slug,
                required String nameAr,
                required String nameEn,
                Value<String?> icon = const Value.absent(),
                Value<String?> traitSchema = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                parentId: parentId,
                slug: slug,
                nameAr: nameAr,
                nameEn: nameEn,
                icon: icon,
                traitSchema: traitSchema,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  BaseReferences<
                    _$CatalogDatabase,
                    $CategoriesTable,
                    CategoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$CatalogDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  required String id,
  required String categoryId,
  required String slug,
  required String menuName,
  required String menuNameAr,
  required String explanationAr,
  required String explanationEn,
  Value<String?> gistAr,
  Value<String?> gistEn,
  Value<int?> calories,
  Value<int?> sizeMl,
  Value<int?> priceMinEgp,
  Value<int?> priceMaxEgp,
  Value<DateTime?> priceUpdatedAt,
  Value<String?> imagePath,
  Value<String?> audioBaristaPath,
  Value<String?> audioOriginalPath,
  Value<String> traits,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<String> id,
  Value<String> categoryId,
  Value<String> slug,
  Value<String> menuName,
  Value<String> menuNameAr,
  Value<String> explanationAr,
  Value<String> explanationEn,
  Value<String?> gistAr,
  Value<String?> gistEn,
  Value<int?> calories,
  Value<int?> sizeMl,
  Value<int?> priceMinEgp,
  Value<int?> priceMaxEgp,
  Value<DateTime?> priceUpdatedAt,
  Value<String?> imagePath,
  Value<String?> audioBaristaPath,
  Value<String?> audioOriginalPath,
  Value<String> traits,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$ItemsTableFilterComposer
    extends Composer<_$CatalogDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get menuName => $composableBuilder(
    column: $table.menuName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get menuNameAr => $composableBuilder(
    column: $table.menuNameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationAr => $composableBuilder(
    column: $table.explanationAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationEn => $composableBuilder(
    column: $table.explanationEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gistAr => $composableBuilder(
    column: $table.gistAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gistEn => $composableBuilder(
    column: $table.gistEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeMl => $composableBuilder(
    column: $table.sizeMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceMinEgp => $composableBuilder(
    column: $table.priceMinEgp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceMaxEgp => $composableBuilder(
    column: $table.priceMaxEgp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioBaristaPath => $composableBuilder(
    column: $table.audioBaristaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioOriginalPath => $composableBuilder(
    column: $table.audioOriginalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get traits => $composableBuilder(
    column: $table.traits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemsTableOrderingComposer
    extends Composer<_$CatalogDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get menuName => $composableBuilder(
    column: $table.menuName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get menuNameAr => $composableBuilder(
    column: $table.menuNameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationAr => $composableBuilder(
    column: $table.explanationAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationEn => $composableBuilder(
    column: $table.explanationEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gistAr => $composableBuilder(
    column: $table.gistAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gistEn => $composableBuilder(
    column: $table.gistEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeMl => $composableBuilder(
    column: $table.sizeMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceMinEgp => $composableBuilder(
    column: $table.priceMinEgp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceMaxEgp => $composableBuilder(
    column: $table.priceMaxEgp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioBaristaPath => $composableBuilder(
    column: $table.audioBaristaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioOriginalPath => $composableBuilder(
    column: $table.audioOriginalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get traits => $composableBuilder(
    column: $table.traits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get menuName =>
      $composableBuilder(column: $table.menuName, builder: (column) => column);

  GeneratedColumn<String> get menuNameAr => $composableBuilder(
    column: $table.menuNameAr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationAr => $composableBuilder(
    column: $table.explanationAr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationEn => $composableBuilder(
    column: $table.explanationEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gistAr =>
      $composableBuilder(column: $table.gistAr, builder: (column) => column);

  GeneratedColumn<String> get gistEn =>
      $composableBuilder(column: $table.gistEn, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get sizeMl =>
      $composableBuilder(column: $table.sizeMl, builder: (column) => column);

  GeneratedColumn<int> get priceMinEgp => $composableBuilder(
    column: $table.priceMinEgp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priceMaxEgp => $composableBuilder(
    column: $table.priceMaxEgp,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get audioBaristaPath => $composableBuilder(
    column: $table.audioBaristaPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioOriginalPath => $composableBuilder(
    column: $table.audioOriginalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get traits =>
      $composableBuilder(column: $table.traits, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $ItemsTable,
          ItemRow,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (ItemRow, BaseReferences<_$CatalogDatabase, $ItemsTable, ItemRow>),
          ItemRow,
          PrefetchHooks Function()
        > {
  $$ItemsTableTableManager(_$CatalogDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> menuName = const Value.absent(),
                Value<String> menuNameAr = const Value.absent(),
                Value<String> explanationAr = const Value.absent(),
                Value<String> explanationEn = const Value.absent(),
                Value<String?> gistAr = const Value.absent(),
                Value<String?> gistEn = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<int?> sizeMl = const Value.absent(),
                Value<int?> priceMinEgp = const Value.absent(),
                Value<int?> priceMaxEgp = const Value.absent(),
                Value<DateTime?> priceUpdatedAt = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> audioBaristaPath = const Value.absent(),
                Value<String?> audioOriginalPath = const Value.absent(),
                Value<String> traits = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                categoryId: categoryId,
                slug: slug,
                menuName: menuName,
                menuNameAr: menuNameAr,
                explanationAr: explanationAr,
                explanationEn: explanationEn,
                gistAr: gistAr,
                gistEn: gistEn,
                calories: calories,
                sizeMl: sizeMl,
                priceMinEgp: priceMinEgp,
                priceMaxEgp: priceMaxEgp,
                priceUpdatedAt: priceUpdatedAt,
                imagePath: imagePath,
                audioBaristaPath: audioBaristaPath,
                audioOriginalPath: audioOriginalPath,
                traits: traits,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required String slug,
                required String menuName,
                required String menuNameAr,
                required String explanationAr,
                required String explanationEn,
                Value<String?> gistAr = const Value.absent(),
                Value<String?> gistEn = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<int?> sizeMl = const Value.absent(),
                Value<int?> priceMinEgp = const Value.absent(),
                Value<int?> priceMaxEgp = const Value.absent(),
                Value<DateTime?> priceUpdatedAt = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> audioBaristaPath = const Value.absent(),
                Value<String?> audioOriginalPath = const Value.absent(),
                Value<String> traits = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                categoryId: categoryId,
                slug: slug,
                menuName: menuName,
                menuNameAr: menuNameAr,
                explanationAr: explanationAr,
                explanationEn: explanationEn,
                gistAr: gistAr,
                gistEn: gistEn,
                calories: calories,
                sizeMl: sizeMl,
                priceMinEgp: priceMinEgp,
                priceMaxEgp: priceMaxEgp,
                priceUpdatedAt: priceUpdatedAt,
                imagePath: imagePath,
                audioBaristaPath: audioBaristaPath,
                audioOriginalPath: audioOriginalPath,
                traits: traits,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, ItemRow>(table),
                  BaseReferences<_$CatalogDatabase, $ItemsTable, ItemRow>(
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

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $ItemsTable,
      ItemRow,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (ItemRow, BaseReferences<_$CatalogDatabase, $ItemsTable, ItemRow>),
      ItemRow,
      PrefetchHooks Function()
    >;
typedef $$ItemTermsTableCreateCompanionBuilder = ItemTermsCompanion Function({
  required String itemId,
  required String term,
  required String lang,
  required String kind,
  Value<int> rowid,
});
typedef $$ItemTermsTableUpdateCompanionBuilder = ItemTermsCompanion Function({
  Value<String> itemId,
  Value<String> term,
  Value<String> lang,
  Value<String> kind,
  Value<int> rowid,
});

class $$ItemTermsTableFilterComposer
    extends Composer<_$CatalogDatabase, $ItemTermsTable> {
  $$ItemTermsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemTermsTableOrderingComposer
    extends Composer<_$CatalogDatabase, $ItemTermsTable> {
  $$ItemTermsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemTermsTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $ItemTermsTable> {
  $$ItemTermsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$ItemTermsTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $ItemTermsTable,
          ItemTermRow,
          $$ItemTermsTableFilterComposer,
          $$ItemTermsTableOrderingComposer,
          $$ItemTermsTableAnnotationComposer,
          $$ItemTermsTableCreateCompanionBuilder,
          $$ItemTermsTableUpdateCompanionBuilder,
          (
            ItemTermRow,
            BaseReferences<_$CatalogDatabase, $ItemTermsTable, ItemTermRow>,
          ),
          ItemTermRow,
          PrefetchHooks Function()
        > {
  $$ItemTermsTableTableManager(_$CatalogDatabase db, $ItemTermsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemTermsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemTermsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemTermsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemTermsCompanion(
                itemId: itemId,
                term: term,
                lang: lang,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String term,
                required String lang,
                required String kind,
                Value<int> rowid = const Value.absent(),
              }) => ItemTermsCompanion.insert(
                itemId: itemId,
                term: term,
                lang: lang,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemTermsTable, ItemTermRow>(table),
                  BaseReferences<
                    _$CatalogDatabase,
                    $ItemTermsTable,
                    ItemTermRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemTermsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $ItemTermsTable,
      ItemTermRow,
      $$ItemTermsTableFilterComposer,
      $$ItemTermsTableOrderingComposer,
      $$ItemTermsTableAnnotationComposer,
      $$ItemTermsTableCreateCompanionBuilder,
      $$ItemTermsTableUpdateCompanionBuilder,
      (
        ItemTermRow,
        BaseReferences<_$CatalogDatabase, $ItemTermsTable, ItemTermRow>,
      ),
      ItemTermRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$CatalogDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
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

class $$SyncMetaTableOrderingComposer
    extends Composer<_$CatalogDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
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

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
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

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $SyncMetaTable,
          SyncMetaRow,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaRow,
            BaseReferences<_$CatalogDatabase, $SyncMetaTable, SyncMetaRow>,
          ),
          SyncMetaRow,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$CatalogDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetaTable, SyncMetaRow>(table),
                  BaseReferences<
                    _$CatalogDatabase,
                    $SyncMetaTable,
                    SyncMetaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $SyncMetaTable,
      SyncMetaRow,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaRow,
        BaseReferences<_$CatalogDatabase, $SyncMetaTable, SyncMetaRow>,
      ),
      SyncMetaRow,
      PrefetchHooks Function()
    >;

class $CatalogDatabaseManager {
  final _$CatalogDatabase _db;
  $CatalogDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ItemTermsTableTableManager get itemTerms =>
      $$ItemTermsTableTableManager(_db, _db.itemTerms);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
