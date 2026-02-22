// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CustomField _$CustomFieldFromJson(Map<String, dynamic> json) {
  return _CustomField.fromJson(json);
}

/// @nodoc
mixin _$CustomField {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'data_type')
  String get dataType => throw _privateConstructorUsedError;
  @JsonKey(name: 'extra_data')
  Map<String, dynamic> get extraData => throw _privateConstructorUsedError;

  /// Serializes this CustomField to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomFieldCopyWith<CustomField> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomFieldCopyWith<$Res> {
  factory $CustomFieldCopyWith(
    CustomField value,
    $Res Function(CustomField) then,
  ) = _$CustomFieldCopyWithImpl<$Res, CustomField>;
  @useResult
  $Res call({
    int id,
    String name,
    @JsonKey(name: 'data_type') String dataType,
    @JsonKey(name: 'extra_data') Map<String, dynamic> extraData,
  });
}

/// @nodoc
class _$CustomFieldCopyWithImpl<$Res, $Val extends CustomField>
    implements $CustomFieldCopyWith<$Res> {
  _$CustomFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? dataType = null,
    Object? extraData = null,
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
            dataType: null == dataType
                ? _value.dataType
                : dataType // ignore: cast_nullable_to_non_nullable
                      as String,
            extraData: null == extraData
                ? _value.extraData
                : extraData // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomFieldImplCopyWith<$Res>
    implements $CustomFieldCopyWith<$Res> {
  factory _$$CustomFieldImplCopyWith(
    _$CustomFieldImpl value,
    $Res Function(_$CustomFieldImpl) then,
  ) = __$$CustomFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    @JsonKey(name: 'data_type') String dataType,
    @JsonKey(name: 'extra_data') Map<String, dynamic> extraData,
  });
}

/// @nodoc
class __$$CustomFieldImplCopyWithImpl<$Res>
    extends _$CustomFieldCopyWithImpl<$Res, _$CustomFieldImpl>
    implements _$$CustomFieldImplCopyWith<$Res> {
  __$$CustomFieldImplCopyWithImpl(
    _$CustomFieldImpl _value,
    $Res Function(_$CustomFieldImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? dataType = null,
    Object? extraData = null,
  }) {
    return _then(
      _$CustomFieldImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        dataType: null == dataType
            ? _value.dataType
            : dataType // ignore: cast_nullable_to_non_nullable
                  as String,
        extraData: null == extraData
            ? _value._extraData
            : extraData // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomFieldImpl implements _CustomField {
  const _$CustomFieldImpl({
    required this.id,
    required this.name,
    @JsonKey(name: 'data_type') required this.dataType,
    @JsonKey(name: 'extra_data')
    final Map<String, dynamic> extraData = const {},
  }) : _extraData = extraData;

  factory _$CustomFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomFieldImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey(name: 'data_type')
  final String dataType;
  final Map<String, dynamic> _extraData;
  @override
  @JsonKey(name: 'extra_data')
  Map<String, dynamic> get extraData {
    if (_extraData is EqualUnmodifiableMapView) return _extraData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_extraData);
  }

  @override
  String toString() {
    return 'CustomField(id: $id, name: $name, dataType: $dataType, extraData: $extraData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomFieldImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.dataType, dataType) ||
                other.dataType == dataType) &&
            const DeepCollectionEquality().equals(
              other._extraData,
              _extraData,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    dataType,
    const DeepCollectionEquality().hash(_extraData),
  );

  /// Create a copy of CustomField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomFieldImplCopyWith<_$CustomFieldImpl> get copyWith =>
      __$$CustomFieldImplCopyWithImpl<_$CustomFieldImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomFieldImplToJson(this);
  }
}

abstract class _CustomField implements CustomField {
  const factory _CustomField({
    required final int id,
    required final String name,
    @JsonKey(name: 'data_type') required final String dataType,
    @JsonKey(name: 'extra_data') final Map<String, dynamic> extraData,
  }) = _$CustomFieldImpl;

