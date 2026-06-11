// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorRoleMeta = const VerificationMeta(
    'actorRole',
  );
  @override
  late final GeneratedColumn<int> actorRole = GeneratedColumn<int>(
    'actor_role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actorRole,
    action,
    entityType,
    entityId,
    message,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('actor_role')) {
      context.handle(
        _actorRoleMeta,
        actorRole.isAcceptableOrUnknown(data['actor_role']!, _actorRoleMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actorRole: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actor_role'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      ),
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLog extends DataClass implements Insertable<AuditLog> {
  final String id;
  final int actorRole;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? message;
  final DateTime createdAt;
  const AuditLog({
    required this.id,
    required this.actorRole,
    required this.action,
    this.entityType,
    this.entityId,
    this.message,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['actor_role'] = Variable<int>(actorRole);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      actorRole: Value(actorRole),
      action: Value(action),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLog(
      id: serializer.fromJson<String>(json['id']),
      actorRole: serializer.fromJson<int>(json['actorRole']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      message: serializer.fromJson<String?>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actorRole': serializer.toJson<int>(actorRole),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String?>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'message': serializer.toJson<String?>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLog copyWith({
    String? id,
    int? actorRole,
    String? action,
    Value<String?> entityType = const Value.absent(),
    Value<String?> entityId = const Value.absent(),
    Value<String?> message = const Value.absent(),
    DateTime? createdAt,
  }) => AuditLog(
    id: id ?? this.id,
    actorRole: actorRole ?? this.actorRole,
    action: action ?? this.action,
    entityType: entityType.present ? entityType.value : this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    message: message.present ? message.value : this.message,
    createdAt: createdAt ?? this.createdAt,
  );
  AuditLog copyWithCompanion(AuditLogsCompanion data) {
    return AuditLog(
      id: data.id.present ? data.id.value : this.id,
      actorRole: data.actorRole.present ? data.actorRole.value : this.actorRole,
      action: data.action.present ? data.action.value : this.action,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLog(')
          ..write('id: $id, ')
          ..write('actorRole: $actorRole, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actorRole,
    action,
    entityType,
    entityId,
    message,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLog &&
          other.id == this.id &&
          other.actorRole == this.actorRole &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.message == this.message &&
          other.createdAt == this.createdAt);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLog> {
  final Value<String> id;
  final Value<int> actorRole;
  final Value<String> action;
  final Value<String?> entityType;
  final Value<String?> entityId;
  final Value<String?> message;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.actorRole = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    required String id,
    this.actorRole = const Value.absent(),
    required String action,
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.message = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       action = Value(action),
       createdAt = Value(createdAt);
  static Insertable<AuditLog> custom({
    Expression<String>? id,
    Expression<int>? actorRole,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actorRole != null) 'actor_role': actorRole,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsCompanion copyWith({
    Value<String>? id,
    Value<int>? actorRole,
    Value<String>? action,
    Value<String?>? entityType,
    Value<String?>? entityId,
    Value<String?>? message,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      actorRole: actorRole ?? this.actorRole,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actorRole.present) {
      map['actor_role'] = Variable<int>(actorRole.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('actorRole: $actorRole, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<int> role = GeneratedColumn<int>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _verificationStatusMeta =
      const VerificationMeta('verificationStatus');
  @override
  late final GeneratedColumn<int> verificationStatus = GeneratedColumn<int>(
    'verification_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _verificationRequestedAtMeta =
      const VerificationMeta('verificationRequestedAt');
  @override
  late final GeneratedColumn<DateTime> verificationRequestedAt =
      GeneratedColumn<DateTime>(
        'verification_requested_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _verificationDeadlineAtMeta =
      const VerificationMeta('verificationDeadlineAt');
  @override
  late final GeneratedColumn<DateTime> verificationDeadlineAt =
      GeneratedColumn<DateTime>(
        'verification_deadline_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _verificationTimeoutPolicyMeta =
      const VerificationMeta('verificationTimeoutPolicy');
  @override
  late final GeneratedColumn<int> verificationTimeoutPolicy =
      GeneratedColumn<int>(
        'verification_timeout_policy',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shopNumberMeta = const VerificationMeta(
    'shopNumber',
  );
  @override
  late final GeneratedColumn<String> shopNumber = GeneratedColumn<String>(
    'shop_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _netBalanceMeta = const VerificationMeta(
    'netBalance',
  );
  @override
  late final GeneratedColumn<String> netBalance = GeneratedColumn<String>(
    'net_balance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.0'),
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<String> creditLimit = GeneratedColumn<String>(
    'credit_limit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.0'),
  );
  static const VerificationMeta _loyaltyPointsMeta = const VerificationMeta(
    'loyaltyPoints',
  );
  @override
  late final GeneratedColumn<int> loyaltyPoints = GeneratedColumn<int>(
    'loyalty_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastTransactionDateMeta =
      const VerificationMeta('lastTransactionDate');
  @override
  late final GeneratedColumn<DateTime> lastTransactionDate =
      GeneratedColumn<DateTime>(
        'last_transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _linkedUserUidMeta = const VerificationMeta(
    'linkedUserUid',
  );
  @override
  late final GeneratedColumn<String> linkedUserUid = GeneratedColumn<String>(
    'linked_user_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verificationMethodMeta =
      const VerificationMeta('verificationMethod');
  @override
  late final GeneratedColumn<String> verificationMethod =
      GeneratedColumn<String>(
        'verification_method',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isRetailerMeta = const VerificationMeta(
    'isRetailer',
  );
  @override
  late final GeneratedColumn<bool> isRetailer = GeneratedColumn<bool>(
    'is_retailer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_retailer" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isWholesalerMeta = const VerificationMeta(
    'isWholesaler',
  );
  @override
  late final GeneratedColumn<bool> isWholesaler = GeneratedColumn<bool>(
    'is_wholesaler',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_wholesaler" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isBrokerMeta = const VerificationMeta(
    'isBroker',
  );
  @override
  late final GeneratedColumn<bool> isBroker = GeneratedColumn<bool>(
    'is_broker',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_broker" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSupplierMeta = const VerificationMeta(
    'isSupplier',
  );
  @override
  late final GeneratedColumn<bool> isSupplier = GeneratedColumn<bool>(
    'is_supplier',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_supplier" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isImporterMeta = const VerificationMeta(
    'isImporter',
  );
  @override
  late final GeneratedColumn<bool> isImporter = GeneratedColumn<bool>(
    'is_importer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_importer" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    role,
    verificationStatus,
    verificationRequestedAt,
    verificationDeadlineAt,
    verificationTimeoutPolicy,
    phoneNumber,
    shopNumber,
    netBalance,
    creditLimit,
    loyaltyPoints,
    lastTransactionDate,
    linkedUserUid,
    verificationMethod,
    isRetailer,
    isWholesaler,
    isBroker,
    isSupplier,
    isImporter,
    isDeleted,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('verification_status')) {
      context.handle(
        _verificationStatusMeta,
        verificationStatus.isAcceptableOrUnknown(
          data['verification_status']!,
          _verificationStatusMeta,
        ),
      );
    }
    if (data.containsKey('verification_requested_at')) {
      context.handle(
        _verificationRequestedAtMeta,
        verificationRequestedAt.isAcceptableOrUnknown(
          data['verification_requested_at']!,
          _verificationRequestedAtMeta,
        ),
      );
    }
    if (data.containsKey('verification_deadline_at')) {
      context.handle(
        _verificationDeadlineAtMeta,
        verificationDeadlineAt.isAcceptableOrUnknown(
          data['verification_deadline_at']!,
          _verificationDeadlineAtMeta,
        ),
      );
    }
    if (data.containsKey('verification_timeout_policy')) {
      context.handle(
        _verificationTimeoutPolicyMeta,
        verificationTimeoutPolicy.isAcceptableOrUnknown(
          data['verification_timeout_policy']!,
          _verificationTimeoutPolicyMeta,
        ),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('shop_number')) {
      context.handle(
        _shopNumberMeta,
        shopNumber.isAcceptableOrUnknown(data['shop_number']!, _shopNumberMeta),
      );
    }
    if (data.containsKey('net_balance')) {
      context.handle(
        _netBalanceMeta,
        netBalance.isAcceptableOrUnknown(data['net_balance']!, _netBalanceMeta),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('loyalty_points')) {
      context.handle(
        _loyaltyPointsMeta,
        loyaltyPoints.isAcceptableOrUnknown(
          data['loyalty_points']!,
          _loyaltyPointsMeta,
        ),
      );
    }
    if (data.containsKey('last_transaction_date')) {
      context.handle(
        _lastTransactionDateMeta,
        lastTransactionDate.isAcceptableOrUnknown(
          data['last_transaction_date']!,
          _lastTransactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastTransactionDateMeta);
    }
    if (data.containsKey('linked_user_uid')) {
      context.handle(
        _linkedUserUidMeta,
        linkedUserUid.isAcceptableOrUnknown(
          data['linked_user_uid']!,
          _linkedUserUidMeta,
        ),
      );
    }
    if (data.containsKey('verification_method')) {
      context.handle(
        _verificationMethodMeta,
        verificationMethod.isAcceptableOrUnknown(
          data['verification_method']!,
          _verificationMethodMeta,
        ),
      );
    }
    if (data.containsKey('is_retailer')) {
      context.handle(
        _isRetailerMeta,
        isRetailer.isAcceptableOrUnknown(data['is_retailer']!, _isRetailerMeta),
      );
    }
    if (data.containsKey('is_wholesaler')) {
      context.handle(
        _isWholesalerMeta,
        isWholesaler.isAcceptableOrUnknown(
          data['is_wholesaler']!,
          _isWholesalerMeta,
        ),
      );
    }
    if (data.containsKey('is_broker')) {
      context.handle(
        _isBrokerMeta,
        isBroker.isAcceptableOrUnknown(data['is_broker']!, _isBrokerMeta),
      );
    }
    if (data.containsKey('is_supplier')) {
      context.handle(
        _isSupplierMeta,
        isSupplier.isAcceptableOrUnknown(data['is_supplier']!, _isSupplierMeta),
      );
    }
    if (data.containsKey('is_importer')) {
      context.handle(
        _isImporterMeta,
        isImporter.isAcceptableOrUnknown(data['is_importer']!, _isImporterMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}role'],
      )!,
      verificationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verification_status'],
      )!,
      verificationRequestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verification_requested_at'],
      ),
      verificationDeadlineAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verification_deadline_at'],
      ),
      verificationTimeoutPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verification_timeout_policy'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      shopNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_number'],
      ),
      netBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}net_balance'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_limit'],
      )!,
      loyaltyPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loyalty_points'],
      )!,
      lastTransactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_transaction_date'],
      )!,
      linkedUserUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_user_uid'],
      ),
      verificationMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verification_method'],
      ),
      isRetailer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_retailer'],
      )!,
      isWholesaler: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_wholesaler'],
      )!,
      isBroker: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_broker'],
      )!,
      isSupplier: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_supplier'],
      )!,
      isImporter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_importer'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final String id;
  final String name;
  final int role;
  final int verificationStatus;
  final DateTime? verificationRequestedAt;
  final DateTime? verificationDeadlineAt;
  final int verificationTimeoutPolicy;
  final String? phoneNumber;
  final String? shopNumber;
  final String netBalance;
  final String creditLimit;
  final int loyaltyPoints;
  final DateTime lastTransactionDate;

  /// Stores the Firestore UID if this contact is a real verified user.
  final String? linkedUserUid;

  /// How the contact was verified: 'phone' or 'email'. Null if unverified.
  final String? verificationMethod;
  final bool isRetailer;
  final bool isWholesaler;
  final bool isBroker;
  final bool isSupplier;
  final bool isImporter;
  final bool isDeleted;
  final DateTime? deletedAt;
  const Contact({
    required this.id,
    required this.name,
    required this.role,
    required this.verificationStatus,
    this.verificationRequestedAt,
    this.verificationDeadlineAt,
    required this.verificationTimeoutPolicy,
    this.phoneNumber,
    this.shopNumber,
    required this.netBalance,
    required this.creditLimit,
    required this.loyaltyPoints,
    required this.lastTransactionDate,
    this.linkedUserUid,
    this.verificationMethod,
    required this.isRetailer,
    required this.isWholesaler,
    required this.isBroker,
    required this.isSupplier,
    required this.isImporter,
    required this.isDeleted,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<int>(role);
    map['verification_status'] = Variable<int>(verificationStatus);
    if (!nullToAbsent || verificationRequestedAt != null) {
      map['verification_requested_at'] = Variable<DateTime>(
        verificationRequestedAt,
      );
    }
    if (!nullToAbsent || verificationDeadlineAt != null) {
      map['verification_deadline_at'] = Variable<DateTime>(
        verificationDeadlineAt,
      );
    }
    map['verification_timeout_policy'] = Variable<int>(
      verificationTimeoutPolicy,
    );
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || shopNumber != null) {
      map['shop_number'] = Variable<String>(shopNumber);
    }
    map['net_balance'] = Variable<String>(netBalance);
    map['credit_limit'] = Variable<String>(creditLimit);
    map['loyalty_points'] = Variable<int>(loyaltyPoints);
    map['last_transaction_date'] = Variable<DateTime>(lastTransactionDate);
    if (!nullToAbsent || linkedUserUid != null) {
      map['linked_user_uid'] = Variable<String>(linkedUserUid);
    }
    if (!nullToAbsent || verificationMethod != null) {
      map['verification_method'] = Variable<String>(verificationMethod);
    }
    map['is_retailer'] = Variable<bool>(isRetailer);
    map['is_wholesaler'] = Variable<bool>(isWholesaler);
    map['is_broker'] = Variable<bool>(isBroker);
    map['is_supplier'] = Variable<bool>(isSupplier);
    map['is_importer'] = Variable<bool>(isImporter);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      verificationStatus: Value(verificationStatus),
      verificationRequestedAt: verificationRequestedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verificationRequestedAt),
      verificationDeadlineAt: verificationDeadlineAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verificationDeadlineAt),
      verificationTimeoutPolicy: Value(verificationTimeoutPolicy),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      shopNumber: shopNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(shopNumber),
      netBalance: Value(netBalance),
      creditLimit: Value(creditLimit),
      loyaltyPoints: Value(loyaltyPoints),
      lastTransactionDate: Value(lastTransactionDate),
      linkedUserUid: linkedUserUid == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedUserUid),
      verificationMethod: verificationMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(verificationMethod),
      isRetailer: Value(isRetailer),
      isWholesaler: Value(isWholesaler),
      isBroker: Value(isBroker),
      isSupplier: Value(isSupplier),
      isImporter: Value(isImporter),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<int>(json['role']),
      verificationStatus: serializer.fromJson<int>(json['verificationStatus']),
      verificationRequestedAt: serializer.fromJson<DateTime?>(
        json['verificationRequestedAt'],
      ),
      verificationDeadlineAt: serializer.fromJson<DateTime?>(
        json['verificationDeadlineAt'],
      ),
      verificationTimeoutPolicy: serializer.fromJson<int>(
        json['verificationTimeoutPolicy'],
      ),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      shopNumber: serializer.fromJson<String?>(json['shopNumber']),
      netBalance: serializer.fromJson<String>(json['netBalance']),
      creditLimit: serializer.fromJson<String>(json['creditLimit']),
      loyaltyPoints: serializer.fromJson<int>(json['loyaltyPoints']),
      lastTransactionDate: serializer.fromJson<DateTime>(
        json['lastTransactionDate'],
      ),
      linkedUserUid: serializer.fromJson<String?>(json['linkedUserUid']),
      verificationMethod: serializer.fromJson<String?>(
        json['verificationMethod'],
      ),
      isRetailer: serializer.fromJson<bool>(json['isRetailer']),
      isWholesaler: serializer.fromJson<bool>(json['isWholesaler']),
      isBroker: serializer.fromJson<bool>(json['isBroker']),
      isSupplier: serializer.fromJson<bool>(json['isSupplier']),
      isImporter: serializer.fromJson<bool>(json['isImporter']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<int>(role),
      'verificationStatus': serializer.toJson<int>(verificationStatus),
      'verificationRequestedAt': serializer.toJson<DateTime?>(
        verificationRequestedAt,
      ),
      'verificationDeadlineAt': serializer.toJson<DateTime?>(
        verificationDeadlineAt,
      ),
      'verificationTimeoutPolicy': serializer.toJson<int>(
        verificationTimeoutPolicy,
      ),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'shopNumber': serializer.toJson<String?>(shopNumber),
      'netBalance': serializer.toJson<String>(netBalance),
      'creditLimit': serializer.toJson<String>(creditLimit),
      'loyaltyPoints': serializer.toJson<int>(loyaltyPoints),
      'lastTransactionDate': serializer.toJson<DateTime>(lastTransactionDate),
      'linkedUserUid': serializer.toJson<String?>(linkedUserUid),
      'verificationMethod': serializer.toJson<String?>(verificationMethod),
      'isRetailer': serializer.toJson<bool>(isRetailer),
      'isWholesaler': serializer.toJson<bool>(isWholesaler),
      'isBroker': serializer.toJson<bool>(isBroker),
      'isSupplier': serializer.toJson<bool>(isSupplier),
      'isImporter': serializer.toJson<bool>(isImporter),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    int? role,
    int? verificationStatus,
    Value<DateTime?> verificationRequestedAt = const Value.absent(),
    Value<DateTime?> verificationDeadlineAt = const Value.absent(),
    int? verificationTimeoutPolicy,
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> shopNumber = const Value.absent(),
    String? netBalance,
    String? creditLimit,
    int? loyaltyPoints,
    DateTime? lastTransactionDate,
    Value<String?> linkedUserUid = const Value.absent(),
    Value<String?> verificationMethod = const Value.absent(),
    bool? isRetailer,
    bool? isWholesaler,
    bool? isBroker,
    bool? isSupplier,
    bool? isImporter,
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Contact(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    verificationRequestedAt: verificationRequestedAt.present
        ? verificationRequestedAt.value
        : this.verificationRequestedAt,
    verificationDeadlineAt: verificationDeadlineAt.present
        ? verificationDeadlineAt.value
        : this.verificationDeadlineAt,
    verificationTimeoutPolicy:
        verificationTimeoutPolicy ?? this.verificationTimeoutPolicy,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    shopNumber: shopNumber.present ? shopNumber.value : this.shopNumber,
    netBalance: netBalance ?? this.netBalance,
    creditLimit: creditLimit ?? this.creditLimit,
    loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    linkedUserUid: linkedUserUid.present
        ? linkedUserUid.value
        : this.linkedUserUid,
    verificationMethod: verificationMethod.present
        ? verificationMethod.value
        : this.verificationMethod,
    isRetailer: isRetailer ?? this.isRetailer,
    isWholesaler: isWholesaler ?? this.isWholesaler,
    isBroker: isBroker ?? this.isBroker,
    isSupplier: isSupplier ?? this.isSupplier,
    isImporter: isImporter ?? this.isImporter,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      verificationStatus: data.verificationStatus.present
          ? data.verificationStatus.value
          : this.verificationStatus,
      verificationRequestedAt: data.verificationRequestedAt.present
          ? data.verificationRequestedAt.value
          : this.verificationRequestedAt,
      verificationDeadlineAt: data.verificationDeadlineAt.present
          ? data.verificationDeadlineAt.value
          : this.verificationDeadlineAt,
      verificationTimeoutPolicy: data.verificationTimeoutPolicy.present
          ? data.verificationTimeoutPolicy.value
          : this.verificationTimeoutPolicy,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      shopNumber: data.shopNumber.present
          ? data.shopNumber.value
          : this.shopNumber,
      netBalance: data.netBalance.present
          ? data.netBalance.value
          : this.netBalance,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      loyaltyPoints: data.loyaltyPoints.present
          ? data.loyaltyPoints.value
          : this.loyaltyPoints,
      lastTransactionDate: data.lastTransactionDate.present
          ? data.lastTransactionDate.value
          : this.lastTransactionDate,
      linkedUserUid: data.linkedUserUid.present
          ? data.linkedUserUid.value
          : this.linkedUserUid,
      verificationMethod: data.verificationMethod.present
          ? data.verificationMethod.value
          : this.verificationMethod,
      isRetailer: data.isRetailer.present
          ? data.isRetailer.value
          : this.isRetailer,
      isWholesaler: data.isWholesaler.present
          ? data.isWholesaler.value
          : this.isWholesaler,
      isBroker: data.isBroker.present ? data.isBroker.value : this.isBroker,
      isSupplier: data.isSupplier.present
          ? data.isSupplier.value
          : this.isSupplier,
      isImporter: data.isImporter.present
          ? data.isImporter.value
          : this.isImporter,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('verificationRequestedAt: $verificationRequestedAt, ')
          ..write('verificationDeadlineAt: $verificationDeadlineAt, ')
          ..write('verificationTimeoutPolicy: $verificationTimeoutPolicy, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('shopNumber: $shopNumber, ')
          ..write('netBalance: $netBalance, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('lastTransactionDate: $lastTransactionDate, ')
          ..write('linkedUserUid: $linkedUserUid, ')
          ..write('verificationMethod: $verificationMethod, ')
          ..write('isRetailer: $isRetailer, ')
          ..write('isWholesaler: $isWholesaler, ')
          ..write('isBroker: $isBroker, ')
          ..write('isSupplier: $isSupplier, ')
          ..write('isImporter: $isImporter, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    role,
    verificationStatus,
    verificationRequestedAt,
    verificationDeadlineAt,
    verificationTimeoutPolicy,
    phoneNumber,
    shopNumber,
    netBalance,
    creditLimit,
    loyaltyPoints,
    lastTransactionDate,
    linkedUserUid,
    verificationMethod,
    isRetailer,
    isWholesaler,
    isBroker,
    isSupplier,
    isImporter,
    isDeleted,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.verificationStatus == this.verificationStatus &&
          other.verificationRequestedAt == this.verificationRequestedAt &&
          other.verificationDeadlineAt == this.verificationDeadlineAt &&
          other.verificationTimeoutPolicy == this.verificationTimeoutPolicy &&
          other.phoneNumber == this.phoneNumber &&
          other.shopNumber == this.shopNumber &&
          other.netBalance == this.netBalance &&
          other.creditLimit == this.creditLimit &&
          other.loyaltyPoints == this.loyaltyPoints &&
          other.lastTransactionDate == this.lastTransactionDate &&
          other.linkedUserUid == this.linkedUserUid &&
          other.verificationMethod == this.verificationMethod &&
          other.isRetailer == this.isRetailer &&
          other.isWholesaler == this.isWholesaler &&
          other.isBroker == this.isBroker &&
          other.isSupplier == this.isSupplier &&
          other.isImporter == this.isImporter &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> role;
  final Value<int> verificationStatus;
  final Value<DateTime?> verificationRequestedAt;
  final Value<DateTime?> verificationDeadlineAt;
  final Value<int> verificationTimeoutPolicy;
  final Value<String?> phoneNumber;
  final Value<String?> shopNumber;
  final Value<String> netBalance;
  final Value<String> creditLimit;
  final Value<int> loyaltyPoints;
  final Value<DateTime> lastTransactionDate;
  final Value<String?> linkedUserUid;
  final Value<String?> verificationMethod;
  final Value<bool> isRetailer;
  final Value<bool> isWholesaler;
  final Value<bool> isBroker;
  final Value<bool> isSupplier;
  final Value<bool> isImporter;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.verificationRequestedAt = const Value.absent(),
    this.verificationDeadlineAt = const Value.absent(),
    this.verificationTimeoutPolicy = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.shopNumber = const Value.absent(),
    this.netBalance = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.lastTransactionDate = const Value.absent(),
    this.linkedUserUid = const Value.absent(),
    this.verificationMethod = const Value.absent(),
    this.isRetailer = const Value.absent(),
    this.isWholesaler = const Value.absent(),
    this.isBroker = const Value.absent(),
    this.isSupplier = const Value.absent(),
    this.isImporter = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String id,
    required String name,
    this.role = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.verificationRequestedAt = const Value.absent(),
    this.verificationDeadlineAt = const Value.absent(),
    this.verificationTimeoutPolicy = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.shopNumber = const Value.absent(),
    this.netBalance = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    required DateTime lastTransactionDate,
    this.linkedUserUid = const Value.absent(),
    this.verificationMethod = const Value.absent(),
    this.isRetailer = const Value.absent(),
    this.isWholesaler = const Value.absent(),
    this.isBroker = const Value.absent(),
    this.isSupplier = const Value.absent(),
    this.isImporter = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       lastTransactionDate = Value(lastTransactionDate);
  static Insertable<Contact> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? role,
    Expression<int>? verificationStatus,
    Expression<DateTime>? verificationRequestedAt,
    Expression<DateTime>? verificationDeadlineAt,
    Expression<int>? verificationTimeoutPolicy,
    Expression<String>? phoneNumber,
    Expression<String>? shopNumber,
    Expression<String>? netBalance,
    Expression<String>? creditLimit,
    Expression<int>? loyaltyPoints,
    Expression<DateTime>? lastTransactionDate,
    Expression<String>? linkedUserUid,
    Expression<String>? verificationMethod,
    Expression<bool>? isRetailer,
    Expression<bool>? isWholesaler,
    Expression<bool>? isBroker,
    Expression<bool>? isSupplier,
    Expression<bool>? isImporter,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (verificationStatus != null) 'verification_status': verificationStatus,
      if (verificationRequestedAt != null)
        'verification_requested_at': verificationRequestedAt,
      if (verificationDeadlineAt != null)
        'verification_deadline_at': verificationDeadlineAt,
      if (verificationTimeoutPolicy != null)
        'verification_timeout_policy': verificationTimeoutPolicy,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (shopNumber != null) 'shop_number': shopNumber,
      if (netBalance != null) 'net_balance': netBalance,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (loyaltyPoints != null) 'loyalty_points': loyaltyPoints,
      if (lastTransactionDate != null)
        'last_transaction_date': lastTransactionDate,
      if (linkedUserUid != null) 'linked_user_uid': linkedUserUid,
      if (verificationMethod != null) 'verification_method': verificationMethod,
      if (isRetailer != null) 'is_retailer': isRetailer,
      if (isWholesaler != null) 'is_wholesaler': isWholesaler,
      if (isBroker != null) 'is_broker': isBroker,
      if (isSupplier != null) 'is_supplier': isSupplier,
      if (isImporter != null) 'is_importer': isImporter,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? role,
    Value<int>? verificationStatus,
    Value<DateTime?>? verificationRequestedAt,
    Value<DateTime?>? verificationDeadlineAt,
    Value<int>? verificationTimeoutPolicy,
    Value<String?>? phoneNumber,
    Value<String?>? shopNumber,
    Value<String>? netBalance,
    Value<String>? creditLimit,
    Value<int>? loyaltyPoints,
    Value<DateTime>? lastTransactionDate,
    Value<String?>? linkedUserUid,
    Value<String?>? verificationMethod,
    Value<bool>? isRetailer,
    Value<bool>? isWholesaler,
    Value<bool>? isBroker,
    Value<bool>? isSupplier,
    Value<bool>? isImporter,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationRequestedAt:
          verificationRequestedAt ?? this.verificationRequestedAt,
      verificationDeadlineAt:
          verificationDeadlineAt ?? this.verificationDeadlineAt,
      verificationTimeoutPolicy:
          verificationTimeoutPolicy ?? this.verificationTimeoutPolicy,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shopNumber: shopNumber ?? this.shopNumber,
      netBalance: netBalance ?? this.netBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      linkedUserUid: linkedUserUid ?? this.linkedUserUid,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      isRetailer: isRetailer ?? this.isRetailer,
      isWholesaler: isWholesaler ?? this.isWholesaler,
      isBroker: isBroker ?? this.isBroker,
      isSupplier: isSupplier ?? this.isSupplier,
      isImporter: isImporter ?? this.isImporter,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(role.value);
    }
    if (verificationStatus.present) {
      map['verification_status'] = Variable<int>(verificationStatus.value);
    }
    if (verificationRequestedAt.present) {
      map['verification_requested_at'] = Variable<DateTime>(
        verificationRequestedAt.value,
      );
    }
    if (verificationDeadlineAt.present) {
      map['verification_deadline_at'] = Variable<DateTime>(
        verificationDeadlineAt.value,
      );
    }
    if (verificationTimeoutPolicy.present) {
      map['verification_timeout_policy'] = Variable<int>(
        verificationTimeoutPolicy.value,
      );
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (shopNumber.present) {
      map['shop_number'] = Variable<String>(shopNumber.value);
    }
    if (netBalance.present) {
      map['net_balance'] = Variable<String>(netBalance.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<String>(creditLimit.value);
    }
    if (loyaltyPoints.present) {
      map['loyalty_points'] = Variable<int>(loyaltyPoints.value);
    }
    if (lastTransactionDate.present) {
      map['last_transaction_date'] = Variable<DateTime>(
        lastTransactionDate.value,
      );
    }
    if (linkedUserUid.present) {
      map['linked_user_uid'] = Variable<String>(linkedUserUid.value);
    }
    if (verificationMethod.present) {
      map['verification_method'] = Variable<String>(verificationMethod.value);
    }
    if (isRetailer.present) {
      map['is_retailer'] = Variable<bool>(isRetailer.value);
    }
    if (isWholesaler.present) {
      map['is_wholesaler'] = Variable<bool>(isWholesaler.value);
    }
    if (isBroker.present) {
      map['is_broker'] = Variable<bool>(isBroker.value);
    }
    if (isSupplier.present) {
      map['is_supplier'] = Variable<bool>(isSupplier.value);
    }
    if (isImporter.present) {
      map['is_importer'] = Variable<bool>(isImporter.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
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
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('verificationRequestedAt: $verificationRequestedAt, ')
          ..write('verificationDeadlineAt: $verificationDeadlineAt, ')
          ..write('verificationTimeoutPolicy: $verificationTimeoutPolicy, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('shopNumber: $shopNumber, ')
          ..write('netBalance: $netBalance, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('lastTransactionDate: $lastTransactionDate, ')
          ..write('linkedUserUid: $linkedUserUid, ')
          ..write('verificationMethod: $verificationMethod, ')
          ..write('isRetailer: $isRetailer, ')
          ..write('isWholesaler: $isWholesaler, ')
          ..write('isBroker: $isBroker, ')
          ..write('isSupplier: $isSupplier, ')
          ..write('isImporter: $isImporter, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseCategoriesTable extends ExpenseCategories
    with TableInfo<$ExpenseCategoriesTable, ExpenseCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('FF8A3D'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorHex,
    notes,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExpenseCategoriesTable createAlias(String alias) {
    return $ExpenseCategoriesTable(attachedDatabase, alias);
  }
}

class ExpenseCategory extends DataClass implements Insertable<ExpenseCategory> {
  final String id;
  final String name;
  final String colorHex;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.colorHex,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExpenseCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: Value(colorHex),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExpenseCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? colorHex,
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExpenseCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExpenseCategory copyWithCompanion(ExpenseCategoriesCompanion data) {
    return ExpenseCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, colorHex, notes, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExpenseCategoriesCompanion extends UpdateCompanion<ExpenseCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExpenseCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseCategoriesCompanion.insert({
    required String id,
    required String name,
    this.colorHex = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExpenseCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? colorHex,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExpenseCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expense_categories (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spentAtMeta = const VerificationMeta(
    'spentAt',
  );
  @override
  late final GeneratedColumn<DateTime> spentAt = GeneratedColumn<DateTime>(
    'spent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptPathMeta = const VerificationMeta(
    'receiptPath',
  );
  @override
  late final GeneratedColumn<String> receiptPath = GeneratedColumn<String>(
    'receipt_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurrenceDaysMeta = const VerificationMeta(
    'recurrenceDays',
  );
  @override
  late final GeneratedColumn<int> recurrenceDays = GeneratedColumn<int>(
    'recurrence_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    title,
    vendor,
    amount,
    spentAt,
    paymentMethod,
    description,
    receiptPath,
    isRecurring,
    recurrenceDays,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('spent_at')) {
      context.handle(
        _spentAtMeta,
        spentAt.isAcceptableOrUnknown(data['spent_at']!, _spentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_spentAtMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('receipt_path')) {
      context.handle(
        _receiptPathMeta,
        receiptPath.isAcceptableOrUnknown(
          data['receipt_path']!,
          _receiptPathMeta,
        ),
      );
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_days')) {
      context.handle(
        _recurrenceDaysMeta,
        recurrenceDays.isAcceptableOrUnknown(
          data['recurrence_days']!,
          _recurrenceDaysMeta,
        ),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      )!,
      spentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}spent_at'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      receiptPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_path'],
      ),
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      recurrenceDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_days'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String categoryId;
  final String title;
  final String? vendor;
  final String amount;
  final DateTime spentAt;
  final String paymentMethod;
  final String? description;
  final String? receiptPath;
  final bool isRecurring;
  final int? recurrenceDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Expense({
    required this.id,
    required this.categoryId,
    required this.title,
    this.vendor,
    required this.amount,
    required this.spentAt,
    required this.paymentMethod,
    this.description,
    this.receiptPath,
    required this.isRecurring,
    this.recurrenceDays,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || vendor != null) {
      map['vendor'] = Variable<String>(vendor);
    }
    map['amount'] = Variable<String>(amount);
    map['spent_at'] = Variable<DateTime>(spentAt);
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || receiptPath != null) {
      map['receipt_path'] = Variable<String>(receiptPath);
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || recurrenceDays != null) {
      map['recurrence_days'] = Variable<int>(recurrenceDays);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      title: Value(title),
      vendor: vendor == null && nullToAbsent
          ? const Value.absent()
          : Value(vendor),
      amount: Value(amount),
      spentAt: Value(spentAt),
      paymentMethod: Value(paymentMethod),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      receiptPath: receiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPath),
      isRecurring: Value(isRecurring),
      recurrenceDays: recurrenceDays == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      title: serializer.fromJson<String>(json['title']),
      vendor: serializer.fromJson<String?>(json['vendor']),
      amount: serializer.fromJson<String>(json['amount']),
      spentAt: serializer.fromJson<DateTime>(json['spentAt']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      description: serializer.fromJson<String?>(json['description']),
      receiptPath: serializer.fromJson<String?>(json['receiptPath']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurrenceDays: serializer.fromJson<int?>(json['recurrenceDays']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'title': serializer.toJson<String>(title),
      'vendor': serializer.toJson<String?>(vendor),
      'amount': serializer.toJson<String>(amount),
      'spentAt': serializer.toJson<DateTime>(spentAt),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'description': serializer.toJson<String?>(description),
      'receiptPath': serializer.toJson<String?>(receiptPath),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurrenceDays': serializer.toJson<int?>(recurrenceDays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Expense copyWith({
    String? id,
    String? categoryId,
    String? title,
    Value<String?> vendor = const Value.absent(),
    String? amount,
    DateTime? spentAt,
    String? paymentMethod,
    Value<String?> description = const Value.absent(),
    Value<String?> receiptPath = const Value.absent(),
    bool? isRecurring,
    Value<int?> recurrenceDays = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Expense(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    title: title ?? this.title,
    vendor: vendor.present ? vendor.value : this.vendor,
    amount: amount ?? this.amount,
    spentAt: spentAt ?? this.spentAt,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    description: description.present ? description.value : this.description,
    receiptPath: receiptPath.present ? receiptPath.value : this.receiptPath,
    isRecurring: isRecurring ?? this.isRecurring,
    recurrenceDays: recurrenceDays.present
        ? recurrenceDays.value
        : this.recurrenceDays,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      title: data.title.present ? data.title.value : this.title,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      amount: data.amount.present ? data.amount.value : this.amount,
      spentAt: data.spentAt.present ? data.spentAt.value : this.spentAt,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      description: data.description.present
          ? data.description.value
          : this.description,
      receiptPath: data.receiptPath.present
          ? data.receiptPath.value
          : this.receiptPath,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      recurrenceDays: data.recurrenceDays.present
          ? data.recurrenceDays.value
          : this.recurrenceDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('vendor: $vendor, ')
          ..write('amount: $amount, ')
          ..write('spentAt: $spentAt, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('description: $description, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceDays: $recurrenceDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    title,
    vendor,
    amount,
    spentAt,
    paymentMethod,
    description,
    receiptPath,
    isRecurring,
    recurrenceDays,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.title == this.title &&
          other.vendor == this.vendor &&
          other.amount == this.amount &&
          other.spentAt == this.spentAt &&
          other.paymentMethod == this.paymentMethod &&
          other.description == this.description &&
          other.receiptPath == this.receiptPath &&
          other.isRecurring == this.isRecurring &&
          other.recurrenceDays == this.recurrenceDays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> title;
  final Value<String?> vendor;
  final Value<String> amount;
  final Value<DateTime> spentAt;
  final Value<String> paymentMethod;
  final Value<String?> description;
  final Value<String?> receiptPath;
  final Value<bool> isRecurring;
  final Value<int?> recurrenceDays;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.vendor = const Value.absent(),
    this.amount = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.description = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String categoryId,
    required String title,
    this.vendor = const Value.absent(),
    required String amount,
    required DateTime spentAt,
    this.paymentMethod = const Value.absent(),
    this.description = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceDays = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       title = Value(title),
       amount = Value(amount),
       spentAt = Value(spentAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? title,
    Expression<String>? vendor,
    Expression<String>? amount,
    Expression<DateTime>? spentAt,
    Expression<String>? paymentMethod,
    Expression<String>? description,
    Expression<String>? receiptPath,
    Expression<bool>? isRecurring,
    Expression<int>? recurrenceDays,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (title != null) 'title': title,
      if (vendor != null) 'vendor': vendor,
      if (amount != null) 'amount': amount,
      if (spentAt != null) 'spent_at': spentAt,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (description != null) 'description': description,
      if (receiptPath != null) 'receipt_path': receiptPath,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurrenceDays != null) 'recurrence_days': recurrenceDays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String>? title,
    Value<String?>? vendor,
    Value<String>? amount,
    Value<DateTime>? spentAt,
    Value<String>? paymentMethod,
    Value<String?>? description,
    Value<String?>? receiptPath,
    Value<bool>? isRecurring,
    Value<int?>? recurrenceDays,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      spentAt: spentAt ?? this.spentAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      receiptPath: receiptPath ?? this.receiptPath,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (spentAt.present) {
      map['spent_at'] = Variable<DateTime>(spentAt.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (receiptPath.present) {
      map['receipt_path'] = Variable<String>(receiptPath.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurrenceDays.present) {
      map['recurrence_days'] = Variable<int>(recurrenceDays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('vendor: $vendor, ')
          ..write('amount: $amount, ')
          ..write('spentAt: $spentAt, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('description: $description, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceDays: $recurrenceDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _itemsPerCartonMeta = const VerificationMeta(
    'itemsPerCarton',
  );
  @override
  late final GeneratedColumn<int> itemsPerCarton = GeneratedColumn<int>(
    'items_per_carton',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemNumberMeta = const VerificationMeta(
    'itemNumber',
  );
  @override
  late final GeneratedColumn<String> itemNumber = GeneratedColumn<String>(
    'item_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeFromMeta = const VerificationMeta(
    'sizeFrom',
  );
  @override
  late final GeneratedColumn<int> sizeFrom = GeneratedColumn<int>(
    'size_from',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeToMeta = const VerificationMeta('sizeTo');
  @override
  late final GeneratedColumn<int> sizeTo = GeneratedColumn<int>(
    'size_to',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesSizeMeta = const VerificationMeta(
    'seriesSize',
  );
  @override
  late final GeneratedColumn<int> seriesSize = GeneratedColumn<int>(
    'series_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6),
  );
  static const VerificationMeta _colorDistributionMeta = const VerificationMeta(
    'colorDistribution',
  );
  @override
  late final GeneratedColumn<String> colorDistribution =
      GeneratedColumn<String>(
        'color_distribution',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _containerRefMeta = const VerificationMeta(
    'containerRef',
  );
  @override
  late final GeneratedColumn<String> containerRef = GeneratedColumn<String>(
    'container_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierContactIdMeta = const VerificationMeta(
    'supplierContactId',
  );
  @override
  late final GeneratedColumn<String> supplierContactId =
      GeneratedColumn<String>(
        'supplier_contact_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _businessRoleMeta = const VerificationMeta(
    'businessRole',
  );
  @override
  late final GeneratedColumn<String> businessRole = GeneratedColumn<String>(
    'business_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('retailer'),
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<String> costPrice = GeneratedColumn<String>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.0'),
  );
  static const VerificationMeta _sellingPriceMeta = const VerificationMeta(
    'sellingPrice',
  );
  @override
  late final GeneratedColumn<String> sellingPrice = GeneratedColumn<String>(
    'selling_price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.0'),
  );
  static const VerificationMeta _stockQuantityMeta = const VerificationMeta(
    'stockQuantity',
  );
  @override
  late final GeneratedColumn<int> stockQuantity = GeneratedColumn<int>(
    'stock_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reorderLevelMeta = const VerificationMeta(
    'reorderLevel',
  );
  @override
  late final GeneratedColumn<int> reorderLevel = GeneratedColumn<int>(
    'reorder_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sku,
    barcode,
    category,
    brand,
    photoUrl,
    unit,
    itemsPerCarton,
    itemNumber,
    sizeFrom,
    sizeTo,
    seriesSize,
    colorDistribution,
    containerRef,
    supplierContactId,
    businessRole,
    costPrice,
    sellingPrice,
    stockQuantity,
    reorderLevel,
    isActive,
    createdAt,
    updatedAt,
    isDeleted,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('items_per_carton')) {
      context.handle(
        _itemsPerCartonMeta,
        itemsPerCarton.isAcceptableOrUnknown(
          data['items_per_carton']!,
          _itemsPerCartonMeta,
        ),
      );
    }
    if (data.containsKey('item_number')) {
      context.handle(
        _itemNumberMeta,
        itemNumber.isAcceptableOrUnknown(data['item_number']!, _itemNumberMeta),
      );
    }
    if (data.containsKey('size_from')) {
      context.handle(
        _sizeFromMeta,
        sizeFrom.isAcceptableOrUnknown(data['size_from']!, _sizeFromMeta),
      );
    }
    if (data.containsKey('size_to')) {
      context.handle(
        _sizeToMeta,
        sizeTo.isAcceptableOrUnknown(data['size_to']!, _sizeToMeta),
      );
    }
    if (data.containsKey('series_size')) {
      context.handle(
        _seriesSizeMeta,
        seriesSize.isAcceptableOrUnknown(data['series_size']!, _seriesSizeMeta),
      );
    }
    if (data.containsKey('color_distribution')) {
      context.handle(
        _colorDistributionMeta,
        colorDistribution.isAcceptableOrUnknown(
          data['color_distribution']!,
          _colorDistributionMeta,
        ),
      );
    }
    if (data.containsKey('container_ref')) {
      context.handle(
        _containerRefMeta,
        containerRef.isAcceptableOrUnknown(
          data['container_ref']!,
          _containerRefMeta,
        ),
      );
    }
    if (data.containsKey('supplier_contact_id')) {
      context.handle(
        _supplierContactIdMeta,
        supplierContactId.isAcceptableOrUnknown(
          data['supplier_contact_id']!,
          _supplierContactIdMeta,
        ),
      );
    }
    if (data.containsKey('business_role')) {
      context.handle(
        _businessRoleMeta,
        businessRole.isAcceptableOrUnknown(
          data['business_role']!,
          _businessRoleMeta,
        ),
      );
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('selling_price')) {
      context.handle(
        _sellingPriceMeta,
        sellingPrice.isAcceptableOrUnknown(
          data['selling_price']!,
          _sellingPriceMeta,
        ),
      );
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
        _stockQuantityMeta,
        stockQuantity.isAcceptableOrUnknown(
          data['stock_quantity']!,
          _stockQuantityMeta,
        ),
      );
    }
    if (data.containsKey('reorder_level')) {
      context.handle(
        _reorderLevelMeta,
        reorderLevel.isAcceptableOrUnknown(
          data['reorder_level']!,
          _reorderLevelMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
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
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      itemsPerCarton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items_per_carton'],
      ),
      itemNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_number'],
      ),
      sizeFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_from'],
      ),
      sizeTo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_to'],
      ),
      seriesSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_size'],
      )!,
      colorDistribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_distribution'],
      ),
      containerRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_ref'],
      ),
      supplierContactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_contact_id'],
      ),
      businessRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_role'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_price'],
      )!,
      sellingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selling_price'],
      )!,
      stockQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_quantity'],
      )!,
      reorderLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reorder_level'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? category;
  final String? brand;
  final String? photoUrl;
  final String unit;
  final int? itemsPerCarton;
  final String? itemNumber;
  final int? sizeFrom;
  final int? sizeTo;
  final int seriesSize;
  final String? colorDistribution;
  final String? containerRef;
  final String? supplierContactId;
  final String businessRole;
  final String costPrice;
  final String sellingPrice;
  final int stockQuantity;
  final int reorderLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  const Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.category,
    this.brand,
    this.photoUrl,
    required this.unit,
    this.itemsPerCarton,
    this.itemNumber,
    this.sizeFrom,
    this.sizeTo,
    required this.seriesSize,
    this.colorDistribution,
    this.containerRef,
    this.supplierContactId,
    required this.businessRole,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.reorderLevel,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || itemsPerCarton != null) {
      map['items_per_carton'] = Variable<int>(itemsPerCarton);
    }
    if (!nullToAbsent || itemNumber != null) {
      map['item_number'] = Variable<String>(itemNumber);
    }
    if (!nullToAbsent || sizeFrom != null) {
      map['size_from'] = Variable<int>(sizeFrom);
    }
    if (!nullToAbsent || sizeTo != null) {
      map['size_to'] = Variable<int>(sizeTo);
    }
    map['series_size'] = Variable<int>(seriesSize);
    if (!nullToAbsent || colorDistribution != null) {
      map['color_distribution'] = Variable<String>(colorDistribution);
    }
    if (!nullToAbsent || containerRef != null) {
      map['container_ref'] = Variable<String>(containerRef);
    }
    if (!nullToAbsent || supplierContactId != null) {
      map['supplier_contact_id'] = Variable<String>(supplierContactId);
    }
    map['business_role'] = Variable<String>(businessRole);
    map['cost_price'] = Variable<String>(costPrice);
    map['selling_price'] = Variable<String>(sellingPrice);
    map['stock_quantity'] = Variable<int>(stockQuantity);
    map['reorder_level'] = Variable<int>(reorderLevel);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      unit: Value(unit),
      itemsPerCarton: itemsPerCarton == null && nullToAbsent
          ? const Value.absent()
          : Value(itemsPerCarton),
      itemNumber: itemNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(itemNumber),
      sizeFrom: sizeFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeFrom),
      sizeTo: sizeTo == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeTo),
      seriesSize: Value(seriesSize),
      colorDistribution: colorDistribution == null && nullToAbsent
          ? const Value.absent()
          : Value(colorDistribution),
      containerRef: containerRef == null && nullToAbsent
          ? const Value.absent()
          : Value(containerRef),
      supplierContactId: supplierContactId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierContactId),
      businessRole: Value(businessRole),
      costPrice: Value(costPrice),
      sellingPrice: Value(sellingPrice),
      stockQuantity: Value(stockQuantity),
      reorderLevel: Value(reorderLevel),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      category: serializer.fromJson<String?>(json['category']),
      brand: serializer.fromJson<String?>(json['brand']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      unit: serializer.fromJson<String>(json['unit']),
      itemsPerCarton: serializer.fromJson<int?>(json['itemsPerCarton']),
      itemNumber: serializer.fromJson<String?>(json['itemNumber']),
      sizeFrom: serializer.fromJson<int?>(json['sizeFrom']),
      sizeTo: serializer.fromJson<int?>(json['sizeTo']),
      seriesSize: serializer.fromJson<int>(json['seriesSize']),
      colorDistribution: serializer.fromJson<String?>(
        json['colorDistribution'],
      ),
      containerRef: serializer.fromJson<String?>(json['containerRef']),
      supplierContactId: serializer.fromJson<String?>(
        json['supplierContactId'],
      ),
      businessRole: serializer.fromJson<String>(json['businessRole']),
      costPrice: serializer.fromJson<String>(json['costPrice']),
      sellingPrice: serializer.fromJson<String>(json['sellingPrice']),
      stockQuantity: serializer.fromJson<int>(json['stockQuantity']),
      reorderLevel: serializer.fromJson<int>(json['reorderLevel']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'category': serializer.toJson<String?>(category),
      'brand': serializer.toJson<String?>(brand),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'unit': serializer.toJson<String>(unit),
      'itemsPerCarton': serializer.toJson<int?>(itemsPerCarton),
      'itemNumber': serializer.toJson<String?>(itemNumber),
      'sizeFrom': serializer.toJson<int?>(sizeFrom),
      'sizeTo': serializer.toJson<int?>(sizeTo),
      'seriesSize': serializer.toJson<int>(seriesSize),
      'colorDistribution': serializer.toJson<String?>(colorDistribution),
      'containerRef': serializer.toJson<String?>(containerRef),
      'supplierContactId': serializer.toJson<String?>(supplierContactId),
      'businessRole': serializer.toJson<String>(businessRole),
      'costPrice': serializer.toJson<String>(costPrice),
      'sellingPrice': serializer.toJson<String>(sellingPrice),
      'stockQuantity': serializer.toJson<int>(stockQuantity),
      'reorderLevel': serializer.toJson<int>(reorderLevel),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    Value<String?> sku = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    String? unit,
    Value<int?> itemsPerCarton = const Value.absent(),
    Value<String?> itemNumber = const Value.absent(),
    Value<int?> sizeFrom = const Value.absent(),
    Value<int?> sizeTo = const Value.absent(),
    int? seriesSize,
    Value<String?> colorDistribution = const Value.absent(),
    Value<String?> containerRef = const Value.absent(),
    Value<String?> supplierContactId = const Value.absent(),
    String? businessRole,
    String? costPrice,
    String? sellingPrice,
    int? stockQuantity,
    int? reorderLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    sku: sku.present ? sku.value : this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    category: category.present ? category.value : this.category,
    brand: brand.present ? brand.value : this.brand,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    unit: unit ?? this.unit,
    itemsPerCarton: itemsPerCarton.present
        ? itemsPerCarton.value
        : this.itemsPerCarton,
    itemNumber: itemNumber.present ? itemNumber.value : this.itemNumber,
    sizeFrom: sizeFrom.present ? sizeFrom.value : this.sizeFrom,
    sizeTo: sizeTo.present ? sizeTo.value : this.sizeTo,
    seriesSize: seriesSize ?? this.seriesSize,
    colorDistribution: colorDistribution.present
        ? colorDistribution.value
        : this.colorDistribution,
    containerRef: containerRef.present ? containerRef.value : this.containerRef,
    supplierContactId: supplierContactId.present
        ? supplierContactId.value
        : this.supplierContactId,
    businessRole: businessRole ?? this.businessRole,
    costPrice: costPrice ?? this.costPrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    stockQuantity: stockQuantity ?? this.stockQuantity,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      category: data.category.present ? data.category.value : this.category,
      brand: data.brand.present ? data.brand.value : this.brand,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      unit: data.unit.present ? data.unit.value : this.unit,
      itemsPerCarton: data.itemsPerCarton.present
          ? data.itemsPerCarton.value
          : this.itemsPerCarton,
      itemNumber: data.itemNumber.present
          ? data.itemNumber.value
          : this.itemNumber,
      sizeFrom: data.sizeFrom.present ? data.sizeFrom.value : this.sizeFrom,
      sizeTo: data.sizeTo.present ? data.sizeTo.value : this.sizeTo,
      seriesSize: data.seriesSize.present
          ? data.seriesSize.value
          : this.seriesSize,
      colorDistribution: data.colorDistribution.present
          ? data.colorDistribution.value
          : this.colorDistribution,
      containerRef: data.containerRef.present
          ? data.containerRef.value
          : this.containerRef,
      supplierContactId: data.supplierContactId.present
          ? data.supplierContactId.value
          : this.supplierContactId,
      businessRole: data.businessRole.present
          ? data.businessRole.value
          : this.businessRole,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      reorderLevel: data.reorderLevel.present
          ? data.reorderLevel.value
          : this.reorderLevel,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('unit: $unit, ')
          ..write('itemsPerCarton: $itemsPerCarton, ')
          ..write('itemNumber: $itemNumber, ')
          ..write('sizeFrom: $sizeFrom, ')
          ..write('sizeTo: $sizeTo, ')
          ..write('seriesSize: $seriesSize, ')
          ..write('colorDistribution: $colorDistribution, ')
          ..write('containerRef: $containerRef, ')
          ..write('supplierContactId: $supplierContactId, ')
          ..write('businessRole: $businessRole, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    sku,
    barcode,
    category,
    brand,
    photoUrl,
    unit,
    itemsPerCarton,
    itemNumber,
    sizeFrom,
    sizeTo,
    seriesSize,
    colorDistribution,
    containerRef,
    supplierContactId,
    businessRole,
    costPrice,
    sellingPrice,
    stockQuantity,
    reorderLevel,
    isActive,
    createdAt,
    updatedAt,
    isDeleted,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.category == this.category &&
          other.brand == this.brand &&
          other.photoUrl == this.photoUrl &&
          other.unit == this.unit &&
          other.itemsPerCarton == this.itemsPerCarton &&
          other.itemNumber == this.itemNumber &&
          other.sizeFrom == this.sizeFrom &&
          other.sizeTo == this.sizeTo &&
          other.seriesSize == this.seriesSize &&
          other.colorDistribution == this.colorDistribution &&
          other.containerRef == this.containerRef &&
          other.supplierContactId == this.supplierContactId &&
          other.businessRole == this.businessRole &&
          other.costPrice == this.costPrice &&
          other.sellingPrice == this.sellingPrice &&
          other.stockQuantity == this.stockQuantity &&
          other.reorderLevel == this.reorderLevel &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<String?> category;
  final Value<String?> brand;
  final Value<String?> photoUrl;
  final Value<String> unit;
  final Value<int?> itemsPerCarton;
  final Value<String?> itemNumber;
  final Value<int?> sizeFrom;
  final Value<int?> sizeTo;
  final Value<int> seriesSize;
  final Value<String?> colorDistribution;
  final Value<String?> containerRef;
  final Value<String?> supplierContactId;
  final Value<String> businessRole;
  final Value<String> costPrice;
  final Value<String> sellingPrice;
  final Value<int> stockQuantity;
  final Value<int> reorderLevel;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.category = const Value.absent(),
    this.brand = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.unit = const Value.absent(),
    this.itemsPerCarton = const Value.absent(),
    this.itemNumber = const Value.absent(),
    this.sizeFrom = const Value.absent(),
    this.sizeTo = const Value.absent(),
    this.seriesSize = const Value.absent(),
    this.colorDistribution = const Value.absent(),
    this.containerRef = const Value.absent(),
    this.supplierContactId = const Value.absent(),
    this.businessRole = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.category = const Value.absent(),
    this.brand = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.unit = const Value.absent(),
    this.itemsPerCarton = const Value.absent(),
    this.itemNumber = const Value.absent(),
    this.sizeFrom = const Value.absent(),
    this.sizeTo = const Value.absent(),
    this.seriesSize = const Value.absent(),
    this.colorDistribution = const Value.absent(),
    this.containerRef = const Value.absent(),
    this.supplierContactId = const Value.absent(),
    this.businessRole = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? category,
    Expression<String>? brand,
    Expression<String>? photoUrl,
    Expression<String>? unit,
    Expression<int>? itemsPerCarton,
    Expression<String>? itemNumber,
    Expression<int>? sizeFrom,
    Expression<int>? sizeTo,
    Expression<int>? seriesSize,
    Expression<String>? colorDistribution,
    Expression<String>? containerRef,
    Expression<String>? supplierContactId,
    Expression<String>? businessRole,
    Expression<String>? costPrice,
    Expression<String>? sellingPrice,
    Expression<int>? stockQuantity,
    Expression<int>? reorderLevel,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (category != null) 'category': category,
      if (brand != null) 'brand': brand,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (unit != null) 'unit': unit,
      if (itemsPerCarton != null) 'items_per_carton': itemsPerCarton,
      if (itemNumber != null) 'item_number': itemNumber,
      if (sizeFrom != null) 'size_from': sizeFrom,
      if (sizeTo != null) 'size_to': sizeTo,
      if (seriesSize != null) 'series_size': seriesSize,
      if (colorDistribution != null) 'color_distribution': colorDistribution,
      if (containerRef != null) 'container_ref': containerRef,
      if (supplierContactId != null) 'supplier_contact_id': supplierContactId,
      if (businessRole != null) 'business_role': businessRole,
      if (costPrice != null) 'cost_price': costPrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? sku,
    Value<String?>? barcode,
    Value<String?>? category,
    Value<String?>? brand,
    Value<String?>? photoUrl,
    Value<String>? unit,
    Value<int?>? itemsPerCarton,
    Value<String?>? itemNumber,
    Value<int?>? sizeFrom,
    Value<int?>? sizeTo,
    Value<int>? seriesSize,
    Value<String?>? colorDistribution,
    Value<String?>? containerRef,
    Value<String?>? supplierContactId,
    Value<String>? businessRole,
    Value<String>? costPrice,
    Value<String>? sellingPrice,
    Value<int>? stockQuantity,
    Value<int>? reorderLevel,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      photoUrl: photoUrl ?? this.photoUrl,
      unit: unit ?? this.unit,
      itemsPerCarton: itemsPerCarton ?? this.itemsPerCarton,
      itemNumber: itemNumber ?? this.itemNumber,
      sizeFrom: sizeFrom ?? this.sizeFrom,
      sizeTo: sizeTo ?? this.sizeTo,
      seriesSize: seriesSize ?? this.seriesSize,
      colorDistribution: colorDistribution ?? this.colorDistribution,
      containerRef: containerRef ?? this.containerRef,
      supplierContactId: supplierContactId ?? this.supplierContactId,
      businessRole: businessRole ?? this.businessRole,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (itemsPerCarton.present) {
      map['items_per_carton'] = Variable<int>(itemsPerCarton.value);
    }
    if (itemNumber.present) {
      map['item_number'] = Variable<String>(itemNumber.value);
    }
    if (sizeFrom.present) {
      map['size_from'] = Variable<int>(sizeFrom.value);
    }
    if (sizeTo.present) {
      map['size_to'] = Variable<int>(sizeTo.value);
    }
    if (seriesSize.present) {
      map['series_size'] = Variable<int>(seriesSize.value);
    }
    if (colorDistribution.present) {
      map['color_distribution'] = Variable<String>(colorDistribution.value);
    }
    if (containerRef.present) {
      map['container_ref'] = Variable<String>(containerRef.value);
    }
    if (supplierContactId.present) {
      map['supplier_contact_id'] = Variable<String>(supplierContactId.value);
    }
    if (businessRole.present) {
      map['business_role'] = Variable<String>(businessRole.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<String>(costPrice.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<String>(sellingPrice.value);
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<int>(stockQuantity.value);
    }
    if (reorderLevel.present) {
      map['reorder_level'] = Variable<int>(reorderLevel.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
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
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('unit: $unit, ')
          ..write('itemsPerCarton: $itemsPerCarton, ')
          ..write('itemNumber: $itemNumber, ')
          ..write('sizeFrom: $sizeFrom, ')
          ..write('sizeTo: $sizeTo, ')
          ..write('seriesSize: $seriesSize, ')
          ..write('colorDistribution: $colorDistribution, ')
          ..write('containerRef: $containerRef, ')
          ..write('supplierContactId: $supplierContactId, ')
          ..write('businessRole: $businessRole, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromotionsTable extends Promotions
    with TableInfo<$PromotionsTable, Promotion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromotionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fixed'),
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<String> discountValue = GeneratedColumn<String>(
    'discount_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minOrderTotalMeta = const VerificationMeta(
    'minOrderTotal',
  );
  @override
  late final GeneratedColumn<String> minOrderTotal = GeneratedColumn<String>(
    'min_order_total',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.0'),
  );
  static const VerificationMeta _maxDiscountAmountMeta = const VerificationMeta(
    'maxDiscountAmount',
  );
  @override
  late final GeneratedColumn<String> maxDiscountAmount =
      GeneratedColumn<String>(
        'max_discount_amount',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
    'ends_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _usageLimitMeta = const VerificationMeta(
    'usageLimit',
  );
  @override
  late final GeneratedColumn<int> usageLimit = GeneratedColumn<int>(
    'usage_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usedCountMeta = const VerificationMeta(
    'usedCount',
  );
  @override
  late final GeneratedColumn<int> usedCount = GeneratedColumn<int>(
    'used_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    title,
    description,
    discountType,
    discountValue,
    minOrderTotal,
    maxDiscountAmount,
    startsAt,
    endsAt,
    isActive,
    usageLimit,
    usedCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promotions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Promotion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountValueMeta);
    }
    if (data.containsKey('min_order_total')) {
      context.handle(
        _minOrderTotalMeta,
        minOrderTotal.isAcceptableOrUnknown(
          data['min_order_total']!,
          _minOrderTotalMeta,
        ),
      );
    }
    if (data.containsKey('max_discount_amount')) {
      context.handle(
        _maxDiscountAmountMeta,
        maxDiscountAmount.isAcceptableOrUnknown(
          data['max_discount_amount']!,
          _maxDiscountAmountMeta,
        ),
      );
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('usage_limit')) {
      context.handle(
        _usageLimitMeta,
        usageLimit.isAcceptableOrUnknown(data['usage_limit']!, _usageLimitMeta),
      );
    }
    if (data.containsKey('used_count')) {
      context.handle(
        _usedCountMeta,
        usedCount.isAcceptableOrUnknown(data['used_count']!, _usedCountMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Promotion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Promotion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_value'],
      )!,
      minOrderTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}min_order_total'],
      )!,
      maxDiscountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}max_discount_amount'],
      ),
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      ),
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_at'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      usageLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_limit'],
      ),
      usedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PromotionsTable createAlias(String alias) {
    return $PromotionsTable(attachedDatabase, alias);
  }
}

class Promotion extends DataClass implements Insertable<Promotion> {
  final String id;
  final String code;
  final String title;
  final String? description;
  final String discountType;
  final String discountValue;
  final String minOrderTotal;
  final String? maxDiscountAmount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final int? usageLimit;
  final int usedCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Promotion({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderTotal,
    this.maxDiscountAmount,
    this.startsAt,
    this.endsAt,
    required this.isActive,
    this.usageLimit,
    required this.usedCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['discount_type'] = Variable<String>(discountType);
    map['discount_value'] = Variable<String>(discountValue);
    map['min_order_total'] = Variable<String>(minOrderTotal);
    if (!nullToAbsent || maxDiscountAmount != null) {
      map['max_discount_amount'] = Variable<String>(maxDiscountAmount);
    }
    if (!nullToAbsent || startsAt != null) {
      map['starts_at'] = Variable<DateTime>(startsAt);
    }
    if (!nullToAbsent || endsAt != null) {
      map['ends_at'] = Variable<DateTime>(endsAt);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || usageLimit != null) {
      map['usage_limit'] = Variable<int>(usageLimit);
    }
    map['used_count'] = Variable<int>(usedCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PromotionsCompanion toCompanion(bool nullToAbsent) {
    return PromotionsCompanion(
      id: Value(id),
      code: Value(code),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      discountType: Value(discountType),
      discountValue: Value(discountValue),
      minOrderTotal: Value(minOrderTotal),
      maxDiscountAmount: maxDiscountAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(maxDiscountAmount),
      startsAt: startsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startsAt),
      endsAt: endsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endsAt),
      isActive: Value(isActive),
      usageLimit: usageLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(usageLimit),
      usedCount: Value(usedCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Promotion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Promotion(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      discountType: serializer.fromJson<String>(json['discountType']),
      discountValue: serializer.fromJson<String>(json['discountValue']),
      minOrderTotal: serializer.fromJson<String>(json['minOrderTotal']),
      maxDiscountAmount: serializer.fromJson<String?>(
        json['maxDiscountAmount'],
      ),
      startsAt: serializer.fromJson<DateTime?>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime?>(json['endsAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      usageLimit: serializer.fromJson<int?>(json['usageLimit']),
      usedCount: serializer.fromJson<int>(json['usedCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'discountType': serializer.toJson<String>(discountType),
      'discountValue': serializer.toJson<String>(discountValue),
      'minOrderTotal': serializer.toJson<String>(minOrderTotal),
      'maxDiscountAmount': serializer.toJson<String?>(maxDiscountAmount),
      'startsAt': serializer.toJson<DateTime?>(startsAt),
      'endsAt': serializer.toJson<DateTime?>(endsAt),
      'isActive': serializer.toJson<bool>(isActive),
      'usageLimit': serializer.toJson<int?>(usageLimit),
      'usedCount': serializer.toJson<int>(usedCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Promotion copyWith({
    String? id,
    String? code,
    String? title,
    Value<String?> description = const Value.absent(),
    String? discountType,
    String? discountValue,
    String? minOrderTotal,
    Value<String?> maxDiscountAmount = const Value.absent(),
    Value<DateTime?> startsAt = const Value.absent(),
    Value<DateTime?> endsAt = const Value.absent(),
    bool? isActive,
    Value<int?> usageLimit = const Value.absent(),
    int? usedCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Promotion(
    id: id ?? this.id,
    code: code ?? this.code,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    discountType: discountType ?? this.discountType,
    discountValue: discountValue ?? this.discountValue,
    minOrderTotal: minOrderTotal ?? this.minOrderTotal,
    maxDiscountAmount: maxDiscountAmount.present
        ? maxDiscountAmount.value
        : this.maxDiscountAmount,
    startsAt: startsAt.present ? startsAt.value : this.startsAt,
    endsAt: endsAt.present ? endsAt.value : this.endsAt,
    isActive: isActive ?? this.isActive,
    usageLimit: usageLimit.present ? usageLimit.value : this.usageLimit,
    usedCount: usedCount ?? this.usedCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Promotion copyWithCompanion(PromotionsCompanion data) {
    return Promotion(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      minOrderTotal: data.minOrderTotal.present
          ? data.minOrderTotal.value
          : this.minOrderTotal,
      maxDiscountAmount: data.maxDiscountAmount.present
          ? data.maxDiscountAmount.value
          : this.maxDiscountAmount,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      usageLimit: data.usageLimit.present
          ? data.usageLimit.value
          : this.usageLimit,
      usedCount: data.usedCount.present ? data.usedCount.value : this.usedCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Promotion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('minOrderTotal: $minOrderTotal, ')
          ..write('maxDiscountAmount: $maxDiscountAmount, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('isActive: $isActive, ')
          ..write('usageLimit: $usageLimit, ')
          ..write('usedCount: $usedCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    title,
    description,
    discountType,
    discountValue,
    minOrderTotal,
    maxDiscountAmount,
    startsAt,
    endsAt,
    isActive,
    usageLimit,
    usedCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Promotion &&
          other.id == this.id &&
          other.code == this.code &&
          other.title == this.title &&
          other.description == this.description &&
          other.discountType == this.discountType &&
          other.discountValue == this.discountValue &&
          other.minOrderTotal == this.minOrderTotal &&
          other.maxDiscountAmount == this.maxDiscountAmount &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.isActive == this.isActive &&
          other.usageLimit == this.usageLimit &&
          other.usedCount == this.usedCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PromotionsCompanion extends UpdateCompanion<Promotion> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> discountType;
  final Value<String> discountValue;
  final Value<String> minOrderTotal;
  final Value<String?> maxDiscountAmount;
  final Value<DateTime?> startsAt;
  final Value<DateTime?> endsAt;
  final Value<bool> isActive;
  final Value<int?> usageLimit;
  final Value<int> usedCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PromotionsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.minOrderTotal = const Value.absent(),
    this.maxDiscountAmount = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.usageLimit = const Value.absent(),
    this.usedCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromotionsCompanion.insert({
    required String id,
    required String code,
    required String title,
    this.description = const Value.absent(),
    this.discountType = const Value.absent(),
    required String discountValue,
    this.minOrderTotal = const Value.absent(),
    this.maxDiscountAmount = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.usageLimit = const Value.absent(),
    this.usedCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       title = Value(title),
       discountValue = Value(discountValue),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Promotion> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? discountType,
    Expression<String>? discountValue,
    Expression<String>? minOrderTotal,
    Expression<String>? maxDiscountAmount,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<bool>? isActive,
    Expression<int>? usageLimit,
    Expression<int>? usedCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (minOrderTotal != null) 'min_order_total': minOrderTotal,
      if (maxDiscountAmount != null) 'max_discount_amount': maxDiscountAmount,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (isActive != null) 'is_active': isActive,
      if (usageLimit != null) 'usage_limit': usageLimit,
      if (usedCount != null) 'used_count': usedCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromotionsCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? discountType,
    Value<String>? discountValue,
    Value<String>? minOrderTotal,
    Value<String?>? maxDiscountAmount,
    Value<DateTime?>? startsAt,
    Value<DateTime?>? endsAt,
    Value<bool>? isActive,
    Value<int?>? usageLimit,
    Value<int>? usedCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PromotionsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderTotal: minOrderTotal ?? this.minOrderTotal,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      isActive: isActive ?? this.isActive,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<String>(discountValue.value);
    }
    if (minOrderTotal.present) {
      map['min_order_total'] = Variable<String>(minOrderTotal.value);
    }
    if (maxDiscountAmount.present) {
      map['max_discount_amount'] = Variable<String>(maxDiscountAmount.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (usageLimit.present) {
      map['usage_limit'] = Variable<int>(usageLimit.value);
    }
    if (usedCount.present) {
      map['used_count'] = Variable<int>(usedCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromotionsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('minOrderTotal: $minOrderTotal, ')
          ..write('maxDiscountAmount: $maxDiscountAmount, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('isActive: $isActive, ')
          ..write('usageLimit: $usageLimit, ')
          ..write('usedCount: $usedCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<String> subtotal = GeneratedColumn<String>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<String> discount = GeneratedColumn<String>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.0'),
  );
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<String> tax = GeneratedColumn<String>(
    'tax',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.0'),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<String> total = GeneratedColumn<String>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<String> paidAmount = GeneratedColumn<String>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.0'),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerName,
    contactId,
    subtotal,
    discount,
    tax,
    total,
    paidAmount,
    paymentMethod,
    status,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    }
    if (data.containsKey('tax')) {
      context.handle(
        _taxMeta,
        tax.isAcceptableOrUnknown(data['tax']!, _taxMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtotal'],
      )!,
      discount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount'],
      )!,
      tax: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}total'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_amount'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final String id;
  final String? customerName;
  final String? contactId;
  final String subtotal;
  final String discount;
  final String tax;
  final String total;
  final String paidAmount;
  final String paymentMethod;
  final String status;
  final String? note;
  final DateTime createdAt;
  const Sale({
    required this.id,
    this.customerName,
    this.contactId,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paidAmount,
    required this.paymentMethod,
    required this.status,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    map['subtotal'] = Variable<String>(subtotal);
    map['discount'] = Variable<String>(discount);
    map['tax'] = Variable<String>(tax);
    map['total'] = Variable<String>(total);
    map['paid_amount'] = Variable<String>(paidAmount);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      subtotal: Value(subtotal),
      discount: Value(discount),
      tax: Value(tax),
      total: Value(total),
      paidAmount: Value(paidAmount),
      paymentMethod: Value(paymentMethod),
      status: Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<String>(json['id']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      contactId: serializer.fromJson<String?>(json['contactId']),
      subtotal: serializer.fromJson<String>(json['subtotal']),
      discount: serializer.fromJson<String>(json['discount']),
      tax: serializer.fromJson<String>(json['tax']),
      total: serializer.fromJson<String>(json['total']),
      paidAmount: serializer.fromJson<String>(json['paidAmount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerName': serializer.toJson<String?>(customerName),
      'contactId': serializer.toJson<String?>(contactId),
      'subtotal': serializer.toJson<String>(subtotal),
      'discount': serializer.toJson<String>(discount),
      'tax': serializer.toJson<String>(tax),
      'total': serializer.toJson<String>(total),
      'paidAmount': serializer.toJson<String>(paidAmount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Sale copyWith({
    String? id,
    Value<String?> customerName = const Value.absent(),
    Value<String?> contactId = const Value.absent(),
    String? subtotal,
    String? discount,
    String? tax,
    String? total,
    String? paidAmount,
    String? paymentMethod,
    String? status,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => Sale(
    id: id ?? this.id,
    customerName: customerName.present ? customerName.value : this.customerName,
    contactId: contactId.present ? contactId.value : this.contactId,
    subtotal: subtotal ?? this.subtotal,
    discount: discount ?? this.discount,
    tax: tax ?? this.tax,
    total: total ?? this.total,
    paidAmount: paidAmount ?? this.paidAmount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    status: status ?? this.status,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discount: data.discount.present ? data.discount.value : this.discount,
      tax: data.tax.present ? data.tax.value : this.tax,
      total: data.total.present ? data.total.value : this.total,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('customerName: $customerName, ')
          ..write('contactId: $contactId, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerName,
    contactId,
    subtotal,
    discount,
    tax,
    total,
    paidAmount,
    paymentMethod,
    status,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.customerName == this.customerName &&
          other.contactId == this.contactId &&
          other.subtotal == this.subtotal &&
          other.discount == this.discount &&
          other.tax == this.tax &&
          other.total == this.total &&
          other.paidAmount == this.paidAmount &&
          other.paymentMethod == this.paymentMethod &&
          other.status == this.status &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<String> id;
  final Value<String?> customerName;
  final Value<String?> contactId;
  final Value<String> subtotal;
  final Value<String> discount;
  final Value<String> tax;
  final Value<String> total;
  final Value<String> paidAmount;
  final Value<String> paymentMethod;
  final Value<String> status;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.customerName = const Value.absent(),
    this.contactId = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.tax = const Value.absent(),
    this.total = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesCompanion.insert({
    required String id,
    this.customerName = const Value.absent(),
    this.contactId = const Value.absent(),
    required String subtotal,
    this.discount = const Value.absent(),
    this.tax = const Value.absent(),
    required String total,
    this.paidAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subtotal = Value(subtotal),
       total = Value(total),
       createdAt = Value(createdAt);
  static Insertable<Sale> custom({
    Expression<String>? id,
    Expression<String>? customerName,
    Expression<String>? contactId,
    Expression<String>? subtotal,
    Expression<String>? discount,
    Expression<String>? tax,
    Expression<String>? total,
    Expression<String>? paidAmount,
    Expression<String>? paymentMethod,
    Expression<String>? status,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerName != null) 'customer_name': customerName,
      if (contactId != null) 'contact_id': contactId,
      if (subtotal != null) 'subtotal': subtotal,
      if (discount != null) 'discount': discount,
      if (tax != null) 'tax': tax,
      if (total != null) 'total': total,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesCompanion copyWith({
    Value<String>? id,
    Value<String?>? customerName,
    Value<String?>? contactId,
    Value<String>? subtotal,
    Value<String>? discount,
    Value<String>? tax,
    Value<String>? total,
    Value<String>? paidAmount,
    Value<String>? paymentMethod,
    Value<String>? status,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SalesCompanion(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      contactId: contactId ?? this.contactId,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<String>(subtotal.value);
    }
    if (discount.present) {
      map['discount'] = Variable<String>(discount.value);
    }
    if (tax.present) {
      map['tax'] = Variable<String>(tax.value);
    }
    if (total.present) {
      map['total'] = Variable<String>(total.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<String>(paidAmount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('customerName: $customerName, ')
          ..write('contactId: $contactId, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromotionRedemptionsTable extends PromotionRedemptions
    with TableInfo<$PromotionRedemptionsTable, PromotionRedemption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromotionRedemptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promotionIdMeta = const VerificationMeta(
    'promotionId',
  );
  @override
  late final GeneratedColumn<String> promotionId = GeneratedColumn<String>(
    'promotion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES promotions (id)',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _codeSnapshotMeta = const VerificationMeta(
    'codeSnapshot',
  );
  @override
  late final GeneratedColumn<String> codeSnapshot = GeneratedColumn<String>(
    'code_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAppliedMeta = const VerificationMeta(
    'discountApplied',
  );
  @override
  late final GeneratedColumn<String> discountApplied = GeneratedColumn<String>(
    'discount_applied',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<String> subtotal = GeneratedColumn<String>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    promotionId,
    saleId,
    codeSnapshot,
    discountApplied,
    subtotal,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promotion_redemptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromotionRedemption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('promotion_id')) {
      context.handle(
        _promotionIdMeta,
        promotionId.isAcceptableOrUnknown(
          data['promotion_id']!,
          _promotionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_promotionIdMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('code_snapshot')) {
      context.handle(
        _codeSnapshotMeta,
        codeSnapshot.isAcceptableOrUnknown(
          data['code_snapshot']!,
          _codeSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codeSnapshotMeta);
    }
    if (data.containsKey('discount_applied')) {
      context.handle(
        _discountAppliedMeta,
        discountApplied.isAcceptableOrUnknown(
          data['discount_applied']!,
          _discountAppliedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountAppliedMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromotionRedemption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromotionRedemption(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      promotionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promotion_id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      codeSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_snapshot'],
      )!,
      discountApplied: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_applied'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtotal'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PromotionRedemptionsTable createAlias(String alias) {
    return $PromotionRedemptionsTable(attachedDatabase, alias);
  }
}

class PromotionRedemption extends DataClass
    implements Insertable<PromotionRedemption> {
  final String id;
  final String promotionId;
  final String saleId;
  final String codeSnapshot;
  final String discountApplied;
  final String subtotal;
  final DateTime createdAt;
  const PromotionRedemption({
    required this.id,
    required this.promotionId,
    required this.saleId,
    required this.codeSnapshot,
    required this.discountApplied,
    required this.subtotal,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['promotion_id'] = Variable<String>(promotionId);
    map['sale_id'] = Variable<String>(saleId);
    map['code_snapshot'] = Variable<String>(codeSnapshot);
    map['discount_applied'] = Variable<String>(discountApplied);
    map['subtotal'] = Variable<String>(subtotal);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PromotionRedemptionsCompanion toCompanion(bool nullToAbsent) {
    return PromotionRedemptionsCompanion(
      id: Value(id),
      promotionId: Value(promotionId),
      saleId: Value(saleId),
      codeSnapshot: Value(codeSnapshot),
      discountApplied: Value(discountApplied),
      subtotal: Value(subtotal),
      createdAt: Value(createdAt),
    );
  }

  factory PromotionRedemption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromotionRedemption(
      id: serializer.fromJson<String>(json['id']),
      promotionId: serializer.fromJson<String>(json['promotionId']),
      saleId: serializer.fromJson<String>(json['saleId']),
      codeSnapshot: serializer.fromJson<String>(json['codeSnapshot']),
      discountApplied: serializer.fromJson<String>(json['discountApplied']),
      subtotal: serializer.fromJson<String>(json['subtotal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'promotionId': serializer.toJson<String>(promotionId),
      'saleId': serializer.toJson<String>(saleId),
      'codeSnapshot': serializer.toJson<String>(codeSnapshot),
      'discountApplied': serializer.toJson<String>(discountApplied),
      'subtotal': serializer.toJson<String>(subtotal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PromotionRedemption copyWith({
    String? id,
    String? promotionId,
    String? saleId,
    String? codeSnapshot,
    String? discountApplied,
    String? subtotal,
    DateTime? createdAt,
  }) => PromotionRedemption(
    id: id ?? this.id,
    promotionId: promotionId ?? this.promotionId,
    saleId: saleId ?? this.saleId,
    codeSnapshot: codeSnapshot ?? this.codeSnapshot,
    discountApplied: discountApplied ?? this.discountApplied,
    subtotal: subtotal ?? this.subtotal,
    createdAt: createdAt ?? this.createdAt,
  );
  PromotionRedemption copyWithCompanion(PromotionRedemptionsCompanion data) {
    return PromotionRedemption(
      id: data.id.present ? data.id.value : this.id,
      promotionId: data.promotionId.present
          ? data.promotionId.value
          : this.promotionId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      codeSnapshot: data.codeSnapshot.present
          ? data.codeSnapshot.value
          : this.codeSnapshot,
      discountApplied: data.discountApplied.present
          ? data.discountApplied.value
          : this.discountApplied,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromotionRedemption(')
          ..write('id: $id, ')
          ..write('promotionId: $promotionId, ')
          ..write('saleId: $saleId, ')
          ..write('codeSnapshot: $codeSnapshot, ')
          ..write('discountApplied: $discountApplied, ')
          ..write('subtotal: $subtotal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    promotionId,
    saleId,
    codeSnapshot,
    discountApplied,
    subtotal,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromotionRedemption &&
          other.id == this.id &&
          other.promotionId == this.promotionId &&
          other.saleId == this.saleId &&
          other.codeSnapshot == this.codeSnapshot &&
          other.discountApplied == this.discountApplied &&
          other.subtotal == this.subtotal &&
          other.createdAt == this.createdAt);
}

class PromotionRedemptionsCompanion
    extends UpdateCompanion<PromotionRedemption> {
  final Value<String> id;
  final Value<String> promotionId;
  final Value<String> saleId;
  final Value<String> codeSnapshot;
  final Value<String> discountApplied;
  final Value<String> subtotal;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PromotionRedemptionsCompanion({
    this.id = const Value.absent(),
    this.promotionId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.codeSnapshot = const Value.absent(),
    this.discountApplied = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromotionRedemptionsCompanion.insert({
    required String id,
    required String promotionId,
    required String saleId,
    required String codeSnapshot,
    required String discountApplied,
    required String subtotal,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       promotionId = Value(promotionId),
       saleId = Value(saleId),
       codeSnapshot = Value(codeSnapshot),
       discountApplied = Value(discountApplied),
       subtotal = Value(subtotal),
       createdAt = Value(createdAt);
  static Insertable<PromotionRedemption> custom({
    Expression<String>? id,
    Expression<String>? promotionId,
    Expression<String>? saleId,
    Expression<String>? codeSnapshot,
    Expression<String>? discountApplied,
    Expression<String>? subtotal,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (promotionId != null) 'promotion_id': promotionId,
      if (saleId != null) 'sale_id': saleId,
      if (codeSnapshot != null) 'code_snapshot': codeSnapshot,
      if (discountApplied != null) 'discount_applied': discountApplied,
      if (subtotal != null) 'subtotal': subtotal,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromotionRedemptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? promotionId,
    Value<String>? saleId,
    Value<String>? codeSnapshot,
    Value<String>? discountApplied,
    Value<String>? subtotal,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PromotionRedemptionsCompanion(
      id: id ?? this.id,
      promotionId: promotionId ?? this.promotionId,
      saleId: saleId ?? this.saleId,
      codeSnapshot: codeSnapshot ?? this.codeSnapshot,
      discountApplied: discountApplied ?? this.discountApplied,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (promotionId.present) {
      map['promotion_id'] = Variable<String>(promotionId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (codeSnapshot.present) {
      map['code_snapshot'] = Variable<String>(codeSnapshot.value);
    }
    if (discountApplied.present) {
      map['discount_applied'] = Variable<String>(discountApplied.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<String>(subtotal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromotionRedemptionsCompanion(')
          ..write('id: $id, ')
          ..write('promotionId: $promotionId, ')
          ..write('saleId: $saleId, ')
          ..write('codeSnapshot: $codeSnapshot, ')
          ..write('discountApplied: $discountApplied, ')
          ..write('subtotal: $subtotal, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SuppliersTable extends Suppliers
    with TableInfo<$SuppliersTable, Supplier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuppliersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _termsDaysMeta = const VerificationMeta(
    'termsDays',
  );
  @override
  late final GeneratedColumn<int> termsDays = GeneratedColumn<int>(
    'terms_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<String> openingBalance = GeneratedColumn<String>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<String> currentBalance = GeneratedColumn<String>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    email,
    address,
    termsDays,
    openingBalance,
    currentBalance,
    notes,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suppliers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Supplier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('terms_days')) {
      context.handle(
        _termsDaysMeta,
        termsDays.isAcceptableOrUnknown(data['terms_days']!, _termsDaysMeta),
      );
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Supplier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Supplier(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      termsDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}terms_days'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_balance'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_balance'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SuppliersTable createAlias(String alias) {
    return $SuppliersTable(attachedDatabase, alias);
  }
}

class Supplier extends DataClass implements Insertable<Supplier> {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int termsDays;
  final String openingBalance;
  final String currentBalance;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.termsDays,
    required this.openingBalance,
    required this.currentBalance,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['terms_days'] = Variable<int>(termsDays);
    map['opening_balance'] = Variable<String>(openingBalance);
    map['current_balance'] = Variable<String>(currentBalance);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SuppliersCompanion toCompanion(bool nullToAbsent) {
    return SuppliersCompanion(
      id: Value(id),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      termsDays: Value(termsDays),
      openingBalance: Value(openingBalance),
      currentBalance: Value(currentBalance),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Supplier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Supplier(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      termsDays: serializer.fromJson<int>(json['termsDays']),
      openingBalance: serializer.fromJson<String>(json['openingBalance']),
      currentBalance: serializer.fromJson<String>(json['currentBalance']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'termsDays': serializer.toJson<int>(termsDays),
      'openingBalance': serializer.toJson<String>(openingBalance),
      'currentBalance': serializer.toJson<String>(currentBalance),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    int? termsDays,
    String? openingBalance,
    String? currentBalance,
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Supplier(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    termsDays: termsDays ?? this.termsDays,
    openingBalance: openingBalance ?? this.openingBalance,
    currentBalance: currentBalance ?? this.currentBalance,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Supplier copyWithCompanion(SuppliersCompanion data) {
    return Supplier(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      termsDays: data.termsDays.present ? data.termsDays.value : this.termsDays,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Supplier(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('termsDays: $termsDays, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    phone,
    email,
    address,
    termsDays,
    openingBalance,
    currentBalance,
    notes,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Supplier &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.termsDays == this.termsDays &&
          other.openingBalance == this.openingBalance &&
          other.currentBalance == this.currentBalance &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SuppliersCompanion extends UpdateCompanion<Supplier> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<int> termsDays;
  final Value<String> openingBalance;
  final Value<String> currentBalance;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SuppliersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.termsDays = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuppliersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.termsDays = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Supplier> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<int>? termsDays,
    Expression<String>? openingBalance,
    Expression<String>? currentBalance,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (termsDays != null) 'terms_days': termsDays,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuppliersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? address,
    Value<int>? termsDays,
    Value<String>? openingBalance,
    Value<String>? currentBalance,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SuppliersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      termsDays: termsDays ?? this.termsDays,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (termsDays.present) {
      map['terms_days'] = Variable<int>(termsDays.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<String>(openingBalance.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<String>(currentBalance.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuppliersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('termsDays: $termsDays, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseOrdersTable extends PurchaseOrders
    with TableInfo<$PurchaseOrdersTable, PurchaseOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES suppliers (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<String> subtotal = GeneratedColumn<String>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _orderDateMeta = const VerificationMeta(
    'orderDate',
  );
  @override
  late final GeneratedColumn<DateTime> orderDate = GeneratedColumn<DateTime>(
    'order_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supplierId,
    status,
    subtotal,
    orderDate,
    dueDate,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_supplierIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('order_date')) {
      context.handle(
        _orderDateMeta,
        orderDate.isAcceptableOrUnknown(data['order_date']!, _orderDateMeta),
      );
    } else if (isInserting) {
      context.missing(_orderDateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtotal'],
      )!,
      orderDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}order_date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PurchaseOrdersTable createAlias(String alias) {
    return $PurchaseOrdersTable(attachedDatabase, alias);
  }
}

class PurchaseOrder extends DataClass implements Insertable<PurchaseOrder> {
  final String id;
  final String supplierId;
  final int status;
  final String subtotal;
  final DateTime orderDate;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.status,
    required this.subtotal,
    required this.orderDate,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['supplier_id'] = Variable<String>(supplierId);
    map['status'] = Variable<int>(status);
    map['subtotal'] = Variable<String>(subtotal);
    map['order_date'] = Variable<DateTime>(orderDate);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PurchaseOrdersCompanion toCompanion(bool nullToAbsent) {
    return PurchaseOrdersCompanion(
      id: Value(id),
      supplierId: Value(supplierId),
      status: Value(status),
      subtotal: Value(subtotal),
      orderDate: Value(orderDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PurchaseOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseOrder(
      id: serializer.fromJson<String>(json['id']),
      supplierId: serializer.fromJson<String>(json['supplierId']),
      status: serializer.fromJson<int>(json['status']),
      subtotal: serializer.fromJson<String>(json['subtotal']),
      orderDate: serializer.fromJson<DateTime>(json['orderDate']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'supplierId': serializer.toJson<String>(supplierId),
      'status': serializer.toJson<int>(status),
      'subtotal': serializer.toJson<String>(subtotal),
      'orderDate': serializer.toJson<DateTime>(orderDate),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PurchaseOrder copyWith({
    String? id,
    String? supplierId,
    int? status,
    String? subtotal,
    DateTime? orderDate,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PurchaseOrder(
    id: id ?? this.id,
    supplierId: supplierId ?? this.supplierId,
    status: status ?? this.status,
    subtotal: subtotal ?? this.subtotal,
    orderDate: orderDate ?? this.orderDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PurchaseOrder copyWithCompanion(PurchaseOrdersCompanion data) {
    return PurchaseOrder(
      id: data.id.present ? data.id.value : this.id,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      status: data.status.present ? data.status.value : this.status,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      orderDate: data.orderDate.present ? data.orderDate.value : this.orderDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrder(')
          ..write('id: $id, ')
          ..write('supplierId: $supplierId, ')
          ..write('status: $status, ')
          ..write('subtotal: $subtotal, ')
          ..write('orderDate: $orderDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supplierId,
    status,
    subtotal,
    orderDate,
    dueDate,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOrder &&
          other.id == this.id &&
          other.supplierId == this.supplierId &&
          other.status == this.status &&
          other.subtotal == this.subtotal &&
          other.orderDate == this.orderDate &&
          other.dueDate == this.dueDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PurchaseOrdersCompanion extends UpdateCompanion<PurchaseOrder> {
  final Value<String> id;
  final Value<String> supplierId;
  final Value<int> status;
  final Value<String> subtotal;
  final Value<DateTime> orderDate;
  final Value<DateTime?> dueDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PurchaseOrdersCompanion({
    this.id = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.status = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.orderDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseOrdersCompanion.insert({
    required String id,
    required String supplierId,
    this.status = const Value.absent(),
    this.subtotal = const Value.absent(),
    required DateTime orderDate,
    this.dueDate = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       supplierId = Value(supplierId),
       orderDate = Value(orderDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PurchaseOrder> custom({
    Expression<String>? id,
    Expression<String>? supplierId,
    Expression<int>? status,
    Expression<String>? subtotal,
    Expression<DateTime>? orderDate,
    Expression<DateTime>? dueDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supplierId != null) 'supplier_id': supplierId,
      if (status != null) 'status': status,
      if (subtotal != null) 'subtotal': subtotal,
      if (orderDate != null) 'order_date': orderDate,
      if (dueDate != null) 'due_date': dueDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseOrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? supplierId,
    Value<int>? status,
    Value<String>? subtotal,
    Value<DateTime>? orderDate,
    Value<DateTime?>? dueDate,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PurchaseOrdersCompanion(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      orderDate: orderDate ?? this.orderDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<String>(subtotal.value);
    }
    if (orderDate.present) {
      map['order_date'] = Variable<DateTime>(orderDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrdersCompanion(')
          ..write('id: $id, ')
          ..write('supplierId: $supplierId, ')
          ..write('status: $status, ')
          ..write('subtotal: $subtotal, ')
          ..write('orderDate: $orderDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseOrderLineItemsTable extends PurchaseOrderLineItems
    with TableInfo<$PurchaseOrderLineItemsTable, PurchaseOrderLineItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseOrderLineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseOrderIdMeta = const VerificationMeta(
    'purchaseOrderId',
  );
  @override
  late final GeneratedColumn<String> purchaseOrderId = GeneratedColumn<String>(
    'purchase_order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES purchase_orders (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsPerCartonMeta = const VerificationMeta(
    'itemsPerCarton',
  );
  @override
  late final GeneratedColumn<int> itemsPerCarton = GeneratedColumn<int>(
    'items_per_carton',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<String> unitCost = GeneratedColumn<String>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<String> lineTotal = GeneratedColumn<String>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    purchaseOrderId,
    productId,
    productName,
    sku,
    unit,
    itemsPerCarton,
    unitCost,
    quantity,
    lineTotal,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_order_line_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseOrderLineItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('purchase_order_id')) {
      context.handle(
        _purchaseOrderIdMeta,
        purchaseOrderId.isAcceptableOrUnknown(
          data['purchase_order_id']!,
          _purchaseOrderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseOrderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('items_per_carton')) {
      context.handle(
        _itemsPerCartonMeta,
        itemsPerCarton.isAcceptableOrUnknown(
          data['items_per_carton']!,
          _itemsPerCartonMeta,
        ),
      );
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    } else if (isInserting) {
      context.missing(_unitCostMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseOrderLineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseOrderLineItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      purchaseOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_order_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      itemsPerCarton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items_per_carton'],
      ),
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_cost'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_total'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PurchaseOrderLineItemsTable createAlias(String alias) {
    return $PurchaseOrderLineItemsTable(attachedDatabase, alias);
  }
}

class PurchaseOrderLineItem extends DataClass
    implements Insertable<PurchaseOrderLineItem> {
  final String id;
  final String purchaseOrderId;
  final String productId;
  final String productName;
  final String? sku;
  final String? unit;
  final int? itemsPerCarton;
  final String unitCost;
  final int quantity;
  final String lineTotal;
  final DateTime createdAt;
  const PurchaseOrderLineItem({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    required this.productName,
    this.sku,
    this.unit,
    this.itemsPerCarton,
    required this.unitCost,
    required this.quantity,
    required this.lineTotal,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['purchase_order_id'] = Variable<String>(purchaseOrderId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || itemsPerCarton != null) {
      map['items_per_carton'] = Variable<int>(itemsPerCarton);
    }
    map['unit_cost'] = Variable<String>(unitCost);
    map['quantity'] = Variable<int>(quantity);
    map['line_total'] = Variable<String>(lineTotal);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PurchaseOrderLineItemsCompanion toCompanion(bool nullToAbsent) {
    return PurchaseOrderLineItemsCompanion(
      id: Value(id),
      purchaseOrderId: Value(purchaseOrderId),
      productId: Value(productId),
      productName: Value(productName),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      itemsPerCarton: itemsPerCarton == null && nullToAbsent
          ? const Value.absent()
          : Value(itemsPerCarton),
      unitCost: Value(unitCost),
      quantity: Value(quantity),
      lineTotal: Value(lineTotal),
      createdAt: Value(createdAt),
    );
  }

  factory PurchaseOrderLineItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseOrderLineItem(
      id: serializer.fromJson<String>(json['id']),
      purchaseOrderId: serializer.fromJson<String>(json['purchaseOrderId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      sku: serializer.fromJson<String?>(json['sku']),
      unit: serializer.fromJson<String?>(json['unit']),
      itemsPerCarton: serializer.fromJson<int?>(json['itemsPerCarton']),
      unitCost: serializer.fromJson<String>(json['unitCost']),
      quantity: serializer.fromJson<int>(json['quantity']),
      lineTotal: serializer.fromJson<String>(json['lineTotal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'purchaseOrderId': serializer.toJson<String>(purchaseOrderId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'sku': serializer.toJson<String?>(sku),
      'unit': serializer.toJson<String?>(unit),
      'itemsPerCarton': serializer.toJson<int?>(itemsPerCarton),
      'unitCost': serializer.toJson<String>(unitCost),
      'quantity': serializer.toJson<int>(quantity),
      'lineTotal': serializer.toJson<String>(lineTotal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PurchaseOrderLineItem copyWith({
    String? id,
    String? purchaseOrderId,
    String? productId,
    String? productName,
    Value<String?> sku = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<int?> itemsPerCarton = const Value.absent(),
    String? unitCost,
    int? quantity,
    String? lineTotal,
    DateTime? createdAt,
  }) => PurchaseOrderLineItem(
    id: id ?? this.id,
    purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    sku: sku.present ? sku.value : this.sku,
    unit: unit.present ? unit.value : this.unit,
    itemsPerCarton: itemsPerCarton.present
        ? itemsPerCarton.value
        : this.itemsPerCarton,
    unitCost: unitCost ?? this.unitCost,
    quantity: quantity ?? this.quantity,
    lineTotal: lineTotal ?? this.lineTotal,
    createdAt: createdAt ?? this.createdAt,
  );
  PurchaseOrderLineItem copyWithCompanion(
    PurchaseOrderLineItemsCompanion data,
  ) {
    return PurchaseOrderLineItem(
      id: data.id.present ? data.id.value : this.id,
      purchaseOrderId: data.purchaseOrderId.present
          ? data.purchaseOrderId.value
          : this.purchaseOrderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      sku: data.sku.present ? data.sku.value : this.sku,
      unit: data.unit.present ? data.unit.value : this.unit,
      itemsPerCarton: data.itemsPerCarton.present
          ? data.itemsPerCarton.value
          : this.itemsPerCarton,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrderLineItem(')
          ..write('id: $id, ')
          ..write('purchaseOrderId: $purchaseOrderId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('sku: $sku, ')
          ..write('unit: $unit, ')
          ..write('itemsPerCarton: $itemsPerCarton, ')
          ..write('unitCost: $unitCost, ')
          ..write('quantity: $quantity, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    purchaseOrderId,
    productId,
    productName,
    sku,
    unit,
    itemsPerCarton,
    unitCost,
    quantity,
    lineTotal,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOrderLineItem &&
          other.id == this.id &&
          other.purchaseOrderId == this.purchaseOrderId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.sku == this.sku &&
          other.unit == this.unit &&
          other.itemsPerCarton == this.itemsPerCarton &&
          other.unitCost == this.unitCost &&
          other.quantity == this.quantity &&
          other.lineTotal == this.lineTotal &&
          other.createdAt == this.createdAt);
}

class PurchaseOrderLineItemsCompanion
    extends UpdateCompanion<PurchaseOrderLineItem> {
  final Value<String> id;
  final Value<String> purchaseOrderId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String?> sku;
  final Value<String?> unit;
  final Value<int?> itemsPerCarton;
  final Value<String> unitCost;
  final Value<int> quantity;
  final Value<String> lineTotal;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PurchaseOrderLineItemsCompanion({
    this.id = const Value.absent(),
    this.purchaseOrderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.sku = const Value.absent(),
    this.unit = const Value.absent(),
    this.itemsPerCarton = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.quantity = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseOrderLineItemsCompanion.insert({
    required String id,
    required String purchaseOrderId,
    required String productId,
    required String productName,
    this.sku = const Value.absent(),
    this.unit = const Value.absent(),
    this.itemsPerCarton = const Value.absent(),
    required String unitCost,
    required int quantity,
    required String lineTotal,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       purchaseOrderId = Value(purchaseOrderId),
       productId = Value(productId),
       productName = Value(productName),
       unitCost = Value(unitCost),
       quantity = Value(quantity),
       lineTotal = Value(lineTotal),
       createdAt = Value(createdAt);
  static Insertable<PurchaseOrderLineItem> custom({
    Expression<String>? id,
    Expression<String>? purchaseOrderId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? sku,
    Expression<String>? unit,
    Expression<int>? itemsPerCarton,
    Expression<String>? unitCost,
    Expression<int>? quantity,
    Expression<String>? lineTotal,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (sku != null) 'sku': sku,
      if (unit != null) 'unit': unit,
      if (itemsPerCarton != null) 'items_per_carton': itemsPerCarton,
      if (unitCost != null) 'unit_cost': unitCost,
      if (quantity != null) 'quantity': quantity,
      if (lineTotal != null) 'line_total': lineTotal,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseOrderLineItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? purchaseOrderId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String?>? sku,
    Value<String?>? unit,
    Value<int?>? itemsPerCarton,
    Value<String>? unitCost,
    Value<int>? quantity,
    Value<String>? lineTotal,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PurchaseOrderLineItemsCompanion(
      id: id ?? this.id,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      itemsPerCarton: itemsPerCarton ?? this.itemsPerCarton,
      unitCost: unitCost ?? this.unitCost,
      quantity: quantity ?? this.quantity,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (purchaseOrderId.present) {
      map['purchase_order_id'] = Variable<String>(purchaseOrderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (itemsPerCarton.present) {
      map['items_per_carton'] = Variable<int>(itemsPerCarton.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<String>(unitCost.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<String>(lineTotal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrderLineItemsCompanion(')
          ..write('id: $id, ')
          ..write('purchaseOrderId: $purchaseOrderId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('sku: $sku, ')
          ..write('unit: $unit, ')
          ..write('itemsPerCarton: $itemsPerCarton, ')
          ..write('unitCost: $unitCost, ')
          ..write('quantity: $quantity, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleLineItemsTable extends SaleLineItems
    with TableInfo<$SaleLineItemsTable, SaleLineItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleLineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsPerCartonMeta = const VerificationMeta(
    'itemsPerCarton',
  );
  @override
  late final GeneratedColumn<int> itemsPerCarton = GeneratedColumn<int>(
    'items_per_carton',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<String> unitPrice = GeneratedColumn<String>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<String> lineTotal = GeneratedColumn<String>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    productId,
    productName,
    sku,
    unit,
    itemsPerCarton,
    unitPrice,
    quantity,
    lineTotal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_line_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleLineItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('items_per_carton')) {
      context.handle(
        _itemsPerCartonMeta,
        itemsPerCarton.isAcceptableOrUnknown(
          data['items_per_carton']!,
          _itemsPerCartonMeta,
        ),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleLineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleLineItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      itemsPerCarton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items_per_carton'],
      ),
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_price'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_total'],
      )!,
    );
  }

  @override
  $SaleLineItemsTable createAlias(String alias) {
    return $SaleLineItemsTable(attachedDatabase, alias);
  }
}

class SaleLineItem extends DataClass implements Insertable<SaleLineItem> {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String? sku;
  final String? unit;
  final int? itemsPerCarton;
  final String unitPrice;
  final int quantity;
  final String lineTotal;
  const SaleLineItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    this.sku,
    this.unit,
    this.itemsPerCarton,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || itemsPerCarton != null) {
      map['items_per_carton'] = Variable<int>(itemsPerCarton);
    }
    map['unit_price'] = Variable<String>(unitPrice);
    map['quantity'] = Variable<int>(quantity);
    map['line_total'] = Variable<String>(lineTotal);
    return map;
  }

  SaleLineItemsCompanion toCompanion(bool nullToAbsent) {
    return SaleLineItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      productName: Value(productName),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      itemsPerCarton: itemsPerCarton == null && nullToAbsent
          ? const Value.absent()
          : Value(itemsPerCarton),
      unitPrice: Value(unitPrice),
      quantity: Value(quantity),
      lineTotal: Value(lineTotal),
    );
  }

  factory SaleLineItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleLineItem(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      sku: serializer.fromJson<String?>(json['sku']),
      unit: serializer.fromJson<String?>(json['unit']),
      itemsPerCarton: serializer.fromJson<int?>(json['itemsPerCarton']),
      unitPrice: serializer.fromJson<String>(json['unitPrice']),
      quantity: serializer.fromJson<int>(json['quantity']),
      lineTotal: serializer.fromJson<String>(json['lineTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'sku': serializer.toJson<String?>(sku),
      'unit': serializer.toJson<String?>(unit),
      'itemsPerCarton': serializer.toJson<int?>(itemsPerCarton),
      'unitPrice': serializer.toJson<String>(unitPrice),
      'quantity': serializer.toJson<int>(quantity),
      'lineTotal': serializer.toJson<String>(lineTotal),
    };
  }

  SaleLineItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    Value<String?> sku = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<int?> itemsPerCarton = const Value.absent(),
    String? unitPrice,
    int? quantity,
    String? lineTotal,
  }) => SaleLineItem(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    sku: sku.present ? sku.value : this.sku,
    unit: unit.present ? unit.value : this.unit,
    itemsPerCarton: itemsPerCarton.present
        ? itemsPerCarton.value
        : this.itemsPerCarton,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    lineTotal: lineTotal ?? this.lineTotal,
  );
  SaleLineItem copyWithCompanion(SaleLineItemsCompanion data) {
    return SaleLineItem(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      sku: data.sku.present ? data.sku.value : this.sku,
      unit: data.unit.present ? data.unit.value : this.unit,
      itemsPerCarton: data.itemsPerCarton.present
          ? data.itemsPerCarton.value
          : this.itemsPerCarton,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleLineItem(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('sku: $sku, ')
          ..write('unit: $unit, ')
          ..write('itemsPerCarton: $itemsPerCarton, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantity: $quantity, ')
          ..write('lineTotal: $lineTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    productId,
    productName,
    sku,
    unit,
    itemsPerCarton,
    unitPrice,
    quantity,
    lineTotal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleLineItem &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.sku == this.sku &&
          other.unit == this.unit &&
          other.itemsPerCarton == this.itemsPerCarton &&
          other.unitPrice == this.unitPrice &&
          other.quantity == this.quantity &&
          other.lineTotal == this.lineTotal);
}

class SaleLineItemsCompanion extends UpdateCompanion<SaleLineItem> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String?> sku;
  final Value<String?> unit;
  final Value<int?> itemsPerCarton;
  final Value<String> unitPrice;
  final Value<int> quantity;
  final Value<String> lineTotal;
  final Value<int> rowid;
  const SaleLineItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.sku = const Value.absent(),
    this.unit = const Value.absent(),
    this.itemsPerCarton = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleLineItemsCompanion.insert({
    required String id,
    required String saleId,
    required String productId,
    required String productName,
    this.sku = const Value.absent(),
    this.unit = const Value.absent(),
    this.itemsPerCarton = const Value.absent(),
    required String unitPrice,
    required int quantity,
    required String lineTotal,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       productId = Value(productId),
       productName = Value(productName),
       unitPrice = Value(unitPrice),
       quantity = Value(quantity),
       lineTotal = Value(lineTotal);
  static Insertable<SaleLineItem> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? sku,
    Expression<String>? unit,
    Expression<int>? itemsPerCarton,
    Expression<String>? unitPrice,
    Expression<int>? quantity,
    Expression<String>? lineTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (sku != null) 'sku': sku,
      if (unit != null) 'unit': unit,
      if (itemsPerCarton != null) 'items_per_carton': itemsPerCarton,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (quantity != null) 'quantity': quantity,
      if (lineTotal != null) 'line_total': lineTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleLineItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String?>? sku,
    Value<String?>? unit,
    Value<int?>? itemsPerCarton,
    Value<String>? unitPrice,
    Value<int>? quantity,
    Value<String>? lineTotal,
    Value<int>? rowid,
  }) {
    return SaleLineItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      itemsPerCarton: itemsPerCarton ?? this.itemsPerCarton,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      lineTotal: lineTotal ?? this.lineTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (itemsPerCarton.present) {
      map['items_per_carton'] = Variable<int>(itemsPerCarton.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<String>(unitPrice.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<String>(lineTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleLineItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('sku: $sku, ')
          ..write('unit: $unit, ')
          ..write('itemsPerCarton: $itemsPerCarton, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantity: $quantity, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityChangeMeta = const VerificationMeta(
    'quantityChange',
  );
  @override
  late final GeneratedColumn<int> quantityChange = GeneratedColumn<int>(
    'quantity_change',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    movementType,
    quantityChange,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('quantity_change')) {
      context.handle(
        _quantityChangeMeta,
        quantityChange.isAcceptableOrUnknown(
          data['quantity_change']!,
          _quantityChangeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityChangeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      quantityChange: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_change'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class StockMovement extends DataClass implements Insertable<StockMovement> {
  final String id;
  final String productId;
  final String movementType;
  final int quantityChange;
  final String? note;
  final DateTime createdAt;
  const StockMovement({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantityChange,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['movement_type'] = Variable<String>(movementType);
    map['quantity_change'] = Variable<int>(quantityChange);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      movementType: Value(movementType),
      quantityChange: Value(quantityChange),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory StockMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovement(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      movementType: serializer.fromJson<String>(json['movementType']),
      quantityChange: serializer.fromJson<int>(json['quantityChange']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'movementType': serializer.toJson<String>(movementType),
      'quantityChange': serializer.toJson<int>(quantityChange),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StockMovement copyWith({
    String? id,
    String? productId,
    String? movementType,
    int? quantityChange,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => StockMovement(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    movementType: movementType ?? this.movementType,
    quantityChange: quantityChange ?? this.quantityChange,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  StockMovement copyWithCompanion(StockMovementsCompanion data) {
    return StockMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      quantityChange: data.quantityChange.present
          ? data.quantityChange.value
          : this.quantityChange,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('movementType: $movementType, ')
          ..write('quantityChange: $quantityChange, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, movementType, quantityChange, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.movementType == this.movementType &&
          other.quantityChange == this.quantityChange &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovement> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> movementType;
  final Value<int> quantityChange;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.quantityChange = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    required String id,
    required String productId,
    required String movementType,
    required int quantityChange,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       movementType = Value(movementType),
       quantityChange = Value(quantityChange),
       createdAt = Value(createdAt);
  static Insertable<StockMovement> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? movementType,
    Expression<int>? quantityChange,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (movementType != null) 'movement_type': movementType,
      if (quantityChange != null) 'quantity_change': quantityChange,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? movementType,
    Value<int>? quantityChange,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      movementType: movementType ?? this.movementType,
      quantityChange: quantityChange ?? this.quantityChange,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (quantityChange.present) {
      map['quantity_change'] = Variable<int>(quantityChange.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('movementType: $movementType, ')
          ..write('quantityChange: $quantityChange, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamMembersTable extends TeamMembers
    with TableInfo<$TeamMembersTable, TeamMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<int> role = GeneratedColumn<int>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fullName,
    phoneNumber,
    role,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}role'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TeamMembersTable createAlias(String alias) {
    return $TeamMembersTable(attachedDatabase, alias);
  }
}

class TeamMember extends DataClass implements Insertable<TeamMember> {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final int role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TeamMember({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    map['role'] = Variable<int>(role);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TeamMembersCompanion toCompanion(bool nullToAbsent) {
    return TeamMembersCompanion(
      id: Value(id),
      fullName: Value(fullName),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      role: Value(role),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TeamMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamMember(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      role: serializer.fromJson<int>(json['role']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'role': serializer.toJson<int>(role),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TeamMember copyWith({
    String? id,
    String? fullName,
    Value<String?> phoneNumber = const Value.absent(),
    int? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TeamMember(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    role: role ?? this.role,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TeamMember copyWithCompanion(TeamMembersCompanion data) {
    return TeamMember(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      role: data.role.present ? data.role.value : this.role,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamMember(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    phoneNumber,
    role,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamMember &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.phoneNumber == this.phoneNumber &&
          other.role == this.role &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TeamMembersCompanion extends UpdateCompanion<TeamMember> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String?> phoneNumber;
  final Value<int> role;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TeamMembersCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamMembersCompanion.insert({
    required String id,
    required String fullName,
    this.phoneNumber = const Value.absent(),
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TeamMember> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? phoneNumber,
    Expression<int>? role,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String?>? phoneNumber,
    Value<int>? role,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TeamMembersCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(role.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamMembersCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contacts (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cartonsMeta = const VerificationMeta(
    'cartons',
  );
  @override
  late final GeneratedColumn<int> cartons = GeneratedColumn<int>(
    'cartons',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyPerCartonMeta = const VerificationMeta(
    'qtyPerCarton',
  );
  @override
  late final GeneratedColumn<int> qtyPerCarton = GeneratedColumn<int>(
    'qty_per_carton',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<String> unitPrice = GeneratedColumn<String>(
    'unit_price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contactId,
    type,
    status,
    amount,
    date,
    description,
    cartons,
    qtyPerCarton,
    unitPrice,
    metadata,
    referenceId,
    saleId,
    isSynced,
    isDeleted,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cartons')) {
      context.handle(
        _cartonsMeta,
        cartons.isAcceptableOrUnknown(data['cartons']!, _cartonsMeta),
      );
    }
    if (data.containsKey('qty_per_carton')) {
      context.handle(
        _qtyPerCartonMeta,
        qtyPerCarton.isAcceptableOrUnknown(
          data['qty_per_carton']!,
          _qtyPerCartonMeta,
        ),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      cartons: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cartons'],
      ),
      qtyPerCarton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_per_carton'],
      ),
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_price'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      ),
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String contactId;
  final int type;
  final int status;
  final String amount;
  final DateTime date;
  final String? description;
  final int? cartons;
  final int? qtyPerCarton;
  final String? unitPrice;
  final String? metadata;
  final String? referenceId;
  final String? saleId;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? deletedAt;
  const Transaction({
    required this.id,
    required this.contactId,
    required this.type,
    required this.status,
    required this.amount,
    required this.date,
    this.description,
    this.cartons,
    this.qtyPerCarton,
    this.unitPrice,
    this.metadata,
    this.referenceId,
    this.saleId,
    required this.isSynced,
    required this.isDeleted,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contact_id'] = Variable<String>(contactId);
    map['type'] = Variable<int>(type);
    map['status'] = Variable<int>(status);
    map['amount'] = Variable<String>(amount);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || cartons != null) {
      map['cartons'] = Variable<int>(cartons);
    }
    if (!nullToAbsent || qtyPerCarton != null) {
      map['qty_per_carton'] = Variable<int>(qtyPerCarton);
    }
    if (!nullToAbsent || unitPrice != null) {
      map['unit_price'] = Variable<String>(unitPrice);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    if (!nullToAbsent || saleId != null) {
      map['sale_id'] = Variable<String>(saleId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      contactId: Value(contactId),
      type: Value(type),
      status: Value(status),
      amount: Value(amount),
      date: Value(date),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      cartons: cartons == null && nullToAbsent
          ? const Value.absent()
          : Value(cartons),
      qtyPerCarton: qtyPerCarton == null && nullToAbsent
          ? const Value.absent()
          : Value(qtyPerCarton),
      unitPrice: unitPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPrice),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      saleId: saleId == null && nullToAbsent
          ? const Value.absent()
          : Value(saleId),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      contactId: serializer.fromJson<String>(json['contactId']),
      type: serializer.fromJson<int>(json['type']),
      status: serializer.fromJson<int>(json['status']),
      amount: serializer.fromJson<String>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      description: serializer.fromJson<String?>(json['description']),
      cartons: serializer.fromJson<int?>(json['cartons']),
      qtyPerCarton: serializer.fromJson<int?>(json['qtyPerCarton']),
      unitPrice: serializer.fromJson<String?>(json['unitPrice']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      saleId: serializer.fromJson<String?>(json['saleId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contactId': serializer.toJson<String>(contactId),
      'type': serializer.toJson<int>(type),
      'status': serializer.toJson<int>(status),
      'amount': serializer.toJson<String>(amount),
      'date': serializer.toJson<DateTime>(date),
      'description': serializer.toJson<String?>(description),
      'cartons': serializer.toJson<int?>(cartons),
      'qtyPerCarton': serializer.toJson<int?>(qtyPerCarton),
      'unitPrice': serializer.toJson<String?>(unitPrice),
      'metadata': serializer.toJson<String?>(metadata),
      'referenceId': serializer.toJson<String?>(referenceId),
      'saleId': serializer.toJson<String?>(saleId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Transaction copyWith({
    String? id,
    String? contactId,
    int? type,
    int? status,
    String? amount,
    DateTime? date,
    Value<String?> description = const Value.absent(),
    Value<int?> cartons = const Value.absent(),
    Value<int?> qtyPerCarton = const Value.absent(),
    Value<String?> unitPrice = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    Value<String?> referenceId = const Value.absent(),
    Value<String?> saleId = const Value.absent(),
    bool? isSynced,
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    contactId: contactId ?? this.contactId,
    type: type ?? this.type,
    status: status ?? this.status,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    description: description.present ? description.value : this.description,
    cartons: cartons.present ? cartons.value : this.cartons,
    qtyPerCarton: qtyPerCarton.present ? qtyPerCarton.value : this.qtyPerCarton,
    unitPrice: unitPrice.present ? unitPrice.value : this.unitPrice,
    metadata: metadata.present ? metadata.value : this.metadata,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    saleId: saleId.present ? saleId.value : this.saleId,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      description: data.description.present
          ? data.description.value
          : this.description,
      cartons: data.cartons.present ? data.cartons.value : this.cartons,
      qtyPerCarton: data.qtyPerCarton.present
          ? data.qtyPerCarton.value
          : this.qtyPerCarton,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('contactId: $contactId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('description: $description, ')
          ..write('cartons: $cartons, ')
          ..write('qtyPerCarton: $qtyPerCarton, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('metadata: $metadata, ')
          ..write('referenceId: $referenceId, ')
          ..write('saleId: $saleId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contactId,
    type,
    status,
    amount,
    date,
    description,
    cartons,
    qtyPerCarton,
    unitPrice,
    metadata,
    referenceId,
    saleId,
    isSynced,
    isDeleted,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.contactId == this.contactId &&
          other.type == this.type &&
          other.status == this.status &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.description == this.description &&
          other.cartons == this.cartons &&
          other.qtyPerCarton == this.qtyPerCarton &&
          other.unitPrice == this.unitPrice &&
          other.metadata == this.metadata &&
          other.referenceId == this.referenceId &&
          other.saleId == this.saleId &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> contactId;
  final Value<int> type;
  final Value<int> status;
  final Value<String> amount;
  final Value<DateTime> date;
  final Value<String?> description;
  final Value<int?> cartons;
  final Value<int?> qtyPerCarton;
  final Value<String?> unitPrice;
  final Value<String?> metadata;
  final Value<String?> referenceId;
  final Value<String?> saleId;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.contactId = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.description = const Value.absent(),
    this.cartons = const Value.absent(),
    this.qtyPerCarton = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.metadata = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String contactId,
    required int type,
    this.status = const Value.absent(),
    required String amount,
    required DateTime date,
    this.description = const Value.absent(),
    this.cartons = const Value.absent(),
    this.qtyPerCarton = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.metadata = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contactId = Value(contactId),
       type = Value(type),
       amount = Value(amount),
       date = Value(date);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? contactId,
    Expression<int>? type,
    Expression<int>? status,
    Expression<String>? amount,
    Expression<DateTime>? date,
    Expression<String>? description,
    Expression<int>? cartons,
    Expression<int>? qtyPerCarton,
    Expression<String>? unitPrice,
    Expression<String>? metadata,
    Expression<String>? referenceId,
    Expression<String>? saleId,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contactId != null) 'contact_id': contactId,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (description != null) 'description': description,
      if (cartons != null) 'cartons': cartons,
      if (qtyPerCarton != null) 'qty_per_carton': qtyPerCarton,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (metadata != null) 'metadata': metadata,
      if (referenceId != null) 'reference_id': referenceId,
      if (saleId != null) 'sale_id': saleId,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? contactId,
    Value<int>? type,
    Value<int>? status,
    Value<String>? amount,
    Value<DateTime>? date,
    Value<String?>? description,
    Value<int?>? cartons,
    Value<int?>? qtyPerCarton,
    Value<String?>? unitPrice,
    Value<String?>? metadata,
    Value<String?>? referenceId,
    Value<String?>? saleId,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      cartons: cartons ?? this.cartons,
      qtyPerCarton: qtyPerCarton ?? this.qtyPerCarton,
      unitPrice: unitPrice ?? this.unitPrice,
      metadata: metadata ?? this.metadata,
      referenceId: referenceId ?? this.referenceId,
      saleId: saleId ?? this.saleId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (cartons.present) {
      map['cartons'] = Variable<int>(cartons.value);
    }
    if (qtyPerCarton.present) {
      map['qty_per_carton'] = Variable<int>(qtyPerCarton.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<String>(unitPrice.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
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
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('contactId: $contactId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('description: $description, ')
          ..write('cartons: $cartons, ')
          ..write('qtyPerCarton: $qtyPerCarton, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('metadata: $metadata, ')
          ..write('referenceId: $referenceId, ')
          ..write('saleId: $saleId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ExpenseCategoriesTable expenseCategories =
      $ExpenseCategoriesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $PromotionsTable promotions = $PromotionsTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $PromotionRedemptionsTable promotionRedemptions =
      $PromotionRedemptionsTable(this);
  late final $SuppliersTable suppliers = $SuppliersTable(this);
  late final $PurchaseOrdersTable purchaseOrders = $PurchaseOrdersTable(this);
  late final $PurchaseOrderLineItemsTable purchaseOrderLineItems =
      $PurchaseOrderLineItemsTable(this);
  late final $SaleLineItemsTable saleLineItems = $SaleLineItemsTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $TeamMembersTable teamMembers = $TeamMembersTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    auditLogs,
    contacts,
    expenseCategories,
    expenses,
    products,
    promotions,
    sales,
    promotionRedemptions,
    suppliers,
    purchaseOrders,
    purchaseOrderLineItems,
    saleLineItems,
    stockMovements,
    teamMembers,
    transactions,
  ];
}

typedef $$AuditLogsTableCreateCompanionBuilder =
    AuditLogsCompanion Function({
      required String id,
      Value<int> actorRole,
      required String action,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<String?> message,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AuditLogsTableUpdateCompanionBuilder =
    AuditLogsCompanion Function({
      Value<String> id,
      Value<int> actorRole,
      Value<String> action,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<String?> message,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
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

  ColumnFilters<int> get actorRole => $composableBuilder(
    column: $table.actorRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
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

  ColumnOrderings<int> get actorRole => $composableBuilder(
    column: $table.actorRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get actorRole =>
      $composableBuilder(column: $table.actorRole, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AuditLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogsTable,
          AuditLog,
          $$AuditLogsTableFilterComposer,
          $$AuditLogsTableOrderingComposer,
          $$AuditLogsTableAnnotationComposer,
          $$AuditLogsTableCreateCompanionBuilder,
          $$AuditLogsTableUpdateCompanionBuilder,
          (AuditLog, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>),
          AuditLog,
          PrefetchHooks Function()
        > {
  $$AuditLogsTableTableManager(_$AppDatabase db, $AuditLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> actorRole = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsCompanion(
                id: id,
                actorRole: actorRole,
                action: action,
                entityType: entityType,
                entityId: entityId,
                message: message,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> actorRole = const Value.absent(),
                required String action,
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String?> message = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsCompanion.insert(
                id: id,
                actorRole: actorRole,
                action: action,
                entityType: entityType,
                entityId: entityId,
                message: message,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogsTable,
      AuditLog,
      $$AuditLogsTableFilterComposer,
      $$AuditLogsTableOrderingComposer,
      $$AuditLogsTableAnnotationComposer,
      $$AuditLogsTableCreateCompanionBuilder,
      $$AuditLogsTableUpdateCompanionBuilder,
      (AuditLog, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>),
      AuditLog,
      PrefetchHooks Function()
    >;
typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      required String id,
      required String name,
      Value<int> role,
      Value<int> verificationStatus,
      Value<DateTime?> verificationRequestedAt,
      Value<DateTime?> verificationDeadlineAt,
      Value<int> verificationTimeoutPolicy,
      Value<String?> phoneNumber,
      Value<String?> shopNumber,
      Value<String> netBalance,
      Value<String> creditLimit,
      Value<int> loyaltyPoints,
      required DateTime lastTransactionDate,
      Value<String?> linkedUserUid,
      Value<String?> verificationMethod,
      Value<bool> isRetailer,
      Value<bool> isWholesaler,
      Value<bool> isBroker,
      Value<bool> isSupplier,
      Value<bool> isImporter,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> role,
      Value<int> verificationStatus,
      Value<DateTime?> verificationRequestedAt,
      Value<DateTime?> verificationDeadlineAt,
      Value<int> verificationTimeoutPolicy,
      Value<String?> phoneNumber,
      Value<String?> shopNumber,
      Value<String> netBalance,
      Value<String> creditLimit,
      Value<int> loyaltyPoints,
      Value<DateTime> lastTransactionDate,
      Value<String?> linkedUserUid,
      Value<String?> verificationMethod,
      Value<bool> isRetailer,
      Value<bool> isWholesaler,
      Value<bool> isBroker,
      Value<bool> isSupplier,
      Value<bool> isImporter,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$ContactsTableReferences
    extends BaseReferences<_$AppDatabase, $ContactsTable, Contact> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.contacts.id, db.transactions.contactId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.contactId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verificationRequestedAt => $composableBuilder(
    column: $table.verificationRequestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verificationDeadlineAt => $composableBuilder(
    column: $table.verificationDeadlineAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verificationTimeoutPolicy => $composableBuilder(
    column: $table.verificationTimeoutPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopNumber => $composableBuilder(
    column: $table.shopNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get netBalance => $composableBuilder(
    column: $table.netBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loyaltyPoints => $composableBuilder(
    column: $table.loyaltyPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastTransactionDate => $composableBuilder(
    column: $table.lastTransactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedUserUid => $composableBuilder(
    column: $table.linkedUserUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verificationMethod => $composableBuilder(
    column: $table.verificationMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRetailer => $composableBuilder(
    column: $table.isRetailer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWholesaler => $composableBuilder(
    column: $table.isWholesaler,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBroker => $composableBuilder(
    column: $table.isBroker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSupplier => $composableBuilder(
    column: $table.isSupplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isImporter => $composableBuilder(
    column: $table.isImporter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verificationRequestedAt => $composableBuilder(
    column: $table.verificationRequestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verificationDeadlineAt => $composableBuilder(
    column: $table.verificationDeadlineAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verificationTimeoutPolicy => $composableBuilder(
    column: $table.verificationTimeoutPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopNumber => $composableBuilder(
    column: $table.shopNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get netBalance => $composableBuilder(
    column: $table.netBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loyaltyPoints => $composableBuilder(
    column: $table.loyaltyPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastTransactionDate => $composableBuilder(
    column: $table.lastTransactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedUserUid => $composableBuilder(
    column: $table.linkedUserUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verificationMethod => $composableBuilder(
    column: $table.verificationMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRetailer => $composableBuilder(
    column: $table.isRetailer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWholesaler => $composableBuilder(
    column: $table.isWholesaler,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBroker => $composableBuilder(
    column: $table.isBroker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSupplier => $composableBuilder(
    column: $table.isSupplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isImporter => $composableBuilder(
    column: $table.isImporter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get verificationRequestedAt => $composableBuilder(
    column: $table.verificationRequestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get verificationDeadlineAt => $composableBuilder(
    column: $table.verificationDeadlineAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get verificationTimeoutPolicy => $composableBuilder(
    column: $table.verificationTimeoutPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shopNumber => $composableBuilder(
    column: $table.shopNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get netBalance => $composableBuilder(
    column: $table.netBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get loyaltyPoints => $composableBuilder(
    column: $table.loyaltyPoints,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastTransactionDate => $composableBuilder(
    column: $table.lastTransactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedUserUid => $composableBuilder(
    column: $table.linkedUserUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verificationMethod => $composableBuilder(
    column: $table.verificationMethod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRetailer => $composableBuilder(
    column: $table.isRetailer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWholesaler => $composableBuilder(
    column: $table.isWholesaler,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBroker =>
      $composableBuilder(column: $table.isBroker, builder: (column) => column);

  GeneratedColumn<bool> get isSupplier => $composableBuilder(
    column: $table.isSupplier,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isImporter => $composableBuilder(
    column: $table.isImporter,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, $$ContactsTableReferences),
          Contact,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> role = const Value.absent(),
                Value<int> verificationStatus = const Value.absent(),
                Value<DateTime?> verificationRequestedAt = const Value.absent(),
                Value<DateTime?> verificationDeadlineAt = const Value.absent(),
                Value<int> verificationTimeoutPolicy = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> shopNumber = const Value.absent(),
                Value<String> netBalance = const Value.absent(),
                Value<String> creditLimit = const Value.absent(),
                Value<int> loyaltyPoints = const Value.absent(),
                Value<DateTime> lastTransactionDate = const Value.absent(),
                Value<String?> linkedUserUid = const Value.absent(),
                Value<String?> verificationMethod = const Value.absent(),
                Value<bool> isRetailer = const Value.absent(),
                Value<bool> isWholesaler = const Value.absent(),
                Value<bool> isBroker = const Value.absent(),
                Value<bool> isSupplier = const Value.absent(),
                Value<bool> isImporter = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                name: name,
                role: role,
                verificationStatus: verificationStatus,
                verificationRequestedAt: verificationRequestedAt,
                verificationDeadlineAt: verificationDeadlineAt,
                verificationTimeoutPolicy: verificationTimeoutPolicy,
                phoneNumber: phoneNumber,
                shopNumber: shopNumber,
                netBalance: netBalance,
                creditLimit: creditLimit,
                loyaltyPoints: loyaltyPoints,
                lastTransactionDate: lastTransactionDate,
                linkedUserUid: linkedUserUid,
                verificationMethod: verificationMethod,
                isRetailer: isRetailer,
                isWholesaler: isWholesaler,
                isBroker: isBroker,
                isSupplier: isSupplier,
                isImporter: isImporter,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> role = const Value.absent(),
                Value<int> verificationStatus = const Value.absent(),
                Value<DateTime?> verificationRequestedAt = const Value.absent(),
                Value<DateTime?> verificationDeadlineAt = const Value.absent(),
                Value<int> verificationTimeoutPolicy = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> shopNumber = const Value.absent(),
                Value<String> netBalance = const Value.absent(),
                Value<String> creditLimit = const Value.absent(),
                Value<int> loyaltyPoints = const Value.absent(),
                required DateTime lastTransactionDate,
                Value<String?> linkedUserUid = const Value.absent(),
                Value<String?> verificationMethod = const Value.absent(),
                Value<bool> isRetailer = const Value.absent(),
                Value<bool> isWholesaler = const Value.absent(),
                Value<bool> isBroker = const Value.absent(),
                Value<bool> isSupplier = const Value.absent(),
                Value<bool> isImporter = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion.insert(
                id: id,
                name: name,
                role: role,
                verificationStatus: verificationStatus,
                verificationRequestedAt: verificationRequestedAt,
                verificationDeadlineAt: verificationDeadlineAt,
                verificationTimeoutPolicy: verificationTimeoutPolicy,
                phoneNumber: phoneNumber,
                shopNumber: shopNumber,
                netBalance: netBalance,
                creditLimit: creditLimit,
                loyaltyPoints: loyaltyPoints,
                lastTransactionDate: lastTransactionDate,
                linkedUserUid: linkedUserUid,
                verificationMethod: verificationMethod,
                isRetailer: isRetailer,
                isWholesaler: isWholesaler,
                isBroker: isBroker,
                isSupplier: isSupplier,
                isImporter: isImporter,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      Contact,
                      $ContactsTable,
                      Transaction
                    >(
                      currentTable: table,
                      referencedTable: $$ContactsTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ContactsTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.contactId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, $$ContactsTableReferences),
      Contact,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$ExpenseCategoriesTableCreateCompanionBuilder =
    ExpenseCategoriesCompanion Function({
      required String id,
      required String name,
      Value<String> colorHex,
      Value<String?> notes,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ExpenseCategoriesTableUpdateCompanionBuilder =
    ExpenseCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> colorHex,
      Value<String?> notes,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ExpenseCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExpenseCategoriesTable,
          ExpenseCategory
        > {
  $$ExpenseCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(
      db.expenseCategories.id,
      db.expenses.categoryId,
    ),
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExpenseCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpenseCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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
}

class $$ExpenseCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpenseCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseCategoriesTable,
          ExpenseCategory,
          $$ExpenseCategoriesTableFilterComposer,
          $$ExpenseCategoriesTableOrderingComposer,
          $$ExpenseCategoriesTableAnnotationComposer,
          $$ExpenseCategoriesTableCreateCompanionBuilder,
          $$ExpenseCategoriesTableUpdateCompanionBuilder,
          (ExpenseCategory, $$ExpenseCategoriesTableReferences),
          ExpenseCategory,
          PrefetchHooks Function({bool expensesRefs})
        > {
  $$ExpenseCategoriesTableTableManager(
    _$AppDatabase db,
    $ExpenseCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseCategoriesCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> colorHex = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseCategoriesCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpenseCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expensesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (expensesRefs) db.expenses],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (expensesRefs)
                    await $_getPrefetchedData<
                      ExpenseCategory,
                      $ExpenseCategoriesTable,
                      Expense
                    >(
                      currentTable: table,
                      referencedTable: $$ExpenseCategoriesTableReferences
                          ._expensesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ExpenseCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).expensesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ExpenseCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseCategoriesTable,
      ExpenseCategory,
      $$ExpenseCategoriesTableFilterComposer,
      $$ExpenseCategoriesTableOrderingComposer,
      $$ExpenseCategoriesTableAnnotationComposer,
      $$ExpenseCategoriesTableCreateCompanionBuilder,
      $$ExpenseCategoriesTableUpdateCompanionBuilder,
      (ExpenseCategory, $$ExpenseCategoriesTableReferences),
      ExpenseCategory,
      PrefetchHooks Function({bool expensesRefs})
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String id,
      required String categoryId,
      required String title,
      Value<String?> vendor,
      required String amount,
      required DateTime spentAt,
      Value<String> paymentMethod,
      Value<String?> description,
      Value<String?> receiptPath,
      Value<bool> isRecurring,
      Value<int?> recurrenceDays,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> id,
      Value<String> categoryId,
      Value<String> title,
      Value<String?> vendor,
      Value<String> amount,
      Value<DateTime> spentAt,
      Value<String> paymentMethod,
      Value<String?> description,
      Value<String?> receiptPath,
      Value<bool> isRecurring,
      Value<int?> recurrenceDays,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExpenseCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.expenseCategories.createAlias(
        $_aliasNameGenerator(db.expenses.categoryId, db.expenseCategories.id),
      );

  $$ExpenseCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$ExpenseCategoriesTableTableManager(
      $_db,
      $_db.expenseCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceDays => $composableBuilder(
    column: $table.recurrenceDays,
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

  $$ExpenseCategoriesTableFilterComposer get categoryId {
    final $$ExpenseCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.expenseCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.expenseCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceDays => $composableBuilder(
    column: $table.recurrenceDays,
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

  $$ExpenseCategoriesTableOrderingComposer get categoryId {
    final $$ExpenseCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.expenseCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.expenseCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get spentAt =>
      $composableBuilder(column: $table.spentAt, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceDays => $composableBuilder(
    column: $table.recurrenceDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ExpenseCategoriesTableAnnotationComposer get categoryId {
    final $$ExpenseCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.expenseCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExpenseCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.expenseCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({bool categoryId})
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                Value<String> amount = const Value.absent(),
                Value<DateTime> spentAt = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> receiptPath = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<int?> recurrenceDays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                categoryId: categoryId,
                title: title,
                vendor: vendor,
                amount: amount,
                spentAt: spentAt,
                paymentMethod: paymentMethod,
                description: description,
                receiptPath: receiptPath,
                isRecurring: isRecurring,
                recurrenceDays: recurrenceDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required String title,
                Value<String?> vendor = const Value.absent(),
                required String amount,
                required DateTime spentAt,
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> receiptPath = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<int?> recurrenceDays = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                categoryId: categoryId,
                title: title,
                vendor: vendor,
                amount: amount,
                spentAt: spentAt,
                paymentMethod: paymentMethod,
                description: description,
                receiptPath: receiptPath,
                isRecurring: isRecurring,
                recurrenceDays: recurrenceDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$ExpensesTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$ExpensesTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String name,
      Value<String?> sku,
      Value<String?> barcode,
      Value<String?> category,
      Value<String?> brand,
      Value<String?> photoUrl,
      Value<String> unit,
      Value<int?> itemsPerCarton,
      Value<String?> itemNumber,
      Value<int?> sizeFrom,
      Value<int?> sizeTo,
      Value<int> seriesSize,
      Value<String?> colorDistribution,
      Value<String?> containerRef,
      Value<String?> supplierContactId,
      Value<String> businessRole,
      Value<String> costPrice,
      Value<String> sellingPrice,
      Value<int> stockQuantity,
      Value<int> reorderLevel,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> sku,
      Value<String?> barcode,
      Value<String?> category,
      Value<String?> brand,
      Value<String?> photoUrl,
      Value<String> unit,
      Value<int?> itemsPerCarton,
      Value<String?> itemNumber,
      Value<int?> sizeFrom,
      Value<int?> sizeTo,
      Value<int> seriesSize,
      Value<String?> colorDistribution,
      Value<String?> containerRef,
      Value<String?> supplierContactId,
      Value<String> businessRole,
      Value<String> costPrice,
      Value<String> sellingPrice,
      Value<int> stockQuantity,
      Value<int> reorderLevel,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $PurchaseOrderLineItemsTable,
    List<PurchaseOrderLineItem>
  >
  _purchaseOrderLineItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.purchaseOrderLineItems,
        aliasName: $_aliasNameGenerator(
          db.products.id,
          db.purchaseOrderLineItems.productId,
        ),
      );

  $$PurchaseOrderLineItemsTableProcessedTableManager
  get purchaseOrderLineItemsRefs {
    final manager = $$PurchaseOrderLineItemsTableTableManager(
      $_db,
      $_db.purchaseOrderLineItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _purchaseOrderLineItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SaleLineItemsTable, List<SaleLineItem>>
  _saleLineItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleLineItems,
    aliasName: $_aliasNameGenerator(db.products.id, db.saleLineItems.productId),
  );

  $$SaleLineItemsTableProcessedTableManager get saleLineItemsRefs {
    final manager = $$SaleLineItemsTableTableManager(
      $_db,
      $_db.saleLineItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleLineItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
  _stockMovementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stockMovements,
    aliasName: $_aliasNameGenerator(
      db.products.id,
      db.stockMovements.productId,
    ),
  );

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager(
      $_db,
      $_db.stockMovements,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemNumber => $composableBuilder(
    column: $table.itemNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeFrom => $composableBuilder(
    column: $table.sizeFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeTo => $composableBuilder(
    column: $table.sizeTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesSize => $composableBuilder(
    column: $table.seriesSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorDistribution => $composableBuilder(
    column: $table.colorDistribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerRef => $composableBuilder(
    column: $table.containerRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierContactId => $composableBuilder(
    column: $table.supplierContactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessRole => $composableBuilder(
    column: $table.businessRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> purchaseOrderLineItemsRefs(
    Expression<bool> Function($$PurchaseOrderLineItemsTableFilterComposer f) f,
  ) {
    final $$PurchaseOrderLineItemsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.purchaseOrderLineItems,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PurchaseOrderLineItemsTableFilterComposer(
                $db: $db,
                $table: $db.purchaseOrderLineItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> saleLineItemsRefs(
    Expression<bool> Function($$SaleLineItemsTableFilterComposer f) f,
  ) {
    final $$SaleLineItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleLineItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleLineItemsTableFilterComposer(
            $db: $db,
            $table: $db.saleLineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stockMovementsRefs(
    Expression<bool> Function($$StockMovementsTableFilterComposer f) f,
  ) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMovements,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMovementsTableFilterComposer(
            $db: $db,
            $table: $db.stockMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemNumber => $composableBuilder(
    column: $table.itemNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeFrom => $composableBuilder(
    column: $table.sizeFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeTo => $composableBuilder(
    column: $table.sizeTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesSize => $composableBuilder(
    column: $table.seriesSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorDistribution => $composableBuilder(
    column: $table.colorDistribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerRef => $composableBuilder(
    column: $table.containerRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierContactId => $composableBuilder(
    column: $table.supplierContactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessRole => $composableBuilder(
    column: $table.businessRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemNumber => $composableBuilder(
    column: $table.itemNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeFrom =>
      $composableBuilder(column: $table.sizeFrom, builder: (column) => column);

  GeneratedColumn<int> get sizeTo =>
      $composableBuilder(column: $table.sizeTo, builder: (column) => column);

  GeneratedColumn<int> get seriesSize => $composableBuilder(
    column: $table.seriesSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorDistribution => $composableBuilder(
    column: $table.colorDistribution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerRef => $composableBuilder(
    column: $table.containerRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplierContactId => $composableBuilder(
    column: $table.supplierContactId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessRole => $composableBuilder(
    column: $table.businessRole,
    builder: (column) => column,
  );

  GeneratedColumn<String> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<String> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> purchaseOrderLineItemsRefs<T extends Object>(
    Expression<T> Function($$PurchaseOrderLineItemsTableAnnotationComposer a) f,
  ) {
    final $$PurchaseOrderLineItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.purchaseOrderLineItems,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PurchaseOrderLineItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.purchaseOrderLineItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> saleLineItemsRefs<T extends Object>(
    Expression<T> Function($$SaleLineItemsTableAnnotationComposer a) f,
  ) {
    final $$SaleLineItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleLineItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleLineItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.saleLineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stockMovementsRefs<T extends Object>(
    Expression<T> Function($$StockMovementsTableAnnotationComposer a) f,
  ) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMovements,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.stockMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({
            bool purchaseOrderLineItemsRefs,
            bool saleLineItemsRefs,
            bool stockMovementsRefs,
          })
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int?> itemsPerCarton = const Value.absent(),
                Value<String?> itemNumber = const Value.absent(),
                Value<int?> sizeFrom = const Value.absent(),
                Value<int?> sizeTo = const Value.absent(),
                Value<int> seriesSize = const Value.absent(),
                Value<String?> colorDistribution = const Value.absent(),
                Value<String?> containerRef = const Value.absent(),
                Value<String?> supplierContactId = const Value.absent(),
                Value<String> businessRole = const Value.absent(),
                Value<String> costPrice = const Value.absent(),
                Value<String> sellingPrice = const Value.absent(),
                Value<int> stockQuantity = const Value.absent(),
                Value<int> reorderLevel = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                sku: sku,
                barcode: barcode,
                category: category,
                brand: brand,
                photoUrl: photoUrl,
                unit: unit,
                itemsPerCarton: itemsPerCarton,
                itemNumber: itemNumber,
                sizeFrom: sizeFrom,
                sizeTo: sizeTo,
                seriesSize: seriesSize,
                colorDistribution: colorDistribution,
                containerRef: containerRef,
                supplierContactId: supplierContactId,
                businessRole: businessRole,
                costPrice: costPrice,
                sellingPrice: sellingPrice,
                stockQuantity: stockQuantity,
                reorderLevel: reorderLevel,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int?> itemsPerCarton = const Value.absent(),
                Value<String?> itemNumber = const Value.absent(),
                Value<int?> sizeFrom = const Value.absent(),
                Value<int?> sizeTo = const Value.absent(),
                Value<int> seriesSize = const Value.absent(),
                Value<String?> colorDistribution = const Value.absent(),
                Value<String?> containerRef = const Value.absent(),
                Value<String?> supplierContactId = const Value.absent(),
                Value<String> businessRole = const Value.absent(),
                Value<String> costPrice = const Value.absent(),
                Value<String> sellingPrice = const Value.absent(),
                Value<int> stockQuantity = const Value.absent(),
                Value<int> reorderLevel = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                sku: sku,
                barcode: barcode,
                category: category,
                brand: brand,
                photoUrl: photoUrl,
                unit: unit,
                itemsPerCarton: itemsPerCarton,
                itemNumber: itemNumber,
                sizeFrom: sizeFrom,
                sizeTo: sizeTo,
                seriesSize: seriesSize,
                colorDistribution: colorDistribution,
                containerRef: containerRef,
                supplierContactId: supplierContactId,
                businessRole: businessRole,
                costPrice: costPrice,
                sellingPrice: sellingPrice,
                stockQuantity: stockQuantity,
                reorderLevel: reorderLevel,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                purchaseOrderLineItemsRefs = false,
                saleLineItemsRefs = false,
                stockMovementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (purchaseOrderLineItemsRefs) db.purchaseOrderLineItems,
                    if (saleLineItemsRefs) db.saleLineItems,
                    if (stockMovementsRefs) db.stockMovements,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (purchaseOrderLineItemsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          PurchaseOrderLineItem
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._purchaseOrderLineItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).purchaseOrderLineItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (saleLineItemsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          SaleLineItem
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._saleLineItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).saleLineItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stockMovementsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          StockMovement
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._stockMovementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).stockMovementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({
        bool purchaseOrderLineItemsRefs,
        bool saleLineItemsRefs,
        bool stockMovementsRefs,
      })
    >;
typedef $$PromotionsTableCreateCompanionBuilder =
    PromotionsCompanion Function({
      required String id,
      required String code,
      required String title,
      Value<String?> description,
      Value<String> discountType,
      required String discountValue,
      Value<String> minOrderTotal,
      Value<String?> maxDiscountAmount,
      Value<DateTime?> startsAt,
      Value<DateTime?> endsAt,
      Value<bool> isActive,
      Value<int?> usageLimit,
      Value<int> usedCount,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PromotionsTableUpdateCompanionBuilder =
    PromotionsCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> title,
      Value<String?> description,
      Value<String> discountType,
      Value<String> discountValue,
      Value<String> minOrderTotal,
      Value<String?> maxDiscountAmount,
      Value<DateTime?> startsAt,
      Value<DateTime?> endsAt,
      Value<bool> isActive,
      Value<int?> usageLimit,
      Value<int> usedCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PromotionsTableReferences
    extends BaseReferences<_$AppDatabase, $PromotionsTable, Promotion> {
  $$PromotionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $PromotionRedemptionsTable,
    List<PromotionRedemption>
  >
  _promotionRedemptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.promotionRedemptions,
        aliasName: $_aliasNameGenerator(
          db.promotions.id,
          db.promotionRedemptions.promotionId,
        ),
      );

  $$PromotionRedemptionsTableProcessedTableManager
  get promotionRedemptionsRefs {
    final manager = $$PromotionRedemptionsTableTableManager(
      $_db,
      $_db.promotionRedemptions,
    ).filter((f) => f.promotionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _promotionRedemptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PromotionsTableFilterComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get minOrderTotal => $composableBuilder(
    column: $table.minOrderTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maxDiscountAmount => $composableBuilder(
    column: $table.maxDiscountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usageLimit => $composableBuilder(
    column: $table.usageLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedCount => $composableBuilder(
    column: $table.usedCount,
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

  Expression<bool> promotionRedemptionsRefs(
    Expression<bool> Function($$PromotionRedemptionsTableFilterComposer f) f,
  ) {
    final $$PromotionRedemptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.promotionRedemptions,
      getReferencedColumn: (t) => t.promotionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromotionRedemptionsTableFilterComposer(
            $db: $db,
            $table: $db.promotionRedemptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PromotionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get minOrderTotal => $composableBuilder(
    column: $table.minOrderTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maxDiscountAmount => $composableBuilder(
    column: $table.maxDiscountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usageLimit => $composableBuilder(
    column: $table.usageLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedCount => $composableBuilder(
    column: $table.usedCount,
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
}

class $$PromotionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get minOrderTotal => $composableBuilder(
    column: $table.minOrderTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get maxDiscountAmount => $composableBuilder(
    column: $table.maxDiscountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get usageLimit => $composableBuilder(
    column: $table.usageLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usedCount =>
      $composableBuilder(column: $table.usedCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> promotionRedemptionsRefs<T extends Object>(
    Expression<T> Function($$PromotionRedemptionsTableAnnotationComposer a) f,
  ) {
    final $$PromotionRedemptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.promotionRedemptions,
          getReferencedColumn: (t) => t.promotionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PromotionRedemptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.promotionRedemptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PromotionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromotionsTable,
          Promotion,
          $$PromotionsTableFilterComposer,
          $$PromotionsTableOrderingComposer,
          $$PromotionsTableAnnotationComposer,
          $$PromotionsTableCreateCompanionBuilder,
          $$PromotionsTableUpdateCompanionBuilder,
          (Promotion, $$PromotionsTableReferences),
          Promotion,
          PrefetchHooks Function({bool promotionRedemptionsRefs})
        > {
  $$PromotionsTableTableManager(_$AppDatabase db, $PromotionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromotionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromotionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromotionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                Value<String> discountValue = const Value.absent(),
                Value<String> minOrderTotal = const Value.absent(),
                Value<String?> maxDiscountAmount = const Value.absent(),
                Value<DateTime?> startsAt = const Value.absent(),
                Value<DateTime?> endsAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int?> usageLimit = const Value.absent(),
                Value<int> usedCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromotionsCompanion(
                id: id,
                code: code,
                title: title,
                description: description,
                discountType: discountType,
                discountValue: discountValue,
                minOrderTotal: minOrderTotal,
                maxDiscountAmount: maxDiscountAmount,
                startsAt: startsAt,
                endsAt: endsAt,
                isActive: isActive,
                usageLimit: usageLimit,
                usedCount: usedCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                required String discountValue,
                Value<String> minOrderTotal = const Value.absent(),
                Value<String?> maxDiscountAmount = const Value.absent(),
                Value<DateTime?> startsAt = const Value.absent(),
                Value<DateTime?> endsAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int?> usageLimit = const Value.absent(),
                Value<int> usedCount = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PromotionsCompanion.insert(
                id: id,
                code: code,
                title: title,
                description: description,
                discountType: discountType,
                discountValue: discountValue,
                minOrderTotal: minOrderTotal,
                maxDiscountAmount: maxDiscountAmount,
                startsAt: startsAt,
                endsAt: endsAt,
                isActive: isActive,
                usageLimit: usageLimit,
                usedCount: usedCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PromotionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({promotionRedemptionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (promotionRedemptionsRefs) db.promotionRedemptions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (promotionRedemptionsRefs)
                    await $_getPrefetchedData<
                      Promotion,
                      $PromotionsTable,
                      PromotionRedemption
                    >(
                      currentTable: table,
                      referencedTable: $$PromotionsTableReferences
                          ._promotionRedemptionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PromotionsTableReferences(
                            db,
                            table,
                            p0,
                          ).promotionRedemptionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.promotionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PromotionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromotionsTable,
      Promotion,
      $$PromotionsTableFilterComposer,
      $$PromotionsTableOrderingComposer,
      $$PromotionsTableAnnotationComposer,
      $$PromotionsTableCreateCompanionBuilder,
      $$PromotionsTableUpdateCompanionBuilder,
      (Promotion, $$PromotionsTableReferences),
      Promotion,
      PrefetchHooks Function({bool promotionRedemptionsRefs})
    >;
typedef $$SalesTableCreateCompanionBuilder =
    SalesCompanion Function({
      required String id,
      Value<String?> customerName,
      Value<String?> contactId,
      required String subtotal,
      Value<String> discount,
      Value<String> tax,
      required String total,
      Value<String> paidAmount,
      Value<String> paymentMethod,
      Value<String> status,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SalesTableUpdateCompanionBuilder =
    SalesCompanion Function({
      Value<String> id,
      Value<String?> customerName,
      Value<String?> contactId,
      Value<String> subtotal,
      Value<String> discount,
      Value<String> tax,
      Value<String> total,
      Value<String> paidAmount,
      Value<String> paymentMethod,
      Value<String> status,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SalesTableReferences
    extends BaseReferences<_$AppDatabase, $SalesTable, Sale> {
  $$SalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $PromotionRedemptionsTable,
    List<PromotionRedemption>
  >
  _promotionRedemptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.promotionRedemptions,
        aliasName: $_aliasNameGenerator(
          db.sales.id,
          db.promotionRedemptions.saleId,
        ),
      );

  $$PromotionRedemptionsTableProcessedTableManager
  get promotionRedemptionsRefs {
    final manager = $$PromotionRedemptionsTableTableManager(
      $_db,
      $_db.promotionRedemptions,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _promotionRedemptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SaleLineItemsTable, List<SaleLineItem>>
  _saleLineItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleLineItems,
    aliasName: $_aliasNameGenerator(db.sales.id, db.saleLineItems.saleId),
  );

  $$SaleLineItemsTableProcessedTableManager get saleLineItemsRefs {
    final manager = $$SaleLineItemsTableTableManager(
      $_db,
      $_db.saleLineItems,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleLineItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
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

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> promotionRedemptionsRefs(
    Expression<bool> Function($$PromotionRedemptionsTableFilterComposer f) f,
  ) {
    final $$PromotionRedemptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.promotionRedemptions,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromotionRedemptionsTableFilterComposer(
            $db: $db,
            $table: $db.promotionRedemptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> saleLineItemsRefs(
    Expression<bool> Function($$SaleLineItemsTableFilterComposer f) f,
  ) {
    final $$SaleLineItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleLineItems,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleLineItemsTableFilterComposer(
            $db: $db,
            $table: $db.saleLineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
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

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<String> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<String> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<String> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<String> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> promotionRedemptionsRefs<T extends Object>(
    Expression<T> Function($$PromotionRedemptionsTableAnnotationComposer a) f,
  ) {
    final $$PromotionRedemptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.promotionRedemptions,
          getReferencedColumn: (t) => t.saleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PromotionRedemptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.promotionRedemptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> saleLineItemsRefs<T extends Object>(
    Expression<T> Function($$SaleLineItemsTableAnnotationComposer a) f,
  ) {
    final $$SaleLineItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleLineItems,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleLineItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.saleLineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTable,
          Sale,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (Sale, $$SalesTableReferences),
          Sale,
          PrefetchHooks Function({
            bool promotionRedemptionsRefs,
            bool saleLineItemsRefs,
          })
        > {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<String> subtotal = const Value.absent(),
                Value<String> discount = const Value.absent(),
                Value<String> tax = const Value.absent(),
                Value<String> total = const Value.absent(),
                Value<String> paidAmount = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion(
                id: id,
                customerName: customerName,
                contactId: contactId,
                subtotal: subtotal,
                discount: discount,
                tax: tax,
                total: total,
                paidAmount: paidAmount,
                paymentMethod: paymentMethod,
                status: status,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> customerName = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                required String subtotal,
                Value<String> discount = const Value.absent(),
                Value<String> tax = const Value.absent(),
                required String total,
                Value<String> paidAmount = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion.insert(
                id: id,
                customerName: customerName,
                contactId: contactId,
                subtotal: subtotal,
                discount: discount,
                tax: tax,
                total: total,
                paidAmount: paidAmount,
                paymentMethod: paymentMethod,
                status: status,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SalesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({promotionRedemptionsRefs = false, saleLineItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (promotionRedemptionsRefs) db.promotionRedemptions,
                    if (saleLineItemsRefs) db.saleLineItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (promotionRedemptionsRefs)
                        await $_getPrefetchedData<
                          Sale,
                          $SalesTable,
                          PromotionRedemption
                        >(
                          currentTable: table,
                          referencedTable: $$SalesTableReferences
                              ._promotionRedemptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SalesTableReferences(
                                db,
                                table,
                                p0,
                              ).promotionRedemptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (saleLineItemsRefs)
                        await $_getPrefetchedData<
                          Sale,
                          $SalesTable,
                          SaleLineItem
                        >(
                          currentTable: table,
                          referencedTable: $$SalesTableReferences
                              ._saleLineItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SalesTableReferences(
                                db,
                                table,
                                p0,
                              ).saleLineItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTable,
      Sale,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (Sale, $$SalesTableReferences),
      Sale,
      PrefetchHooks Function({
        bool promotionRedemptionsRefs,
        bool saleLineItemsRefs,
      })
    >;
typedef $$PromotionRedemptionsTableCreateCompanionBuilder =
    PromotionRedemptionsCompanion Function({
      required String id,
      required String promotionId,
      required String saleId,
      required String codeSnapshot,
      required String discountApplied,
      required String subtotal,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PromotionRedemptionsTableUpdateCompanionBuilder =
    PromotionRedemptionsCompanion Function({
      Value<String> id,
      Value<String> promotionId,
      Value<String> saleId,
      Value<String> codeSnapshot,
      Value<String> discountApplied,
      Value<String> subtotal,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PromotionRedemptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PromotionRedemptionsTable,
          PromotionRedemption
        > {
  $$PromotionRedemptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PromotionsTable _promotionIdTable(_$AppDatabase db) =>
      db.promotions.createAlias(
        $_aliasNameGenerator(
          db.promotionRedemptions.promotionId,
          db.promotions.id,
        ),
      );

  $$PromotionsTableProcessedTableManager get promotionId {
    final $_column = $_itemColumn<String>('promotion_id')!;

    final manager = $$PromotionsTableTableManager(
      $_db,
      $_db.promotions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_promotionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SalesTable _saleIdTable(_$AppDatabase db) => db.sales.createAlias(
    $_aliasNameGenerator(db.promotionRedemptions.saleId, db.sales.id),
  );

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<String>('sale_id')!;

    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PromotionRedemptionsTableFilterComposer
    extends Composer<_$AppDatabase, $PromotionRedemptionsTable> {
  $$PromotionRedemptionsTableFilterComposer({
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

  ColumnFilters<String> get codeSnapshot => $composableBuilder(
    column: $table.codeSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountApplied => $composableBuilder(
    column: $table.discountApplied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PromotionsTableFilterComposer get promotionId {
    final $$PromotionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promotionId,
      referencedTable: $db.promotions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromotionsTableFilterComposer(
            $db: $db,
            $table: $db.promotions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromotionRedemptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromotionRedemptionsTable> {
  $$PromotionRedemptionsTableOrderingComposer({
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

  ColumnOrderings<String> get codeSnapshot => $composableBuilder(
    column: $table.codeSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountApplied => $composableBuilder(
    column: $table.discountApplied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PromotionsTableOrderingComposer get promotionId {
    final $$PromotionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promotionId,
      referencedTable: $db.promotions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromotionsTableOrderingComposer(
            $db: $db,
            $table: $db.promotions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableOrderingComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromotionRedemptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromotionRedemptionsTable> {
  $$PromotionRedemptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get codeSnapshot => $composableBuilder(
    column: $table.codeSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountApplied => $composableBuilder(
    column: $table.discountApplied,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PromotionsTableAnnotationComposer get promotionId {
    final $$PromotionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promotionId,
      referencedTable: $db.promotions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromotionsTableAnnotationComposer(
            $db: $db,
            $table: $db.promotions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromotionRedemptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromotionRedemptionsTable,
          PromotionRedemption,
          $$PromotionRedemptionsTableFilterComposer,
          $$PromotionRedemptionsTableOrderingComposer,
          $$PromotionRedemptionsTableAnnotationComposer,
          $$PromotionRedemptionsTableCreateCompanionBuilder,
          $$PromotionRedemptionsTableUpdateCompanionBuilder,
          (PromotionRedemption, $$PromotionRedemptionsTableReferences),
          PromotionRedemption,
          PrefetchHooks Function({bool promotionId, bool saleId})
        > {
  $$PromotionRedemptionsTableTableManager(
    _$AppDatabase db,
    $PromotionRedemptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromotionRedemptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromotionRedemptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PromotionRedemptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> promotionId = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> codeSnapshot = const Value.absent(),
                Value<String> discountApplied = const Value.absent(),
                Value<String> subtotal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromotionRedemptionsCompanion(
                id: id,
                promotionId: promotionId,
                saleId: saleId,
                codeSnapshot: codeSnapshot,
                discountApplied: discountApplied,
                subtotal: subtotal,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String promotionId,
                required String saleId,
                required String codeSnapshot,
                required String discountApplied,
                required String subtotal,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PromotionRedemptionsCompanion.insert(
                id: id,
                promotionId: promotionId,
                saleId: saleId,
                codeSnapshot: codeSnapshot,
                discountApplied: discountApplied,
                subtotal: subtotal,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PromotionRedemptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({promotionId = false, saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (promotionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.promotionId,
                                referencedTable:
                                    $$PromotionRedemptionsTableReferences
                                        ._promotionIdTable(db),
                                referencedColumn:
                                    $$PromotionRedemptionsTableReferences
                                        ._promotionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (saleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleId,
                                referencedTable:
                                    $$PromotionRedemptionsTableReferences
                                        ._saleIdTable(db),
                                referencedColumn:
                                    $$PromotionRedemptionsTableReferences
                                        ._saleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PromotionRedemptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromotionRedemptionsTable,
      PromotionRedemption,
      $$PromotionRedemptionsTableFilterComposer,
      $$PromotionRedemptionsTableOrderingComposer,
      $$PromotionRedemptionsTableAnnotationComposer,
      $$PromotionRedemptionsTableCreateCompanionBuilder,
      $$PromotionRedemptionsTableUpdateCompanionBuilder,
      (PromotionRedemption, $$PromotionRedemptionsTableReferences),
      PromotionRedemption,
      PrefetchHooks Function({bool promotionId, bool saleId})
    >;
typedef $$SuppliersTableCreateCompanionBuilder =
    SuppliersCompanion Function({
      required String id,
      required String name,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<int> termsDays,
      Value<String> openingBalance,
      Value<String> currentBalance,
      Value<String?> notes,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SuppliersTableUpdateCompanionBuilder =
    SuppliersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<int> termsDays,
      Value<String> openingBalance,
      Value<String> currentBalance,
      Value<String?> notes,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SuppliersTableReferences
    extends BaseReferences<_$AppDatabase, $SuppliersTable, Supplier> {
  $$SuppliersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PurchaseOrdersTable, List<PurchaseOrder>>
  _purchaseOrdersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.purchaseOrders,
    aliasName: $_aliasNameGenerator(
      db.suppliers.id,
      db.purchaseOrders.supplierId,
    ),
  );

  $$PurchaseOrdersTableProcessedTableManager get purchaseOrdersRefs {
    final manager = $$PurchaseOrdersTableTableManager(
      $_db,
      $_db.purchaseOrders,
    ).filter((f) => f.supplierId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchaseOrdersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SuppliersTableFilterComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get termsDays => $composableBuilder(
    column: $table.termsDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  Expression<bool> purchaseOrdersRefs(
    Expression<bool> Function($$PurchaseOrdersTableFilterComposer f) f,
  ) {
    final $$PurchaseOrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseOrdersTableFilterComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SuppliersTableOrderingComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get termsDays => $composableBuilder(
    column: $table.termsDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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
}

class $$SuppliersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get termsDays =>
      $composableBuilder(column: $table.termsDays, builder: (column) => column);

  GeneratedColumn<String> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> purchaseOrdersRefs<T extends Object>(
    Expression<T> Function($$PurchaseOrdersTableAnnotationComposer a) f,
  ) {
    final $$PurchaseOrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseOrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SuppliersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuppliersTable,
          Supplier,
          $$SuppliersTableFilterComposer,
          $$SuppliersTableOrderingComposer,
          $$SuppliersTableAnnotationComposer,
          $$SuppliersTableCreateCompanionBuilder,
          $$SuppliersTableUpdateCompanionBuilder,
          (Supplier, $$SuppliersTableReferences),
          Supplier,
          PrefetchHooks Function({bool purchaseOrdersRefs})
        > {
  $$SuppliersTableTableManager(_$AppDatabase db, $SuppliersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuppliersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuppliersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuppliersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<int> termsDays = const Value.absent(),
                Value<String> openingBalance = const Value.absent(),
                Value<String> currentBalance = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuppliersCompanion(
                id: id,
                name: name,
                phone: phone,
                email: email,
                address: address,
                termsDays: termsDays,
                openingBalance: openingBalance,
                currentBalance: currentBalance,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<int> termsDays = const Value.absent(),
                Value<String> openingBalance = const Value.absent(),
                Value<String> currentBalance = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SuppliersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                email: email,
                address: address,
                termsDays: termsDays,
                openingBalance: openingBalance,
                currentBalance: currentBalance,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SuppliersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({purchaseOrdersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (purchaseOrdersRefs) db.purchaseOrders,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (purchaseOrdersRefs)
                    await $_getPrefetchedData<
                      Supplier,
                      $SuppliersTable,
                      PurchaseOrder
                    >(
                      currentTable: table,
                      referencedTable: $$SuppliersTableReferences
                          ._purchaseOrdersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SuppliersTableReferences(
                            db,
                            table,
                            p0,
                          ).purchaseOrdersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.supplierId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SuppliersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuppliersTable,
      Supplier,
      $$SuppliersTableFilterComposer,
      $$SuppliersTableOrderingComposer,
      $$SuppliersTableAnnotationComposer,
      $$SuppliersTableCreateCompanionBuilder,
      $$SuppliersTableUpdateCompanionBuilder,
      (Supplier, $$SuppliersTableReferences),
      Supplier,
      PrefetchHooks Function({bool purchaseOrdersRefs})
    >;
typedef $$PurchaseOrdersTableCreateCompanionBuilder =
    PurchaseOrdersCompanion Function({
      required String id,
      required String supplierId,
      Value<int> status,
      Value<String> subtotal,
      required DateTime orderDate,
      Value<DateTime?> dueDate,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PurchaseOrdersTableUpdateCompanionBuilder =
    PurchaseOrdersCompanion Function({
      Value<String> id,
      Value<String> supplierId,
      Value<int> status,
      Value<String> subtotal,
      Value<DateTime> orderDate,
      Value<DateTime?> dueDate,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PurchaseOrdersTableReferences
    extends BaseReferences<_$AppDatabase, $PurchaseOrdersTable, PurchaseOrder> {
  $$PurchaseOrdersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SuppliersTable _supplierIdTable(_$AppDatabase db) =>
      db.suppliers.createAlias(
        $_aliasNameGenerator(db.purchaseOrders.supplierId, db.suppliers.id),
      );

  $$SuppliersTableProcessedTableManager get supplierId {
    final $_column = $_itemColumn<String>('supplier_id')!;

    final manager = $$SuppliersTableTableManager(
      $_db,
      $_db.suppliers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $PurchaseOrderLineItemsTable,
    List<PurchaseOrderLineItem>
  >
  _purchaseOrderLineItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.purchaseOrderLineItems,
        aliasName: $_aliasNameGenerator(
          db.purchaseOrders.id,
          db.purchaseOrderLineItems.purchaseOrderId,
        ),
      );

  $$PurchaseOrderLineItemsTableProcessedTableManager
  get purchaseOrderLineItemsRefs {
    final manager =
        $$PurchaseOrderLineItemsTableTableManager(
          $_db,
          $_db.purchaseOrderLineItems,
        ).filter(
          (f) => f.purchaseOrderId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _purchaseOrderLineItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PurchaseOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTable> {
  $$PurchaseOrdersTableFilterComposer({
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

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get orderDate => $composableBuilder(
    column: $table.orderDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$SuppliersTableFilterComposer get supplierId {
    final $$SuppliersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableFilterComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> purchaseOrderLineItemsRefs(
    Expression<bool> Function($$PurchaseOrderLineItemsTableFilterComposer f) f,
  ) {
    final $$PurchaseOrderLineItemsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.purchaseOrderLineItems,
          getReferencedColumn: (t) => t.purchaseOrderId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PurchaseOrderLineItemsTableFilterComposer(
                $db: $db,
                $table: $db.purchaseOrderLineItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PurchaseOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTable> {
  $$PurchaseOrdersTableOrderingComposer({
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

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get orderDate => $composableBuilder(
    column: $table.orderDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$SuppliersTableOrderingComposer get supplierId {
    final $$SuppliersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableOrderingComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchaseOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTable> {
  $$PurchaseOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<DateTime> get orderDate =>
      $composableBuilder(column: $table.orderDate, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SuppliersTableAnnotationComposer get supplierId {
    final $$SuppliersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableAnnotationComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> purchaseOrderLineItemsRefs<T extends Object>(
    Expression<T> Function($$PurchaseOrderLineItemsTableAnnotationComposer a) f,
  ) {
    final $$PurchaseOrderLineItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.purchaseOrderLineItems,
          getReferencedColumn: (t) => t.purchaseOrderId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PurchaseOrderLineItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.purchaseOrderLineItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PurchaseOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseOrdersTable,
          PurchaseOrder,
          $$PurchaseOrdersTableFilterComposer,
          $$PurchaseOrdersTableOrderingComposer,
          $$PurchaseOrdersTableAnnotationComposer,
          $$PurchaseOrdersTableCreateCompanionBuilder,
          $$PurchaseOrdersTableUpdateCompanionBuilder,
          (PurchaseOrder, $$PurchaseOrdersTableReferences),
          PurchaseOrder,
          PrefetchHooks Function({
            bool supplierId,
            bool purchaseOrderLineItemsRefs,
          })
        > {
  $$PurchaseOrdersTableTableManager(
    _$AppDatabase db,
    $PurchaseOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchaseOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> supplierId = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> subtotal = const Value.absent(),
                Value<DateTime> orderDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrdersCompanion(
                id: id,
                supplierId: supplierId,
                status: status,
                subtotal: subtotal,
                orderDate: orderDate,
                dueDate: dueDate,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String supplierId,
                Value<int> status = const Value.absent(),
                Value<String> subtotal = const Value.absent(),
                required DateTime orderDate,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrdersCompanion.insert(
                id: id,
                supplierId: supplierId,
                status: status,
                subtotal: subtotal,
                orderDate: orderDate,
                dueDate: dueDate,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PurchaseOrdersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({supplierId = false, purchaseOrderLineItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (purchaseOrderLineItemsRefs) db.purchaseOrderLineItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (supplierId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.supplierId,
                                    referencedTable:
                                        $$PurchaseOrdersTableReferences
                                            ._supplierIdTable(db),
                                    referencedColumn:
                                        $$PurchaseOrdersTableReferences
                                            ._supplierIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (purchaseOrderLineItemsRefs)
                        await $_getPrefetchedData<
                          PurchaseOrder,
                          $PurchaseOrdersTable,
                          PurchaseOrderLineItem
                        >(
                          currentTable: table,
                          referencedTable: $$PurchaseOrdersTableReferences
                              ._purchaseOrderLineItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PurchaseOrdersTableReferences(
                                db,
                                table,
                                p0,
                              ).purchaseOrderLineItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.purchaseOrderId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PurchaseOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseOrdersTable,
      PurchaseOrder,
      $$PurchaseOrdersTableFilterComposer,
      $$PurchaseOrdersTableOrderingComposer,
      $$PurchaseOrdersTableAnnotationComposer,
      $$PurchaseOrdersTableCreateCompanionBuilder,
      $$PurchaseOrdersTableUpdateCompanionBuilder,
      (PurchaseOrder, $$PurchaseOrdersTableReferences),
      PurchaseOrder,
      PrefetchHooks Function({bool supplierId, bool purchaseOrderLineItemsRefs})
    >;
typedef $$PurchaseOrderLineItemsTableCreateCompanionBuilder =
    PurchaseOrderLineItemsCompanion Function({
      required String id,
      required String purchaseOrderId,
      required String productId,
      required String productName,
      Value<String?> sku,
      Value<String?> unit,
      Value<int?> itemsPerCarton,
      required String unitCost,
      required int quantity,
      required String lineTotal,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PurchaseOrderLineItemsTableUpdateCompanionBuilder =
    PurchaseOrderLineItemsCompanion Function({
      Value<String> id,
      Value<String> purchaseOrderId,
      Value<String> productId,
      Value<String> productName,
      Value<String?> sku,
      Value<String?> unit,
      Value<int?> itemsPerCarton,
      Value<String> unitCost,
      Value<int> quantity,
      Value<String> lineTotal,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PurchaseOrderLineItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PurchaseOrderLineItemsTable,
          PurchaseOrderLineItem
        > {
  $$PurchaseOrderLineItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PurchaseOrdersTable _purchaseOrderIdTable(_$AppDatabase db) =>
      db.purchaseOrders.createAlias(
        $_aliasNameGenerator(
          db.purchaseOrderLineItems.purchaseOrderId,
          db.purchaseOrders.id,
        ),
      );

  $$PurchaseOrdersTableProcessedTableManager get purchaseOrderId {
    final $_column = $_itemColumn<String>('purchase_order_id')!;

    final manager = $$PurchaseOrdersTableTableManager(
      $_db,
      $_db.purchaseOrders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_purchaseOrderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(
          db.purchaseOrderLineItems.productId,
          db.products.id,
        ),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PurchaseOrderLineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseOrderLineItemsTable> {
  $$PurchaseOrderLineItemsTableFilterComposer({
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

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PurchaseOrdersTableFilterComposer get purchaseOrderId {
    final $$PurchaseOrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseOrderId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseOrdersTableFilterComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchaseOrderLineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseOrderLineItemsTable> {
  $$PurchaseOrderLineItemsTableOrderingComposer({
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

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PurchaseOrdersTableOrderingComposer get purchaseOrderId {
    final $$PurchaseOrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseOrderId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseOrdersTableOrderingComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchaseOrderLineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseOrderLineItemsTable> {
  $$PurchaseOrderLineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PurchaseOrdersTableAnnotationComposer get purchaseOrderId {
    final $$PurchaseOrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseOrderId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseOrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchaseOrderLineItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseOrderLineItemsTable,
          PurchaseOrderLineItem,
          $$PurchaseOrderLineItemsTableFilterComposer,
          $$PurchaseOrderLineItemsTableOrderingComposer,
          $$PurchaseOrderLineItemsTableAnnotationComposer,
          $$PurchaseOrderLineItemsTableCreateCompanionBuilder,
          $$PurchaseOrderLineItemsTableUpdateCompanionBuilder,
          (PurchaseOrderLineItem, $$PurchaseOrderLineItemsTableReferences),
          PurchaseOrderLineItem,
          PrefetchHooks Function({bool purchaseOrderId, bool productId})
        > {
  $$PurchaseOrderLineItemsTableTableManager(
    _$AppDatabase db,
    $PurchaseOrderLineItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseOrderLineItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PurchaseOrderLineItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PurchaseOrderLineItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> purchaseOrderId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> itemsPerCarton = const Value.absent(),
                Value<String> unitCost = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> lineTotal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrderLineItemsCompanion(
                id: id,
                purchaseOrderId: purchaseOrderId,
                productId: productId,
                productName: productName,
                sku: sku,
                unit: unit,
                itemsPerCarton: itemsPerCarton,
                unitCost: unitCost,
                quantity: quantity,
                lineTotal: lineTotal,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String purchaseOrderId,
                required String productId,
                required String productName,
                Value<String?> sku = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> itemsPerCarton = const Value.absent(),
                required String unitCost,
                required int quantity,
                required String lineTotal,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrderLineItemsCompanion.insert(
                id: id,
                purchaseOrderId: purchaseOrderId,
                productId: productId,
                productName: productName,
                sku: sku,
                unit: unit,
                itemsPerCarton: itemsPerCarton,
                unitCost: unitCost,
                quantity: quantity,
                lineTotal: lineTotal,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PurchaseOrderLineItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({purchaseOrderId = false, productId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (purchaseOrderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.purchaseOrderId,
                                    referencedTable:
                                        $$PurchaseOrderLineItemsTableReferences
                                            ._purchaseOrderIdTable(db),
                                    referencedColumn:
                                        $$PurchaseOrderLineItemsTableReferences
                                            ._purchaseOrderIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (productId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.productId,
                                    referencedTable:
                                        $$PurchaseOrderLineItemsTableReferences
                                            ._productIdTable(db),
                                    referencedColumn:
                                        $$PurchaseOrderLineItemsTableReferences
                                            ._productIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PurchaseOrderLineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseOrderLineItemsTable,
      PurchaseOrderLineItem,
      $$PurchaseOrderLineItemsTableFilterComposer,
      $$PurchaseOrderLineItemsTableOrderingComposer,
      $$PurchaseOrderLineItemsTableAnnotationComposer,
      $$PurchaseOrderLineItemsTableCreateCompanionBuilder,
      $$PurchaseOrderLineItemsTableUpdateCompanionBuilder,
      (PurchaseOrderLineItem, $$PurchaseOrderLineItemsTableReferences),
      PurchaseOrderLineItem,
      PrefetchHooks Function({bool purchaseOrderId, bool productId})
    >;
typedef $$SaleLineItemsTableCreateCompanionBuilder =
    SaleLineItemsCompanion Function({
      required String id,
      required String saleId,
      required String productId,
      required String productName,
      Value<String?> sku,
      Value<String?> unit,
      Value<int?> itemsPerCarton,
      required String unitPrice,
      required int quantity,
      required String lineTotal,
      Value<int> rowid,
    });
typedef $$SaleLineItemsTableUpdateCompanionBuilder =
    SaleLineItemsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String> productId,
      Value<String> productName,
      Value<String?> sku,
      Value<String?> unit,
      Value<int?> itemsPerCarton,
      Value<String> unitPrice,
      Value<int> quantity,
      Value<String> lineTotal,
      Value<int> rowid,
    });

final class $$SaleLineItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SaleLineItemsTable, SaleLineItem> {
  $$SaleLineItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SalesTable _saleIdTable(_$AppDatabase db) => db.sales.createAlias(
    $_aliasNameGenerator(db.saleLineItems.saleId, db.sales.id),
  );

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<String>('sale_id')!;

    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.saleLineItems.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SaleLineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SaleLineItemsTable> {
  $$SaleLineItemsTableFilterComposer({
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

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleLineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleLineItemsTable> {
  $$SaleLineItemsTableOrderingComposer({
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

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableOrderingComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleLineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleLineItemsTable> {
  $$SaleLineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get itemsPerCarton => $composableBuilder(
    column: $table.itemsPerCarton,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleLineItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleLineItemsTable,
          SaleLineItem,
          $$SaleLineItemsTableFilterComposer,
          $$SaleLineItemsTableOrderingComposer,
          $$SaleLineItemsTableAnnotationComposer,
          $$SaleLineItemsTableCreateCompanionBuilder,
          $$SaleLineItemsTableUpdateCompanionBuilder,
          (SaleLineItem, $$SaleLineItemsTableReferences),
          SaleLineItem,
          PrefetchHooks Function({bool saleId, bool productId})
        > {
  $$SaleLineItemsTableTableManager(_$AppDatabase db, $SaleLineItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleLineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleLineItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleLineItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> itemsPerCarton = const Value.absent(),
                Value<String> unitPrice = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> lineTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaleLineItemsCompanion(
                id: id,
                saleId: saleId,
                productId: productId,
                productName: productName,
                sku: sku,
                unit: unit,
                itemsPerCarton: itemsPerCarton,
                unitPrice: unitPrice,
                quantity: quantity,
                lineTotal: lineTotal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                required String productId,
                required String productName,
                Value<String?> sku = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> itemsPerCarton = const Value.absent(),
                required String unitPrice,
                required int quantity,
                required String lineTotal,
                Value<int> rowid = const Value.absent(),
              }) => SaleLineItemsCompanion.insert(
                id: id,
                saleId: saleId,
                productId: productId,
                productName: productName,
                sku: sku,
                unit: unit,
                itemsPerCarton: itemsPerCarton,
                unitPrice: unitPrice,
                quantity: quantity,
                lineTotal: lineTotal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SaleLineItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleId,
                                referencedTable: $$SaleLineItemsTableReferences
                                    ._saleIdTable(db),
                                referencedColumn: $$SaleLineItemsTableReferences
                                    ._saleIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$SaleLineItemsTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$SaleLineItemsTableReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SaleLineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleLineItemsTable,
      SaleLineItem,
      $$SaleLineItemsTableFilterComposer,
      $$SaleLineItemsTableOrderingComposer,
      $$SaleLineItemsTableAnnotationComposer,
      $$SaleLineItemsTableCreateCompanionBuilder,
      $$SaleLineItemsTableUpdateCompanionBuilder,
      (SaleLineItem, $$SaleLineItemsTableReferences),
      SaleLineItem,
      PrefetchHooks Function({bool saleId, bool productId})
    >;
typedef $$StockMovementsTableCreateCompanionBuilder =
    StockMovementsCompanion Function({
      required String id,
      required String productId,
      required String movementType,
      required int quantityChange,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$StockMovementsTableUpdateCompanionBuilder =
    StockMovementsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> movementType,
      Value<int> quantityChange,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$StockMovementsTableReferences
    extends BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovement> {
  $$StockMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.stockMovements.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
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

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityChange => $composableBuilder(
    column: $table.quantityChange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
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

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityChange => $composableBuilder(
    column: $table.quantityChange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityChange => $composableBuilder(
    column: $table.quantityChange,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockMovementsTable,
          StockMovement,
          $$StockMovementsTableFilterComposer,
          $$StockMovementsTableOrderingComposer,
          $$StockMovementsTableAnnotationComposer,
          $$StockMovementsTableCreateCompanionBuilder,
          $$StockMovementsTableUpdateCompanionBuilder,
          (StockMovement, $$StockMovementsTableReferences),
          StockMovement,
          PrefetchHooks Function({bool productId})
        > {
  $$StockMovementsTableTableManager(
    _$AppDatabase db,
    $StockMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<int> quantityChange = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion(
                id: id,
                productId: productId,
                movementType: movementType,
                quantityChange: quantityChange,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String movementType,
                required int quantityChange,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion.insert(
                id: id,
                productId: productId,
                movementType: movementType,
                quantityChange: quantityChange,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StockMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$StockMovementsTableReferences
                                    ._productIdTable(db),
                                referencedColumn:
                                    $$StockMovementsTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StockMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockMovementsTable,
      StockMovement,
      $$StockMovementsTableFilterComposer,
      $$StockMovementsTableOrderingComposer,
      $$StockMovementsTableAnnotationComposer,
      $$StockMovementsTableCreateCompanionBuilder,
      $$StockMovementsTableUpdateCompanionBuilder,
      (StockMovement, $$StockMovementsTableReferences),
      StockMovement,
      PrefetchHooks Function({bool productId})
    >;
typedef $$TeamMembersTableCreateCompanionBuilder =
    TeamMembersCompanion Function({
      required String id,
      required String fullName,
      Value<String?> phoneNumber,
      Value<int> role,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TeamMembersTableUpdateCompanionBuilder =
    TeamMembersCompanion Function({
      Value<String> id,
      Value<String> fullName,
      Value<String?> phoneNumber,
      Value<int> role,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TeamMembersTableFilterComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableFilterComposer({
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

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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
}

class $$TeamMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableOrderingComposer({
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

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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
}

class $$TeamMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TeamMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamMembersTable,
          TeamMember,
          $$TeamMembersTableFilterComposer,
          $$TeamMembersTableOrderingComposer,
          $$TeamMembersTableAnnotationComposer,
          $$TeamMembersTableCreateCompanionBuilder,
          $$TeamMembersTableUpdateCompanionBuilder,
          (
            TeamMember,
            BaseReferences<_$AppDatabase, $TeamMembersTable, TeamMember>,
          ),
          TeamMember,
          PrefetchHooks Function()
        > {
  $$TeamMembersTableTableManager(_$AppDatabase db, $TeamMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<int> role = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamMembersCompanion(
                id: id,
                fullName: fullName,
                phoneNumber: phoneNumber,
                role: role,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fullName,
                Value<String?> phoneNumber = const Value.absent(),
                Value<int> role = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TeamMembersCompanion.insert(
                id: id,
                fullName: fullName,
                phoneNumber: phoneNumber,
                role: role,
                isActive: isActive,
                createdAt: createdAt,
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

typedef $$TeamMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamMembersTable,
      TeamMember,
      $$TeamMembersTableFilterComposer,
      $$TeamMembersTableOrderingComposer,
      $$TeamMembersTableAnnotationComposer,
      $$TeamMembersTableCreateCompanionBuilder,
      $$TeamMembersTableUpdateCompanionBuilder,
      (
        TeamMember,
        BaseReferences<_$AppDatabase, $TeamMembersTable, TeamMember>,
      ),
      TeamMember,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String contactId,
      required int type,
      Value<int> status,
      required String amount,
      required DateTime date,
      Value<String?> description,
      Value<int?> cartons,
      Value<int?> qtyPerCarton,
      Value<String?> unitPrice,
      Value<String?> metadata,
      Value<String?> referenceId,
      Value<String?> saleId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> contactId,
      Value<int> type,
      Value<int> status,
      Value<String> amount,
      Value<DateTime> date,
      Value<String?> description,
      Value<int?> cartons,
      Value<int?> qtyPerCarton,
      Value<String?> unitPrice,
      Value<String?> metadata,
      Value<String?> referenceId,
      Value<String?> saleId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ContactsTable _contactIdTable(_$AppDatabase db) =>
      db.contacts.createAlias(
        $_aliasNameGenerator(db.transactions.contactId, db.contacts.id),
      );

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<String>('contact_id')!;

    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cartons => $composableBuilder(
    column: $table.cartons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyPerCarton => $composableBuilder(
    column: $table.qtyPerCarton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cartons => $composableBuilder(
    column: $table.cartons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyPerCarton => $composableBuilder(
    column: $table.qtyPerCarton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cartons =>
      $composableBuilder(column: $table.cartons, builder: (column) => column);

  GeneratedColumn<int> get qtyPerCarton => $composableBuilder(
    column: $table.qtyPerCarton,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({bool contactId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contactId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> cartons = const Value.absent(),
                Value<int?> qtyPerCarton = const Value.absent(),
                Value<String?> unitPrice = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String?> saleId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                contactId: contactId,
                type: type,
                status: status,
                amount: amount,
                date: date,
                description: description,
                cartons: cartons,
                qtyPerCarton: qtyPerCarton,
                unitPrice: unitPrice,
                metadata: metadata,
                referenceId: referenceId,
                saleId: saleId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contactId,
                required int type,
                Value<int> status = const Value.absent(),
                required String amount,
                required DateTime date,
                Value<String?> description = const Value.absent(),
                Value<int?> cartons = const Value.absent(),
                Value<int?> qtyPerCarton = const Value.absent(),
                Value<String?> unitPrice = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String?> saleId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                contactId: contactId,
                type: type,
                status: status,
                amount: amount,
                date: date,
                description: description,
                cartons: cartons,
                qtyPerCarton: qtyPerCarton,
                unitPrice: unitPrice,
                metadata: metadata,
                referenceId: referenceId,
                saleId: saleId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (contactId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contactId,
                                referencedTable: $$TransactionsTableReferences
                                    ._contactIdTable(db),
                                referencedColumn: $$TransactionsTableReferences
                                    ._contactIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({bool contactId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ExpenseCategoriesTableTableManager get expenseCategories =>
      $$ExpenseCategoriesTableTableManager(_db, _db.expenseCategories);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$PromotionsTableTableManager get promotions =>
      $$PromotionsTableTableManager(_db, _db.promotions);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$PromotionRedemptionsTableTableManager get promotionRedemptions =>
      $$PromotionRedemptionsTableTableManager(_db, _db.promotionRedemptions);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db, _db.suppliers);
  $$PurchaseOrdersTableTableManager get purchaseOrders =>
      $$PurchaseOrdersTableTableManager(_db, _db.purchaseOrders);
  $$PurchaseOrderLineItemsTableTableManager get purchaseOrderLineItems =>
      $$PurchaseOrderLineItemsTableTableManager(
        _db,
        _db.purchaseOrderLineItems,
      );
  $$SaleLineItemsTableTableManager get saleLineItems =>
      $$SaleLineItemsTableTableManager(_db, _db.saleLineItems);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$TeamMembersTableTableManager get teamMembers =>
      $$TeamMembersTableTableManager(_db, _db.teamMembers);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
}
