// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WorkflowTrigger _$WorkflowTriggerFromJson(Map<String, dynamic> json) {
  return _WorkflowTrigger.fromJson(json);
}

/// @nodoc
mixin _$WorkflowTrigger {
  int get id => throw _privateConstructorUsedError;
  int get type => throw _privateConstructorUsedError;
  List<int> get sources => throw _privateConstructorUsedError;
  @JsonKey(name: 'filter_filename')
  String? get filterFilename => throw _privateConstructorUsedError;
  @JsonKey(name: 'filter_path')
  String? get filterPath => throw _privateConstructorUsedError;
  @JsonKey(name: 'filter_mailrule')
  int? get filterMailrule => throw _privateConstructorUsedError;
  @JsonKey(name: 'matching_algorithm')
  int get matchingAlgorithm => throw _privateConstructorUsedError;
  String get match => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_insensitive')
  bool get isInsensitive => throw _privateConstructorUsedError;
  @JsonKey(name: 'filter_has_tags')
  List<int> get filterHasTags => throw _privateConstructorUsedError;
  @JsonKey(name: 'filter_has_correspondent')
  int? get filterHasCorrespondent => throw _privateConstructorUsedError;
  @JsonKey(name: 'filter_has_document_type')
  int? get filterHasDocumentType => throw _privateConstructorUsedError;

  /// Serializes this WorkflowTrigger to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkflowTrigger
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkflowTriggerCopyWith<WorkflowTrigger> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowTriggerCopyWith<$Res> {
  factory $WorkflowTriggerCopyWith(
    WorkflowTrigger value,
    $Res Function(WorkflowTrigger) then,
  ) = _$WorkflowTriggerCopyWithImpl<$Res, WorkflowTrigger>;
  @useResult
  $Res call({
    int id,
    int type,
    List<int> sources,
    @JsonKey(name: 'filter_filename') String? filterFilename,
    @JsonKey(name: 'filter_path') String? filterPath,
    @JsonKey(name: 'filter_mailrule') int? filterMailrule,
    @JsonKey(name: 'matching_algorithm') int matchingAlgorithm,
    String match,
    @JsonKey(name: 'is_insensitive') bool isInsensitive,
    @JsonKey(name: 'filter_has_tags') List<int> filterHasTags,
    @JsonKey(name: 'filter_has_correspondent') int? filterHasCorrespondent,
    @JsonKey(name: 'filter_has_document_type') int? filterHasDocumentType,
  });
}

/// @nodoc
class _$WorkflowTriggerCopyWithImpl<$Res, $Val extends WorkflowTrigger>
    implements $WorkflowTriggerCopyWith<$Res> {
  _$WorkflowTriggerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkflowTrigger
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? sources = null,
    Object? filterFilename = freezed,
    Object? filterPath = freezed,
    Object? filterMailrule = freezed,
    Object? matchingAlgorithm = null,
    Object? match = null,
    Object? isInsensitive = null,
    Object? filterHasTags = null,
    Object? filterHasCorrespondent = freezed,
    Object? filterHasDocumentType = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as int,
            sources: null == sources
                ? _value.sources
                : sources // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            filterFilename: freezed == filterFilename
                ? _value.filterFilename
                : filterFilename // ignore: cast_nullable_to_non_nullable
                      as String?,
            filterPath: freezed == filterPath
                ? _value.filterPath
                : filterPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            filterMailrule: freezed == filterMailrule
                ? _value.filterMailrule
                : filterMailrule // ignore: cast_nullable_to_non_nullable
                      as int?,
            matchingAlgorithm: null == matchingAlgorithm
                ? _value.matchingAlgorithm
                : matchingAlgorithm // ignore: cast_nullable_to_non_nullable
                      as int,
            match: null == match
                ? _value.match
                : match // ignore: cast_nullable_to_non_nullable
                      as String,
            isInsensitive: null == isInsensitive
                ? _value.isInsensitive
                : isInsensitive // ignore: cast_nullable_to_non_nullable
                      as bool,
            filterHasTags: null == filterHasTags
                ? _value.filterHasTags
                : filterHasTags // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            filterHasCorrespondent: freezed == filterHasCorrespondent
                ? _value.filterHasCorrespondent
                : filterHasCorrespondent // ignore: cast_nullable_to_non_nullable
                      as int?,
            filterHasDocumentType: freezed == filterHasDocumentType
                ? _value.filterHasDocumentType
                : filterHasDocumentType // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkflowTriggerImplCopyWith<$Res>
    implements $WorkflowTriggerCopyWith<$Res> {
  factory _$$WorkflowTriggerImplCopyWith(
    _$WorkflowTriggerImpl value,
    $Res Function(_$WorkflowTriggerImpl) then,
  ) = __$$WorkflowTriggerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int type,
    List<int> sources,
    @JsonKey(name: 'filter_filename') String? filterFilename,
    @JsonKey(name: 'filter_path') String? filterPath,
    @JsonKey(name: 'filter_mailrule') int? filterMailrule,
    @JsonKey(name: 'matching_algorithm') int matchingAlgorithm,
    String match,
    @JsonKey(name: 'is_insensitive') bool isInsensitive,
    @JsonKey(name: 'filter_has_tags') List<int> filterHasTags,
    @JsonKey(name: 'filter_has_correspondent') int? filterHasCorrespondent,
    @JsonKey(name: 'filter_has_document_type') int? filterHasDocumentType,
  });
}

