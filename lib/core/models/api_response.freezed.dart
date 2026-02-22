// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PaginatedResponse<T> _$PaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object?) fromJsonT,
) {
  return _PaginatedResponse<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$PaginatedResponse<T> {
  int get count => throw _privateConstructorUsedError;
  String? get next => throw _privateConstructorUsedError;
  String? get previous => throw _privateConstructorUsedError;
  List<int> get all => throw _privateConstructorUsedError;
  List<T> get results => throw _privateConstructorUsedError;

  /// Serializes this PaginatedResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      throw _privateConstructorUsedError;

  /// Create a copy of PaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaginatedResponseCopyWith<T, PaginatedResponse<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginatedResponseCopyWith<T, $Res> {
  factory $PaginatedResponseCopyWith(
    PaginatedResponse<T> value,
    $Res Function(PaginatedResponse<T>) then,
  ) = _$PaginatedResponseCopyWithImpl<T, $Res, PaginatedResponse<T>>;
  @useResult
  $Res call({
    int count,
    String? next,
    String? previous,
    List<int> all,
    List<T> results,
  });
}

/// @nodoc
class _$PaginatedResponseCopyWithImpl<
  T,
  $Res,
  $Val extends PaginatedResponse<T>
>
    implements $PaginatedResponseCopyWith<T, $Res> {
  _$PaginatedResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? next = freezed,
    Object? previous = freezed,
    Object? all = null,
    Object? results = null,
  }) {
    return _then(
      _value.copyWith(
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            next: freezed == next
                ? _value.next
                : next // ignore: cast_nullable_to_non_nullable
                      as String?,
            previous: freezed == previous
                ? _value.previous
                : previous // ignore: cast_nullable_to_non_nullable
                      as String?,
            all: null == all
                ? _value.all
                : all // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            results: null == results
                ? _value.results
                : results // ignore: cast_nullable_to_non_nullable
                      as List<T>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaginatedResponseImplCopyWith<T, $Res>
    implements $PaginatedResponseCopyWith<T, $Res> {
  factory _$$PaginatedResponseImplCopyWith(
    _$PaginatedResponseImpl<T> value,
    $Res Function(_$PaginatedResponseImpl<T>) then,
  ) = __$$PaginatedResponseImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({
    int count,
    String? next,
    String? previous,
    List<int> all,
    List<T> results,
  });
}

/// @nodoc
class __$$PaginatedResponseImplCopyWithImpl<T, $Res>
    extends _$PaginatedResponseCopyWithImpl<T, $Res, _$PaginatedResponseImpl<T>>
    implements _$$PaginatedResponseImplCopyWith<T, $Res> {
  __$$PaginatedResponseImplCopyWithImpl(
    _$PaginatedResponseImpl<T> _value,
    $Res Function(_$PaginatedResponseImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of PaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? next = freezed,
    Object? previous = freezed,
    Object? all = null,
    Object? results = null,
  }) {
    return _then(
      _$PaginatedResponseImpl<T>(
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        next: freezed == next
            ? _value.next
            : next // ignore: cast_nullable_to_non_nullable
                  as String?,
        previous: freezed == previous
            ? _value.previous
            : previous // ignore: cast_nullable_to_non_nullable
                  as String?,
        all: null == all
            ? _value._all
            : all // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        results: null == results
            ? _value._results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<T>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$PaginatedResponseImpl<T> implements _PaginatedResponse<T> {
  const _$PaginatedResponseImpl({
    required this.count,
    this.next,
    this.previous,
    final List<int> all = const [],
    required final List<T> results,
  }) : _all = all,
       _results = results;

  factory _$PaginatedResponseImpl.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$$PaginatedResponseImplFromJson(json, fromJsonT);

  @override
  final int count;
  @override
  final String? next;
  @override
  final String? previous;
  final List<int> _all;
  @override
  @JsonKey()
  List<int> get all {
    if (_all is EqualUnmodifiableListView) return _all;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_all);
  }

  final List<T> _results;
  @override
  List<T> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  String toString() {
    return 'PaginatedResponse<$T>(count: $count, next: $next, previous: $previous, all: $all, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginatedResponseImpl<T> &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.next, next) || other.next == next) &&
            (identical(other.previous, previous) ||
                other.previous == previous) &&
            const DeepCollectionEquality().equals(other._all, _all) &&
            const DeepCollectionEquality().equals(other._results, _results));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    count,
    next,
    previous,
    const DeepCollectionEquality().hash(_all),
    const DeepCollectionEquality().hash(_results),
  );

  /// Create a copy of PaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginatedResponseImplCopyWith<T, _$PaginatedResponseImpl<T>>
  get copyWith =>
      __$$PaginatedResponseImplCopyWithImpl<T, _$PaginatedResponseImpl<T>>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$PaginatedResponseImplToJson<T>(this, toJsonT);
  }
}

abstract class _PaginatedResponse<T> implements PaginatedResponse<T> {
  const factory _PaginatedResponse({
    required final int count,
    final String? next,
    final String? previous,
    final List<int> all,
    required final List<T> results,
  }) = _$PaginatedResponseImpl<T>;

  factory _PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) = _$PaginatedResponseImpl<T>.fromJson;

  @override
  int get count;
  @override
  String? get next;
  @override
  String? get previous;
  @override
  List<int> get all;
  @override
  List<T> get results;

  /// Create a copy of PaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaginatedResponseImplCopyWith<T, _$PaginatedResponseImpl<T>>
  get copyWith => throw _privateConstructorUsedError;
}