  factory _CustomField.fromJson(Map<String, dynamic> json) =
      _$CustomFieldImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'data_type')
  String get dataType;
  @override
  @JsonKey(name: 'extra_data')
  Map<String, dynamic> get extraData;

  /// Create a copy of CustomField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomFieldImplCopyWith<_$CustomFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomFieldInstance _$CustomFieldInstanceFromJson(Map<String, dynamic> json) {
  return _CustomFieldInstance.fromJson(json);
}

/// @nodoc
mixin _$CustomFieldInstance {
  int get field => throw _privateConstructorUsedError;
  dynamic get value => throw _privateConstructorUsedError;

  /// Serializes this CustomFieldInstance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomFieldInstance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomFieldInstanceCopyWith<CustomFieldInstance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomFieldInstanceCopyWith<$Res> {
  factory $CustomFieldInstanceCopyWith(
    CustomFieldInstance value,
    $Res Function(CustomFieldInstance) then,
  ) = _$CustomFieldInstanceCopyWithImpl<$Res, CustomFieldInstance>;
  @useResult
  $Res call({int field, dynamic value});
}

/// @nodoc
class _$CustomFieldInstanceCopyWithImpl<$Res, $Val extends CustomFieldInstance>
    implements $CustomFieldInstanceCopyWith<$Res> {
  _$CustomFieldInstanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomFieldInstance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field = null, Object? value = freezed}) {
    return _then(
      _value.copyWith(
            field: null == field
                ? _value.field
                : field // ignore: cast_nullable_to_non_nullable
                      as int,
            value: freezed == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as dynamic,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomFieldInstanceImplCopyWith<$Res>
    implements $CustomFieldInstanceCopyWith<$Res> {
  factory _$$CustomFieldInstanceImplCopyWith(
    _$CustomFieldInstanceImpl value,
    $Res Function(_$CustomFieldInstanceImpl) then,
  ) = __$$CustomFieldInstanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int field, dynamic value});
}

/// @nodoc
class __$$CustomFieldInstanceImplCopyWithImpl<$Res>
    extends _$CustomFieldInstanceCopyWithImpl<$Res, _$CustomFieldInstanceImpl>
    implements _$$CustomFieldInstanceImplCopyWith<$Res> {
  __$$CustomFieldInstanceImplCopyWithImpl(
    _$CustomFieldInstanceImpl _value,
    $Res Function(_$CustomFieldInstanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomFieldInstance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field = null, Object? value = freezed}) {
    return _then(
      _$CustomFieldInstanceImpl(
        field: null == field
            ? _value.field
            : field // ignore: cast_nullable_to_non_nullable
                  as int,
        value: freezed == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as dynamic,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomFieldInstanceImpl implements _CustomFieldInstance {
  const _$CustomFieldInstanceImpl({required this.field, this.value});

  factory _$CustomFieldInstanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomFieldInstanceImplFromJson(json);

  @override
  final int field;
  @override
  final dynamic value;

  @override
  String toString() {
    return 'CustomFieldInstance(field: $field, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomFieldInstanceImpl &&
            (identical(other.field, field) || other.field == field) &&
            const DeepCollectionEquality().equals(other.value, value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    field,
    const DeepCollectionEquality().hash(value),
  );

  /// Create a copy of CustomFieldInstance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomFieldInstanceImplCopyWith<_$CustomFieldInstanceImpl> get copyWith =>
      __$$CustomFieldInstanceImplCopyWithImpl<_$CustomFieldInstanceImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomFieldInstanceImplToJson(this);
  }
}

abstract class _CustomFieldInstance implements CustomFieldInstance {
  const factory _CustomFieldInstance({
    required final int field,
    final dynamic value,
  }) = _$CustomFieldInstanceImpl;

  factory _CustomFieldInstance.fromJson(Map<String, dynamic> json) =
      _$CustomFieldInstanceImpl.fromJson;

  @override
  int get field;
  @override
  dynamic get value;

  /// Create a copy of CustomFieldInstance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomFieldInstanceImplCopyWith<_$CustomFieldInstanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