/// @nodoc
class __$$WorkflowTriggerImplCopyWithImpl<$Res>
    extends _$WorkflowTriggerCopyWithImpl<$Res, _$WorkflowTriggerImpl>
    implements _$$WorkflowTriggerImplCopyWith<$Res> {
  __$$WorkflowTriggerImplCopyWithImpl(
    _$WorkflowTriggerImpl _value,
    $Res Function(_$WorkflowTriggerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkflowTrigger
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? sources = null,
    Object? filterFilename = freezed,
    Object? filterPath = freezed,
    Object? filterMailrule = freezed,
    Object? matchingAlgorithm = null,
    Object? match = null,
    Object? isInsensitive = null,
    Object? filterHasTags = null,
    Object? filterHasCorrespondent = freezed,
    Object? filterHasDocumentType = freezed,
  }) {
    return _then(
      _$WorkflowTriggerImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as int,
        sources: null == sources
            ? _value._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        filterFilename: freezed == filterFilename
            ? _value.filterFilename
            : filterFilename // ignore: cast_nullable_to_non_nullable
                  as String?,
        filterPath: freezed == filterPath
            ? _value.filterPath
            : filterPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        filterMailrule: freezed == filterMailrule
            ? _value.filterMailrule
            : filterMailrule // ignore: cast_nullable_to_non_nullable
                  as int?,
        matchingAlgorithm: null == matchingAlgorithm
            ? _value.matchingAlgorithm
            : matchingAlgorithm // ignore: cast_nullable_to_non_nullable
                  as int,
        match: null == match
            ? _value.match
            : match // ignore: cast_nullable_to_non_nullable
                  as String,
        isInsensitive: null == isInsensitive
            ? _value.isInsensitive
            : isInsensitive // ignore: cast_nullable_to_non_nullable
                  as bool,
        filterHasTags: null == filterHasTags
            ? _value._filterHasTags
            : filterHasTags // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        filterHasCorrespondent: freezed == filterHasCorrespondent
            ? _value.filterHasCorrespondent
            : filterHasCorrespondent // ignore: cast_nullable_to_non_nullable
                  as int?,
        filterHasDocumentType: freezed == filterHasDocumentType
            ? _value.filterHasDocumentType
            : filterHasDocumentType // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowTriggerImpl implements _WorkflowTrigger {
  const _$WorkflowTriggerImpl({
    required this.id,
    required this.type,
    final List<int> sources = const [],
    @JsonKey(name: 'filter_filename') this.filterFilename,
    @JsonKey(name: 'filter_path') this.filterPath,
    @JsonKey(name: 'filter_mailrule') this.filterMailrule,
    @JsonKey(name: 'matching_algorithm') this.matchingAlgorithm = 0,
    this.match = '',
    @JsonKey(name: 'is_insensitive') this.isInsensitive = false,
    @JsonKey(name: 'filter_has_tags') final List<int> filterHasTags = const [],
    @JsonKey(name: 'filter_has_correspondent') this.filterHasCorrespondent,
    @JsonKey(name: 'filter_has_document_type') this.filterHasDocumentType,
  }) : _sources = sources,
       _filterHasTags = filterHasTags;

  factory _$WorkflowTriggerImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowTriggerImplFromJson(json);

  @override
  final int id;
  @override
  final int type;
  final List<int> _sources;
  @override
  @JsonKey()
  List<int> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  @override
  @JsonKey(name: 'filter_filename')
  final String? filterFilename;
  @override
  @JsonKey(name: 'filter_path')
  final String? filterPath;
  @override
  @JsonKey(name: 'filter_mailrule')
  final int? filterMailrule;
  @override
  @JsonKey(name: 'matching_algorithm')
  final int matchingAlgorithm;
  @override
  @JsonKey()
  final String match;
  @override
  @JsonKey(name: 'is_insensitive')
  final bool isInsensitive;
  final List<int> _filterHasTags;
  @override
  @JsonKey(name: 'filter_has_tags')
  List<int> get filterHasTags {
    if (_filterHasTags is EqualUnmodifiableListView) return _filterHasTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filterHasTags);
  }

  @override
  @JsonKey(name: 'filter_has_correspondent')
  final int? filterHasCorrespondent;
  @override
  @JsonKey(name: 'filter_has_document_type')
  final int? filterHasDocumentType;

  @override
  String toString() {
    return 'WorkflowTrigger(id: $id, type: $type, sources: $sources, filterFilename: $filterFilename, filterPath: $filterPath, filterMailrule: $filterMailrule, matchingAlgorithm: $matchingAlgorithm, match: $match, isInsensitive: $isInsensitive, filterHasTags: $filterHasTags, filterHasCorrespondent: $filterHasCorrespondent, filterHasDocumentType: $filterHasDocumentType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowTriggerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            (identical(other.filterFilename, filterFilename) ||
                other.filterFilename == filterFilename) &&
            (identical(other.filterPath, filterPath) ||
                other.filterPath == filterPath) &&
            (identical(other.filterMailrule, filterMailrule) ||
                other.filterMailrule == filterMailrule) &&
            (identical(other.matchingAlgorithm, matchingAlgorithm) ||
                other.matchingAlgorithm == matchingAlgorithm) &&
            (identical(other.match, match) || other.match == match) &&
            (identical(other.isInsensitive, isInsensitive) ||
                other.isInsensitive == isInsensitive) &&
            const DeepCollectionEquality().equals(
              other._filterHasTags,
              _filterHasTags,
            ) &&
            (identical(other.filterHasCorrespondent, filterHasCorrespondent) ||
                other.filterHasCorrespondent == filterHasCorrespondent) &&
            (identical(other.filterHasDocumentType, filterHasDocumentType) ||
                other.filterHasDocumentType == filterHasDocumentType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    const DeepCollectionEquality().hash(_sources),
    filterFilename,
    filterPath,
    filterMailrule,
    matchingAlgorithm,
    match,
    isInsensitive,
    const DeepCollectionEquality().hash(_filterHasTags),
    filterHasCorrespondent,
    filterHasDocumentType,
  );

  /// Create a copy of WorkflowTrigger
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowTriggerImplCopyWith<_$WorkflowTriggerImpl> get copyWith =>
      __$$WorkflowTriggerImplCopyWithImpl<_$WorkflowTriggerImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowTriggerImplToJson(this);
  }
}

