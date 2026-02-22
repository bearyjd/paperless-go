// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage_path.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StoragePath _$StoragePathFromJson(Map<String, dynamic> json) {
  return _StoragePath.fromJson(json);
}

/// @nodoc
mixin _$StoragePath {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_count')
  int get documentCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'matching_algorithm')
  int get matchingAlgorithm => throw _privateConstructorUsedError;
  @JsonKey(name: 'match')
  String get match => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_insensitive')
  bool get isInsensitive => throw _privateConstructorUsedError;

  /// Serializes this StoragePath to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoragePath
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoragePathCopyWith<StoragePath> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoragePathCopyWith<$Res> {
  factory $StoragePathCopyWith(
    StoragePath value,
    $Res Function(StoragePath) then,
  ) = _$StoragePathCopyWithImpl<$Res, StoragePath>;
  @useResult
  $Res call({
    int id,
    String name,
    String slug,
    String path,
    @JsonKey(name: 'document_count') int documentCount,
    @JsonKey(name: 'matching_algorithm') int matchingAlgorithm,
    @JsonKey(name: 'match') String match,
    @JsonKey(name: 'is_insensitive') bool isInsensitive,
  });
}

/// @nodoc
class _$StoragePathCopyWithImpl<$Res, $Val extends StoragePath>
    implements $StoragePathCopyWith<$Res> {
  _$StoragePathCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoragePath
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? path = null,
    Object? documentCount = null,
    Object? matchingAlgorithm = null,
    Object? match = null,
    Object? isInsensitive = null,
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
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String,
            documentCount: null == documentCount
                ? _value.documentCount
                : documentCount // ignore: cast_nullable_to_non_nullable
                      as int,
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StoragePathImplCopyWith<$Res>
    implements $StoragePathCopyWith<$Res> {
  factory _$$StoragePathImplCopyWith(
    _$StoragePathImpl value,
    $Res Function(_$StoragePathImpl) then,
  ) = __$$StoragePathImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String slug,
    String path,
    @JsonKey(name: 'document_count') int documentCount,
    @JsonKey(name: 'matching_algorithm') int matchingAlgorithm,
    @JsonKey(name: 'match') String match,
    @JsonKey(name: 'is_insensitive') bool isInsensitive,
  });
}

/// @nodoc
class __$$StoragePathImplCopyWithImpl<$Res>
    extends _$StoragePathCopyWithImpl<$Res, _$StoragePathImpl>
    implements _$$StoragePathImplCopyWith<$Res> {
  __$$StoragePathImplCopyWithImpl(
    _$StoragePathImpl _value,
    $Res Function(_$StoragePathImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StoragePath
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? path = null,
    Object? documentCount = null,
    Object? matchingAlgorithm = null,
    Object? match = null,
    Object? isInsensitive = null,
  }) {
    return _then(
      _$StoragePathImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        documentCount: null == documentCount
            ? _value.documentCount
            : documentCount // ignore: cast_nullable_to_non_nullable
                  as int,
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StoragePathImpl implements _StoragePath {
  const _$StoragePathImpl({
    required this.id,
    required this.name,
    required this.slug,
    required this.path,
    @JsonKey(name: 'document_count') this.documentCount = 0,
    @JsonKey(name: 'matching_algorithm') this.matchingAlgorithm = 0,
    @JsonKey(name: 'match') this.match = '',
    @JsonKey(name: 'is_insensitive') this.isInsensitive = true,
  });

  factory _$StoragePathImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoragePathImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String path;
  @override
  @JsonKey(name: 'document_count')
  final int documentCount;
  @override
  @JsonKey(name: 'matching_algorithm')
  final int matchingAlgorithm;
  @override
  @JsonKey(name: 'match')
  final String match;
  @override
  @JsonKey(name: 'is_insensitive')
  final bool isInsensitive;

  @override
  String toString() {
    return 'StoragePath(id: $id, name: $name, slug: $slug, path: $path, documentCount: $documentCount, matchingAlgorithm: $matchingAlgorithm, match: $match, isInsensitive: $isInsensitive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoragePathImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.documentCount, documentCount) ||
                other.documentCount == documentCount) &&
            (identical(other.matchingAlgorithm, matchingAlgorithm) ||
                other.matchingAlgorithm == matchingAlgorithm) &&
            (identical(other.match, match) || other.match == match) &&
            (identical(other.isInsensitive, isInsensitive) ||
                other.isInsensitive == isInsensitive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    slug,
    path,
    documentCount,
    matchingAlgorithm,
    match,
    isInsensitive,
  );

  /// Create a copy of StoragePath
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoragePathImplCopyWith<_$StoragePathImpl> get copyWith =>
      __$$StoragePathImplCopyWithImpl<_$StoragePathImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoragePathImplToJson(this);
  }
}

abstract class _StoragePath implements StoragePath {
  const factory _StoragePath({
    required final int id,
    required final String name,
    required final String slug,
    required final String path,
    @JsonKey(name: 'document_count') final int documentCount,
    @JsonKey(name: 'matching_algorithm') final int matchingAlgorithm,
    @JsonKey(name: 'match') final String match,
    @JsonKey(name: 'is_insensitive') final bool isInsensitive,
  }) = _$StoragePathImpl;

  factory _StoragePath.fromJson(Map<String, dynamic> json) =
      _$StoragePathImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  String get path;
  @override
  @JsonKey(name: 'document_count')
  int get documentCount;
  @override
  @JsonKey(name: 'matching_algorithm')
  int get matchingAlgorithm;
  @override
  @JsonKey(name: 'match')
  String get match;
  @override
  @JsonKey(name: 'is_insensitive')
  bool get isInsensitive;

  /// Create a copy of StoragePath
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoragePathImplCopyWith<_$StoragePathImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
