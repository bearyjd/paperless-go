// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'correspondent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Correspondent _$CorrespondentFromJson(Map<String, dynamic> json) {
  return _Correspondent.fromJson(json);
}

/// @nodoc
mixin _$Correspondent {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_count')
  int get documentCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'matching_algorithm')
  int get matchingAlgorithm => throw _privateConstructorUsedError;
  @JsonKey(name: 'match')
  String get match => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_insensitive')
  bool get isInsensitive => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_correspondence')
  DateTime? get lastCorrespondence => throw _privateConstructorUsedError;

  /// Serializes this Correspondent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Correspondent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CorrespondentCopyWith<Correspondent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CorrespondentCopyWith<$Res> {
  factory $CorrespondentCopyWith(
    Correspondent value,
    $Res Function(Correspondent) then,
  ) = _$CorrespondentCopyWithImpl<$Res, Correspondent>;
  @useResult
  $Res call({
    int id,
    String name,
    String slug,
    @JsonKey(name: 'document_count') int documentCount,
    @JsonKey(name: 'matching_algorithm') int matchingAlgorithm,
    @JsonKey(name: 'match') String match,
    @JsonKey(name: 'is_insensitive') bool isInsensitive,
    @JsonKey(name: 'last_correspondence') DateTime? lastCorrespondence,
  });
}

/// @nodoc
class _$CorrespondentCopyWithImpl<$Res, $Val extends Correspondent>
    implements $CorrespondentCopyWith<$Res> {
  _$CorrespondentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Correspondent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? documentCount = null,
    Object? matchingAlgorithm = null,
    Object? match = null,
    Object? isInsensitive = null,
    Object? lastCorrespondence = freezed,
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
            lastCorrespondence: freezed == lastCorrespondence
                ? _value.lastCorrespondence
                : lastCorrespondence // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CorrespondentImplCopyWith<$Res>
    implements $CorrespondentCopyWith<$Res> {
  factory _$$CorrespondentImplCopyWith(
    _$CorrespondentImpl value,
    $Res Function(_$CorrespondentImpl) then,
  ) = __$$CorrespondentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String slug,
    @JsonKey(name: 'document_count') int documentCount,
    @JsonKey(name: 'matching_algorithm') int matchingAlgorithm,
    @JsonKey(name: 'match') String match,
    @JsonKey(name: 'is_insensitive') bool isInsensitive,
    @JsonKey(name: 'last_correspondence') DateTime? lastCorrespondence,
  });
}

/// @nodoc
class __$$CorrespondentImplCopyWithImpl<$Res>
    extends _$CorrespondentCopyWithImpl<$Res, _$CorrespondentImpl>
    implements _$$CorrespondentImplCopyWith<$Res> {
  __$$CorrespondentImplCopyWithImpl(
    _$CorrespondentImpl _value,
    $Res Function(_$CorrespondentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Correspondent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? documentCount = null,
    Object? matchingAlgorithm = null,
    Object? match = null,
    Object? isInsensitive = null,
    Object? lastCorrespondence = freezed,
  }) {
    return _then(
      _$CorrespondentImpl(
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
        lastCorrespondence: freezed == lastCorrespondence
            ? _value.lastCorrespondence
            : lastCorrespondence // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CorrespondentImpl implements _Correspondent {
  const _$CorrespondentImpl({
    required this.id,
    required this.name,
    required this.slug,
    @JsonKey(name: 'document_count') this.documentCount = 0,
    @JsonKey(name: 'matching_algorithm') this.matchingAlgorithm = 0,
    @JsonKey(name: 'match') this.match = '',
    @JsonKey(name: 'is_insensitive') this.isInsensitive = true,
    @JsonKey(name: 'last_correspondence') this.lastCorrespondence,
  });

  factory _$CorrespondentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CorrespondentImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String slug;
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
  @JsonKey(name: 'last_correspondence')
  final DateTime? lastCorrespondence;

  @override
  String toString() {
    return 'Correspondent(id: $id, name: $name, slug: $slug, documentCount: $documentCount, matchingAlgorithm: $matchingAlgorithm, match: $match, isInsensitive: $isInsensitive, lastCorrespondence: $lastCorrespondence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CorrespondentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.documentCount, documentCount) ||
                other.documentCount == documentCount) &&
            (identical(other.matchingAlgorithm, matchingAlgorithm) ||
                other.matchingAlgorithm == matchingAlgorithm) &&
            (identical(other.match, match) || other.match == match) &&
            (identical(other.isInsensitive, isInsensitive) ||
                other.isInsensitive == isInsensitive) &&
            (identical(other.lastCorrespondence, lastCorrespondence) ||
                other.lastCorrespondence == lastCorrespondence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    slug,
    documentCount,
    matchingAlgorithm,
    match,
    isInsensitive,
    lastCorrespondence,
  );

  /// Create a copy of Correspondent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CorrespondentImplCopyWith<_$CorrespondentImpl> get copyWith =>
      __$$CorrespondentImplCopyWithImpl<_$CorrespondentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CorrespondentImplToJson(this);
  }
}

abstract class _Correspondent implements Correspondent {
  const factory _Correspondent({
    required final int id,
    required final String name,
    required final String slug,
    @JsonKey(name: 'document_count') final int documentCount,
    @JsonKey(name: 'matching_algorithm') final int matchingAlgorithm,
    @JsonKey(name: 'match') final String match,
    @JsonKey(name: 'is_insensitive') final bool isInsensitive,
    @JsonKey(name: 'last_correspondence') final DateTime? lastCorrespondence,
  }) = _$CorrespondentImpl;

  factory _Correspondent.fromJson(Map<String, dynamic> json) =
      _$CorrespondentImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get slug;
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
  @override
  @JsonKey(name: 'last_correspondence')
  DateTime? get lastCorrespondence;

  /// Create a copy of Correspondent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CorrespondentImplCopyWith<_$CorrespondentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