abstract class _WorkflowTrigger implements WorkflowTrigger {
  const factory _WorkflowTrigger({
    required final int id,
    required final int type,
    final List<int> sources,
    @JsonKey(name: 'filter_filename') final String? filterFilename,
    @JsonKey(name: 'filter_path') final String? filterPath,
    @JsonKey(name: 'filter_mailrule') final int? filterMailrule,
    @JsonKey(name: 'matching_algorithm') final int matchingAlgorithm,
    final String match,
    @JsonKey(name: 'is_insensitive') final bool isInsensitive,
    @JsonKey(name: 'filter_has_tags') final List<int> filterHasTags,
    @JsonKey(name: 'filter_has_correspondent')
    final int? filterHasCorrespondent,
    @JsonKey(name: 'filter_has_document_type') final int? filterHasDocumentType,
  }) = _$WorkflowTriggerImpl;

  factory _WorkflowTrigger.fromJson(Map<String, dynamic> json) =
      _$WorkflowTriggerImpl.fromJson;

  @override
  int get id;
  @override
  int get type;
  @override
  List<int> get sources;
  @override
  @JsonKey(name: 'filter_filename')
  String? get filterFilename;
  @override
  @JsonKey(name: 'filter_path')
  String? get filterPath;
  @override
  @JsonKey(name: 'filter_mailrule')
  int? get filterMailrule;
  @override
  @JsonKey(name: 'matching_algorithm')
  int get matchingAlgorithm;
  @override
  String get match;
  @override
  @JsonKey(name: 'is_insensitive')
  bool get isInsensitive;
  @override
  @JsonKey(name: 'filter_has_tags')
  List<int> get filterHasTags;
  @override
  @JsonKey(name: 'filter_has_correspondent')
  int? get filterHasCorrespondent;
  @override
  @JsonKey(name: 'filter_has_document_type')
  int? get filterHasDocumentType;

