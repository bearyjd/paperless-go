// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Note _$NoteFromJson(Map<String, dynamic> json) {
  return _Note.fromJson(json);
}

/// @nodoc
mixin _$Note {
  int get id => throw _privateConstructorUsedError;
  String get note => throw _privateConstructorUsedError;
  DateTime get created => throw _privateConstructorUsedError;
  Map<String, dynamic>? get user => throw _privateConstructorUsedError;

  /// Serializes this Note to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteCopyWith<Note> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteCopyWith<$Res> {
  factory $NoteCopyWith(Note value, $Res Function(Note) then) =
      _$NoteCopyWithImpl<$Res, Note>;
  @useResult
  $Res call({
    int id,
    String note,
    DateTime created,
    Map<String, dynamic>? user,
  });
}

/// @nodoc
class _$NoteCopyWithImpl<$Res, $Val extends Note>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? note = null,
    Object? created = null,
    Object? user = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            note: null == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String,
            created: null == created
                ? _value.created
                : created // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            user: freezed == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoteImplCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$$NoteImplCopyWith(
    _$NoteImpl value,
    $Res Function(_$NoteImpl) then,
  ) = __$$NoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String note,
    DateTime created,
    Map<String, dynamic>? user,
  });
}

/// @nodoc
class __$$NoteImplCopyWithImpl<$Res>
    extends _$NoteCopyWithImpl<$Res, _$NoteImpl>
    implements _$$NoteImplCopyWith<$Res> {
  __$$NoteImplCopyWithImpl(_$NoteImpl _value, $Res Function(_$NoteImpl) _then)
    : super(_value, _then);

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? note = null,
    Object? created = null,
    Object? user = freezed,
  }) {
    return _then(
      _$NoteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        note: null == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String,
        created: null == created
            ? _value.created
            : created // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        user: freezed == user
            ? _value._user
            : user // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteImpl implements _Note {
  const _$NoteImpl({
    required this.id,
    required this.note,
    required this.created,
    final Map<String, dynamic>? user,
  }) : _user = user;

  factory _$NoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteImplFromJson(json);

  @override
  final int id;
  @override
  final String note;
  @override
  final DateTime created;
  final Map<String, dynamic>? _user;
  @override
  Map<String, dynamic>? get user {
    final value = _user;
    if (value == null) return null;
    if (_user is EqualUnmodifiableMapView) return _user;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Note(id: $id, note: $note, created: $created, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.created, created) || other.created == created) &&
            const DeepCollectionEquality().equals(other._user, _user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    note,
    created,
    const DeepCollectionEquality().hash(_user),
  );

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      __$$NoteImplCopyWithImpl<_$NoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteImplToJson(this);
  }
}

abstract class _Note implements Note {
  const factory _Note({
    required final int id,
    required final String note,
    required final DateTime created,
    final Map<String, dynamic>? user,
  }) = _$NoteImpl;

  factory _Note.fromJson(Map<String, dynamic> json) = _$NoteImpl.fromJson;

  @override
  int get id;
  @override
  String get note;
  @override
  DateTime get created;
  @override
  Map<String, dynamic>? get user;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NoteUser _$NoteUserFromJson(Map<String, dynamic> json) {
  return _NoteUser.fromJson(json);
}

/// @nodoc
mixin _$NoteUser {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;

  /// Serializes this NoteUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NoteUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteUserCopyWith<NoteUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteUserCopyWith<$Res> {
  factory $NoteUserCopyWith(NoteUser value, $Res Function(NoteUser) then) =
      _$NoteUserCopyWithImpl<$Res, NoteUser>;
  @useResult
  $Res call({int id, String username});
}

/// @nodoc
class _$NoteUserCopyWithImpl<$Res, $Val extends NoteUser>
    implements $NoteUserCopyWith<$Res> {
  _$NoteUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoteUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? username = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoteUserImplCopyWith<$Res>
    implements $NoteUserCopyWith<$Res> {
  factory _$$NoteUserImplCopyWith(
    _$NoteUserImpl value,
    $Res Function(_$NoteUserImpl) then,
  ) = __$$NoteUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String username});
}

/// @nodoc
class __$$NoteUserImplCopyWithImpl<$Res>
    extends _$NoteUserCopyWithImpl<$Res, _$NoteUserImpl>
    implements _$$NoteUserImplCopyWith<$Res> {
  __$$NoteUserImplCopyWithImpl(
    _$NoteUserImpl _value,
    $Res Function(_$NoteUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? username = null}) {
    return _then(
      _$NoteUserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteUserImpl implements _NoteUser {
  const _$NoteUserImpl({required this.id, required this.username});

  factory _$NoteUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteUserImplFromJson(json);

  @override
  final int id;
  @override
  final String username;

  @override
  String toString() {
    return 'NoteUser(id: $id, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, username);

  /// Create a copy of NoteUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteUserImplCopyWith<_$NoteUserImpl> get copyWith =>
      __$$NoteUserImplCopyWithImpl<_$NoteUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteUserImplToJson(this);
  }
}

abstract class _NoteUser implements NoteUser {
  const factory _NoteUser({
    required final int id,
    required final String username,
  }) = _$NoteUserImpl;

  factory _NoteUser.fromJson(Map<String, dynamic> json) =
      _$NoteUserImpl.fromJson;

  @override
  int get id;
  @override
  String get username;

  /// Create a copy of NoteUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteUserImplCopyWith<_$NoteUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
