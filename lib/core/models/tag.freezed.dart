// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Tag _$TagFromJson(Map<String, dynamic> json) {
  return _Tag.fromJson(json);
}

/// @nodoc
mixin _$Tag {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get colour => throw _privateConstructorUsedError;
  @JsonKey(name: 'text_color')
  String? get textColor => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_inbox_tag')
  bool get isInboxTag => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_count')
  int get documentCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'matching_algorithm')
  int get matchingAlgorithm => throw _privateConstructorUsedError;
  @JsonKey(name: 'match')
  String get match => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_insensitive')
  bool get isInsensitive => throw _privateConstructorUsedError;

  /// Serializes this Tag to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TagCopyWith<Tag> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TagCopyWith<$Res> {
  factory $TagCopyWith(Tag value, $Res Function(Tag) then) =
      _$TagCopyWithImpl<$Res, Tag>;
  @useResult
  $Res call({
    int id,
    String name,
    String slug,
    String? colour,
    @JsonKey(name: 'text_color') String? textColor,
    @JsonKey(name: 'is_inbox_tag') bool isInboxTag,
    @JsonKey(name: 'document_count') int documentCount,
    @JsonKey(name: 'matching_algorithm') int matchingAlgorithm,
    @JsonKey(name: 'match') String match,
    @JsonKey(name: 'is_insensitive') bool isInsensitive,
  });
}

/// @nodoc
class _$TagCopyWithImpl<$Res, $Val extends Tag> implements $TagCopyWith<$Res> {
  _$TagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? colour = freezed,
    Object? textColor = freezed,
    Object? isInboxTag = null,
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
            colour: freezed == colour
                ? _value.colour
                : colour // ignore: cast_nullable_to_non_nullable
                      as String?,
            textColor: freezed == textColor
                ? _value.textColor
                : textColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            isInboxTag: null == isInboxTag
                ? _value.isInboxTag
                : isInboxTag // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$TagImplCopyWith<$Res> implements $TagCopyWith<$Res> {
  factory _$$TagImplCopyWith(_$TagImpl value, $Res Function(_$TagImpl) then) =
      __$$TagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String slug,
    String? colour,
    @JsonKey(name: 'text_color') String? textColor,
    @JsonKey(name: 'is_inbox_tag') bool isInboxTag,
    @JsonKey(name: 'document_count') int documentCount,
    @JsonKey(name: 'matching_algorithm') int matchingAlgorithm,
    @JsonKey(name: 'match') String match,
    @JsonKey(name: 'is_insensitive') bool isInsensitive,
  });
}

/// @nodoc
class __$$TagImplCopyWithImpl<$Res> extends _$TagCopyWithImpl<$Res, _$TagImpl>
    implements _$$TagImplCopyWith<$Res> {
  __$$TagImplCopyWithImpl(_$TagImpl _value, $Res Function(_$TagImpl) _then)
    : super(_value, _then);

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? colour = freezed,
    Object? textColor = freezed,
    Object? isInboxTag = null,
    Object? documentCount = null,
    Object? matchingAlgorithm = null,
    Object? match = null,
    Object? isInsensitive = null,
  }) {
    return _then(
      _$TagImpl(
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
        colour: freezed == colour
            ? _value.colour
            : colour // ignore: cast_nullable_to_non_nullable
                  as String?,
        textColor: freezed == textColor
            ? _value.textColor
            : textColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        isInboxTag: null == isInboxTag
            ? _value.isInboxTag
            : isInboxTag // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$TagImpl implements _Tag {
  const _$TagImpl({
    required this.id,
    required this.name,
    required this.slug,
    this.colour,
    @JsonKey(name: 'text_color') this.textColor,
    @JsonKey(name: 'is_inbox_tag') this.isInboxTag = false,
    @JsonKey(name: 'document_count') this.documentCount = 0,
    @JsonKey(name: 'matching_algorithm') this.matchingAlgorithm = 0,
    @JsonKey(name: 'match') this.match = '',
    @JsonKey(name: 'is_insensitive') this.isInsensitive = true,
  });

  factory _$TagImpl.fromJson(Map<String, dynamic> json) =>
      _$$TagImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? colour;
  @override
  @JsonKey(name: 'text_color')
  final String? textColor;
  @override
  @JsonKey(name: 'is_inbox_tag')
  final bool isInboxTag;
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
    return 'Tag(id: $id, name: $name, slug: $slug, colour: $colour, textColor: $textColor, isInboxTag: $isInboxTag, documentCount: $documentCount, matchingAlgorithm: $matchingAlgorithm, match: $match, isInsensitive: $isInsensitive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.colour, colour) || other.colour == colour) &&
            (identical(other.textColor, textColor) ||
                other.textColor == textColor) &&
            (identical(other.isInboxTag, isInboxTag) ||
                other.isInboxTag == isInboxTag) &&
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
    colour,
    textColor,
    isInboxTag,
    documentCount,
    matchingAlgorithm,
    match,
    isInsensitive,
  );

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TagImplCopyWith<_$TagImpl> get copyWith =>
      __$$TagImplCopyWithImpl<_$TagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TagImplToJson(this);
  }
}

abstract class _Tag implements Tag {
  const factory _Tag({
    required final int id,
    required final String name,
    required final String slug,
    final String? colour,
    @JsonKey(name: 'text_color') final String? textColor,
    @JsonKey(name: 'is_inbox_tag') final bool isInboxTag,
    @JsonKey(name: 'document_count') final int documentCount,
    @JsonKey(name: 'matching_algorithm') final int matchingAlgorithm,
    @JsonKey(name: 'match') final String match,
    @JsonKey(name: 'is_insensitive') final bool isInsensitive,
  }) = _$TagImpl;

  factory _Tag.fromJson(Map<String, dynamic> json) = _$TagImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  String? get colour;
  @override
  @JsonKey(name: 'text_color')
  String? get textColor;
  @override
  @JsonKey(name: 'is_inbox_tag')
  bool get isInboxTag;
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

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TagImplCopyWith<_$TagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