  /// Create a copy of WorkflowTrigger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkflowTriggerImplCopyWith<_$WorkflowTriggerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkflowAction _$WorkflowActionFromJson(Map<String, dynamic> json) {
  return _WorkflowAction.fromJson(json);
}

/// @nodoc
mixin _$WorkflowAction {
  int get id => throw _privateConstructorUsedError;
  int get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_title')
  String? get assignTitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_tags')
  List<int> get assignTags => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_correspondent')
  int? get assignCorrespondent => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_document_type')
  int? get assignDocumentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_storage_path')
  int? get assignStoragePath => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_owner')
  int? get assignOwner => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_view_users')
  List<int> get assignViewUsers => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_view_groups')
  List<int> get assignViewGroups => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_change_users')
  List<int> get assignChangeUsers => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_change_groups')
  List<int> get assignChangeGroups => throw _privateConstructorUsedError;
  @JsonKey(name: 'assign_custom_fields')
  List<int> get assignCustomFields => throw _privateConstructorUsedError;

  /// Serializes this WorkflowAction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkflowAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkflowActionCopyWith<WorkflowAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowActionCopyWith<$Res> {
  factory $WorkflowActionCopyWith(
    WorkflowAction value,
    $Res Function(WorkflowAction) then,
  ) = _$WorkflowActionCopyWithImpl<$Res, WorkflowAction>;
  @useResult
  $Res call({
    int id,
    int type,
    @JsonKey(name: 'assign_title') String? assignTitle,
    @JsonKey(name: 'assign_tags') List<int> assignTags,
    @JsonKey(name: 'assign_correspondent') int? assignCorrespondent,
    @JsonKey(name: 'assign_document_type') int? assignDocumentType,
    @JsonKey(name: 'assign_storage_path') int? assignStoragePath,
    @JsonKey(name: 'assign_owner') int? assignOwner,
    @JsonKey(name: 'assign_view_users') List<int> assignViewUsers,
    @JsonKey(name: 'assign_view_groups') List<int> assignViewGroups,
    @JsonKey(name: 'assign_change_users') List<int> assignChangeUsers,
    @JsonKey(name: 'assign_change_groups') List<int> assignChangeGroups,
    @JsonKey(name: 'assign_custom_fields') List<int> assignCustomFields,
  });
}

