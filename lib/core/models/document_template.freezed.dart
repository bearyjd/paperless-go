// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DocumentTemplate _$DocumentTemplateFromJson(Map<String, dynamic> json) {
  return _DocumentTemplate.fromJson(json);
}

/// @nodoc
mixin _$DocumentTemplate {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int? get correspondentId => throw _privateConstructorUsedError;
  int? get documentTypeId => throw _privateConstructorUsedError;
  List<int> get tagIds => throw _privateConstructorUsedError;
  int? get storagePathId => throw _privateConstructorUsedError;

  /// Serializes this DocumentTemplate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DocumentTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DocumentTemplateCopyWith<DocumentTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentTemplateCopyWith<$Res> {
  factory $DocumentTemplateCopyWith(
    DocumentTemplate value,
    $Res Function(DocumentTemplate) then,
  ) = _$DocumentTemplateCopyWithImpl<$Res, DocumentTemplate>;
  @useResult
  $Res call({
    int id,
    String name,
    int? correspondentId,
    int? documentTypeId,
    List<int> tagIds,
    int? storagePathId,
  });
}

/// @nodoc
class _$DocumentTemplateCopyWithImpl<$Res, $Val extends DocumentTemplate>
    implements $DocumentTemplateCopyWith<$Res> {
  _$DocumentTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DocumentTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? correspondentId = freezed,
    Object? documentTypeId = freezed,
    Object? tagIds = null,
    Object? storagePathId = freezed,
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
            correspondentId: freezed == correspondentId
                ? _value.correspondentId
                : correspondentId // ignore: cast_nullable_to_non_nullable
                      as int?,
            documentTypeId: freezed == documentTypeId
                ? _value.documentTypeId
                : documentTypeId // ignore: cast_nullable_to_non_nullable
                      as int?,
            tagIds: null == tagIds
                ? _value.tagIds
                : tagIds // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            storagePathId: freezed == storagePathId
                ? _value.storagePathId
                : storagePathId // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DocumentTemplateImplCopyWith<$Res>
    implements $DocumentTemplateCopyWith<$Res> {
  factory _$$DocumentTemplateImplCopyWith(
    _$DocumentTemplateImpl value,
    $Res Function(_$DocumentTemplateImpl) then,
  ) = __$$DocumentTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    int? correspondentId,
    int? documentTypeId,
    List<int> tagIds,
    int? storagePathId,
  });
}

/// @nodoc
class __$$DocumentTemplateImplCopyWithImpl<$Res>
    extends _$DocumentTemplateCopyWithImpl<$Res, _$DocumentTemplateImpl>
    implements _$$DocumentTemplateImplCopyWith<$Res> {
  __$$DocumentTemplateImplCopyWithImpl(
    _$DocumentTemplateImpl _value,
    $Res Function(_$DocumentTemplateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DocumentTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? correspondentId = freezed,
    Object? documentTypeId = freezed,
    Object? tagIds = null,
    Object? storagePathId = freezed,
  }) {
    return _then(
      _$DocumentTemplateImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        correspondentId: freezed == correspondentId
            ? _value.correspondentId
            : correspondentId // ignore: cast_nullable_to_non_nullable
                  as int?,
        documentTypeId: freezed == documentTypeId
            ? _value.documentTypeId
            : documentTypeId // ignore: cast_nullable_to_non_nullable
                  as int?,
        tagIds: null == tagIds
            ? _value._tagIds
            : tagIds // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        storagePathId: freezed == storagePathId
            ? _value.storagePathId
            : storagePathId // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DocumentTemplateImpl implements _DocumentTemplate {
  const _$DocumentTemplateImpl({
    required this.id,
    required this.name,
    this.correspondentId,
    this.documentTypeId,
    final List<int> tagIds = const [],
    this.storagePathId,
  }) : _tagIds = tagIds;

  factory _$DocumentTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocumentTemplateImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final int? correspondentId;
  @override
  final int? documentTypeId;
  final List<int> _tagIds;
  @override
  @JsonKey()
  List<int> get tagIds {
    if (_tagIds is EqualUnmodifiableListView) return _tagIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tagIds);
  }

  @override
  final int? storagePathId;

  @override
  String toString() {
    return 'DocumentTemplate(id: $id, name: $name, correspondentId: $correspondentId, documentTypeId: $documentTypeId, tagIds: $tagIds, storagePathId: $storagePathId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.correspondentId, correspondentId) ||
                other.correspondentId == correspondentId) &&
            (identical(other.documentTypeId, documentTypeId) ||
                other.documentTypeId == documentTypeId) &&
            const DeepCollectionEquality().equals(other._tagIds, _tagIds) &&
            (identical(other.storagePathId, storagePathId) ||
                other.storagePathId == storagePathId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    correspondentId,
    documentTypeId,
    const DeepCollectionEquality().hash(_tagIds),
    storagePathId,
  );

  /// Create a copy of DocumentTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentTemplateImplCopyWith<_$DocumentTemplateImpl> get copyWith =>
      __$$DocumentTemplateImplCopyWithImpl<_$DocumentTemplateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DocumentTemplateImplToJson(this);
  }
}

abstract class _DocumentTemplate implements DocumentTemplate {
  const factory _DocumentTemplate({
    required final int id,
    required final String name,
    final int? correspondentId,
    final int? documentTypeId,
    final List<int> tagIds,
    final int? storagePathId,
  }) = _$DocumentTemplateImpl;

  factory _DocumentTemplate.fromJson(Map<String, dynamic> json) =
      _$DocumentTemplateImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  int? get correspondentId;
  @override
  int? get documentTypeId;
  @override
  List<int> get tagIds;
  @override
  int? get storagePathId;

  /// Create a copy of DocumentTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocumentTemplateImplCopyWith<_$DocumentTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