/// @nodoc
class _$WorkflowActionCopyWithImpl<$Res, $Val extends WorkflowAction>
    implements $WorkflowActionCopyWith<$Res> {
  _$WorkflowActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkflowAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? assignTitle = freezed,
    Object? assignTags = null,
    Object? assignCorrespondent = freezed,
    Object? assignDocumentType = freezed,
    Object? assignStoragePath = freezed,
    Object? assignOwner = freezed,
    Object? assignViewUsers = null,
    Object? assignViewGroups = null,
    Object? assignChangeUsers = null,
    Object? assignChangeGroups = null,
    Object? assignCustomFields = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as int,
            assignTitle: freezed == assignTitle
                ? _value.assignTitle
                : assignTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignTags: null == assignTags
                ? _value.assignTags
                : assignTags // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            assignCorrespondent: freezed == assignCorrespondent
                ? _value.assignCorrespondent
                : assignCorrespondent // ignore: cast_nullable_to_non_nullable
                      as int?,
            assignDocumentType: freezed == assignDocumentType
                ? _value.assignDocumentType
                : assignDocumentType // ignore: cast_nullable_to_non_nullable
                      as int?,
            assignStoragePath: freezed == assignStoragePath
                ? _value.assignStoragePath
                : assignStoragePath // ignore: cast_nullable_to_non_nullable
                      as int?,
            assignOwner: freezed == assignOwner
                ? _value.assignOwner
                : assignOwner // ignore: cast_nullable_to_non_nullable
                      as int?,
            assignViewUsers: null == assignViewUsers
                ? _value.assignViewUsers
                : assignViewUsers // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            assignViewGroups: null == assignViewGroups
                ? _value.assignViewGroups
                : assignViewGroups // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            assignChangeUsers: null == assignChangeUsers
                ? _value.assignChangeUsers
                : assignChangeUsers // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            assignChangeGroups: null == assignChangeGroups
                ? _value.assignChangeGroups
                : assignChangeGroups // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            assignCustomFields: null == assignCustomFields
                ? _value.assignCustomFields
                : assignCustomFields // ignore: cast_nullable_to_non_nullable
                      as List<int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkflowActionImplCopyWith<$Res>
    implements $WorkflowActionCopyWith<$Res> {
  factory _$$WorkflowActionImplCopyWith(
    _$WorkflowActionImpl value,
    $Res Function(_$WorkflowActionImpl) then,
  ) = __$$WorkflowActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int type,
    @JsonKey(name: 'assign_title') String? assignTitle,
    @JsonKey(name: 'assign_tags') List<int> assignTags,
    @JsonKey(name: 'assign_correspondent') int? assignCorrespondent,
    @JsonKey(name: 'assign_document_type') int? assignDocumentType,
    @JsonKey(name: 'assign_storage_path') int? assignStoragePath,
    @JsonKey(name: 'assign_owner') int? assignOwner,
    @JsonKey(name: 'assign_view_users') List<int> assignViewUsers,
    @JsonKey(name: 'assign_view_groups') List<int> assignViewGroups,
    @JsonKey(name: 'assign_change_users') List<int> assignChangeUsers,
    @JsonKey(name: 'assign_change_groups') List<int> assignChangeGroups,
    @JsonKey(name: 'assign_custom_fields') List<int> assignCustomFields,
  });
}

/// @nodoc
class __$$WorkflowActionImplCopyWithImpl<$Res>
    extends _$WorkflowActionCopyWithImpl<$Res, _$WorkflowActionImpl>
    implements _$$WorkflowActionImplCopyWith<$Res> {
  __$$WorkflowActionImplCopyWithImpl(
    _$WorkflowActionImpl _value,
    $Res Function(_$WorkflowActionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkflowAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? assignTitle = freezed,
    Object? assignTags = null,
    Object? assignCorrespondent = freezed,
    Object? assignDocumentType = freezed,
    Object? assignStoragePath = freezed,
    Object? assignOwner = freezed,
    Object? assignViewUsers = null,
    Object? assignViewGroups = null,
    Object? assignChangeUsers = null,
    Object? assignChangeGroups = null,
    Object? assignCustomFields = null,
  }) {
    return _then(
      _$WorkflowActionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as int,
        assignTitle: freezed == assignTitle
            ? _value.assignTitle
            : assignTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignTags: null == assignTags
            ? _value._assignTags
            : assignTags // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        assignCorrespondent: freezed == assignCorrespondent
            ? _value.assignCorrespondent
            : assignCorrespondent // ignore: cast_nullable_to_non_nullable
                  as int?,
        assignDocumentType: freezed == assignDocumentType
            ? _value.assignDocumentType
            : assignDocumentType // ignore: cast_nullable_to_non_nullable
                  as int?,
        assignStoragePath: freezed == assignStoragePath
            ? _value.assignStoragePath
            : assignStoragePath // ignore: cast_nullable_to_non_nullable
                  as int?,
        assignOwner: freezed == assignOwner
            ? _value.assignOwner
            : assignOwner // ignore: cast_nullable_to_non_nullable
                  as int?,
        assignViewUsers: null == assignViewUsers
            ? _value._assignViewUsers
            : assignViewUsers // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        assignViewGroups: null == assignViewGroups
            ? _value._assignViewGroups
            : assignViewGroups // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        assignChangeUsers: null == assignChangeUsers
            ? _value._assignChangeUsers
            : assignChangeUsers // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        assignChangeGroups: null == assignChangeGroups
            ? _value._assignChangeGroups
            : assignChangeGroups // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        assignCustomFields: null == assignCustomFields
            ? _value._assignCustomFields
            : assignCustomFields // ignore: cast_nullable_to_non_nullable
                  as List<int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowActionImpl implements _WorkflowAction {
  const _$WorkflowActionImpl({
    required this.id,
    required this.type,
    @JsonKey(name: 'assign_title') this.assignTitle,
    @JsonKey(name: 'assign_tags') final List<int> assignTags = const [],
    @JsonKey(name: 'assign_correspondent') this.assignCorrespondent,
    @JsonKey(name: 'assign_document_type') this.assignDocumentType,
    @JsonKey(name: 'assign_storage_path') this.assignStoragePath,
    @JsonKey(name: 'assign_owner') this.assignOwner,
    @JsonKey(name: 'assign_view_users')
    final List<int> assignViewUsers = const [],
    @JsonKey(name: 'assign_view_groups')
    final List<int> assignViewGroups = const [],
    @JsonKey(name: 'assign_change_users')
    final List<int> assignChangeUsers = const [],
    @JsonKey(name: 'assign_change_groups')
    final List<int> assignChangeGroups = const [],
    @JsonKey(name: 'assign_custom_fields')
    final List<int> assignCustomFields = const [],
  }) : _assignTags = assignTags,
       _assignViewUsers = assignViewUsers,
       _assignViewGroups = assignViewGroups,
       _assignChangeUsers = assignChangeUsers,
       _assignChangeGroups = assignChangeGroups,
       _assignCustomFields = assignCustomFields;

  factory _$WorkflowActionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowActionImplFromJson(json);

  @override
  final int id;
  @override
  final int type;
  @override
  @JsonKey(name: 'assign_title')
  final String? assignTitle;
  final List<int> _assignTags;
  @override
  @JsonKey(name: 'assign_tags')
  List<int> get assignTags {
    if (_assignTags is EqualUnmodifiableListView) return _assignTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignTags);
  }

  @override
  @JsonKey(name: 'assign_correspondent')
  final int? assignCorrespondent;
  @override
  @JsonKey(name: 'assign_document_type')
  final int? assignDocumentType;
  @override
  @JsonKey(name: 'assign_storage_path')
  final int? assignStoragePath;
  @override
  @JsonKey(name: 'assign_owner')
  final int? assignOwner;
  final List<int> _assignViewUsers;
  @override
  @JsonKey(name: 'assign_view_users')
  List<int> get assignViewUsers {
    if (_assignViewUsers is EqualUnmodifiableListView) return _assignViewUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignViewUsers);
  }

  final List<int> _assignViewGroups;
  @override
  @JsonKey(name: 'assign_view_groups')
  List<int> get assignViewGroups {
    if (_assignViewGroups is EqualUnmodifiableListView)
      return _assignViewGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignViewGroups);
  }

  final List<int> _assignChangeUsers;
  @override
  @JsonKey(name: 'assign_change_users')
  List<int> get assignChangeUsers {
    if (_assignChangeUsers is EqualUnmodifiableListView)
      return _assignChangeUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignChangeUsers);
  }

  final List<int> _assignChangeGroups;
  @override
  @JsonKey(name: 'assign_change_groups')
  List<int> get assignChangeGroups {
    if (_assignChangeGroups is EqualUnmodifiableListView)
      return _assignChangeGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignChangeGroups);
  }

  final List<int> _assignCustomFields;
  @override
  @JsonKey(name: 'assign_custom_fields')
  List<int> get assignCustomFields {
    if (_assignCustomFields is EqualUnmodifiableListView)
      return _assignCustomFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignCustomFields);
  }

  @override
  String toString() {
    return 'WorkflowAction(id: $id, type: $type, assignTitle: $assignTitle, assignTags: $assignTags, assignCorrespondent: $assignCorrespondent, assignDocumentType: $assignDocumentType, assignStoragePath: $assignStoragePath, assignOwner: $assignOwner, assignViewUsers: $assignViewUsers, assignViewGroups: $assignViewGroups, assignChangeUsers: $assignChangeUsers, assignChangeGroups: $assignChangeGroups, assignCustomFields: $assignCustomFields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowActionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.assignTitle, assignTitle) ||
                other.assignTitle == assignTitle) &&
            const DeepCollectionEquality().equals(
              other._assignTags,
              _assignTags,
            ) &&
            (identical(other.assignCorrespondent, assignCorrespondent) ||
                other.assignCorrespondent == assignCorrespondent) &&
            (identical(other.assignDocumentType, assignDocumentType) ||
                other.assignDocumentType == assignDocumentType) &&
            (identical(other.assignStoragePath, assignStoragePath) ||
                other.assignStoragePath == assignStoragePath) &&
            (identical(other.assignOwner, assignOwner) ||
                other.assignOwner == assignOwner) &&
            const DeepCollectionEquality().equals(
              other._assignViewUsers,
              _assignViewUsers,
            ) &&
            const DeepCollectionEquality().equals(
              other._assignViewGroups,
              _assignViewGroups,
            ) &&
            const DeepCollectionEquality().equals(
              other._assignChangeUsers,
              _assignChangeUsers,
            ) &&
            const DeepCollectionEquality().equals(
              other._assignChangeGroups,
              _assignChangeGroups,
            ) &&
            const DeepCollectionEquality().equals(
              other._assignCustomFields,
              _assignCustomFields,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    assignTitle,
    const DeepCollectionEquality().hash(_assignTags),
    assignCorrespondent,
    assignDocumentType,
    assignStoragePath,
    assignOwner,
    const DeepCollectionEquality().hash(_assignViewUsers),
    const DeepCollectionEquality().hash(_assignViewGroups),
    const DeepCollectionEquality().hash(_assignChangeUsers),
    const DeepCollectionEquality().hash(_assignChangeGroups),
    const DeepCollectionEquality().hash(_assignCustomFields),
  );

  /// Create a copy of WorkflowAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowActionImplCopyWith<_$WorkflowActionImpl> get copyWith =>
      __$$WorkflowActionImplCopyWithImpl<_$WorkflowActionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowActionImplToJson(this);
  }
}

abstract class _WorkflowAction implements WorkflowAction {
  const factory _WorkflowAction({
    required final int id,
    required final int type,
    @JsonKey(name: 'assign_title') final String? assignTitle,
    @JsonKey(name: 'assign_tags') final List<int> assignTags,
    @JsonKey(name: 'assign_correspondent') final int? assignCorrespondent,
    @JsonKey(name: 'assign_document_type') final int? assignDocumentType,
    @JsonKey(name: 'assign_storage_path') final int? assignStoragePath,
    @JsonKey(name: 'assign_owner') final int? assignOwner,
    @JsonKey(name: 'assign_view_users') final List<int> assignViewUsers,
    @JsonKey(name: 'assign_view_groups') final List<int> assignViewGroups,
    @JsonKey(name: 'assign_change_users') final List<int> assignChangeUsers,
    @JsonKey(name: 'assign_change_groups') final List<int> assignChangeGroups,
    @JsonKey(name: 'assign_custom_fields') final List<int> assignCustomFields,
  }) = _$WorkflowActionImpl;

  factory _WorkflowAction.fromJson(Map<String, dynamic> json) =
      _$WorkflowActionImpl.fromJson;

  @override
  int get id;
  @override
  int get type;
  @override
  @JsonKey(name: 'assign_title')
  String? get assignTitle;
  @override
  @JsonKey(name: 'assign_tags')
  List<int> get assignTags;
  @override
  @JsonKey(name: 'assign_correspondent')
  int? get assignCorrespondent;
  @override
  @JsonKey(name: 'assign_document_type')
  int? get assignDocumentType;
  @override
  @JsonKey(name: 'assign_storage_path')
  int? get assignStoragePath;
  @override
  @JsonKey(name: 'assign_owner')
  int? get assignOwner;
  @override
  @JsonKey(name: 'assign_view_users')
  List<int> get assignViewUsers;
  @override
  @JsonKey(name: 'assign_view_groups')
  List<int> get assignViewGroups;
  @override
  @JsonKey(name: 'assign_change_users')
  List<int> get assignChangeUsers;
  @override
  @JsonKey(name: 'assign_change_groups')
  List<int> get assignChangeGroups;
  @override
  @JsonKey(name: 'assign_custom_fields')
  List<int> get assignCustomFields;

  /// Create a copy of WorkflowAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkflowActionImplCopyWith<_$WorkflowActionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Workflow _$WorkflowFromJson(Map<String, dynamic> json) {
  return _Workflow.fromJson(json);
}

/// @nodoc
mixin _$Workflow {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  List<WorkflowTrigger> get triggers => throw _privateConstructorUsedError;
  List<WorkflowAction> get actions => throw _privateConstructorUsedError;

  /// Serializes this Workflow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkflowCopyWith<Workflow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowCopyWith<$Res> {
  factory $WorkflowCopyWith(Workflow value, $Res Function(Workflow) then) =
      _$WorkflowCopyWithImpl<$Res, Workflow>;
  @useResult
  $Res call({
    int id,
    String name,
    int order,
    bool enabled,
    List<WorkflowTrigger> triggers,
    List<WorkflowAction> actions,
  });
}

/// @nodoc
class _$WorkflowCopyWithImpl<$Res, $Val extends Workflow>
    implements $WorkflowCopyWith<$Res> {
  _$WorkflowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? order = null,
    Object? enabled = null,
    Object? triggers = null,
    Object? actions = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            triggers: null == triggers
                ? _value.triggers
                : triggers // ignore: cast_nullable_to_non_nullable
                      as List<WorkflowTrigger>,
            actions: null == actions
                ? _value.actions
                : actions // ignore: cast_nullable_to_non_nullable
                      as List<WorkflowAction>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkflowImplCopyWith<$Res>
    implements $WorkflowCopyWith<$Res> {
  factory _$$WorkflowImplCopyWith(
    _$WorkflowImpl value,
    $Res Function(_$WorkflowImpl) then,
  ) = __$$WorkflowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    int order,
    bool enabled,
    List<WorkflowTrigger> triggers,
    List<WorkflowAction> actions,
  });
}

/// @nodoc
class __$$WorkflowImplCopyWithImpl<$Res>
    extends _$WorkflowCopyWithImpl<$Res, _$WorkflowImpl>
    implements _$$WorkflowImplCopyWith<$Res> {
  __$$WorkflowImplCopyWithImpl(
    _$WorkflowImpl _value,
    $Res Function(_$WorkflowImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? order = null,
    Object? enabled = null,
    Object? triggers = null,
    Object? actions = null,
  }) {
    return _then(
      _$WorkflowImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        triggers: null == triggers
            ? _value._triggers
            : triggers // ignore: cast_nullable_to_non_nullable
                  as List<WorkflowTrigger>,
        actions: null == actions
            ? _value._actions
            : actions // ignore: cast_nullable_to_non_nullable
                  as List<WorkflowAction>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowImpl implements _Workflow {
  const _$WorkflowImpl({
    required this.id,
    required this.name,
    this.order = 0,
    this.enabled = true,
    final List<WorkflowTrigger> triggers = const [],
    final List<WorkflowAction> actions = const [],
  }) : _triggers = triggers,
       _actions = actions;

  factory _$WorkflowImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey()
  final int order;
  @override
  @JsonKey()
  final bool enabled;
  final List<WorkflowTrigger> _triggers;
  @override
  @JsonKey()
  List<WorkflowTrigger> get triggers {
    if (_triggers is EqualUnmodifiableListView) return _triggers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_triggers);
  }

  final List<WorkflowAction> _actions;
  @override
  @JsonKey()
  List<WorkflowAction> get actions {
    if (_actions is EqualUnmodifiableListView) return _actions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_actions);
  }

  @override
  String toString() {
    return 'Workflow(id: $id, name: $name, order: $order, enabled: $enabled, triggers: $triggers, actions: $actions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            const DeepCollectionEquality().equals(other._triggers, _triggers) &&
            const DeepCollectionEquality().equals(other._actions, _actions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    order,
    enabled,
    const DeepCollectionEquality().hash(_triggers),
    const DeepCollectionEquality().hash(_actions),
  );

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowImplCopyWith<_$WorkflowImpl> get copyWith =>
      __$$WorkflowImplCopyWithImpl<_$WorkflowImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowImplToJson(this);
  }
}

abstract class _Workflow implements Workflow {
  const factory _Workflow({
    required final int id,
    required final String name,
    final int order,
    final bool enabled,
    final List<WorkflowTrigger> triggers,
    final List<WorkflowAction> actions,
  }) = _$WorkflowImpl;

  factory _Workflow.fromJson(Map<String, dynamic> json) =
      _$WorkflowImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  int get order;
  @override
  bool get enabled;
  @override
  List<WorkflowTrigger> get triggers;
  @override
  List<WorkflowAction> get actions;

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkflowImplCopyWith<_$WorkflowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
