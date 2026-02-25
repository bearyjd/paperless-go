// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteImpl _$$NoteImplFromJson(Map<String, dynamic> json) => _$NoteImpl(
  id: (json['id'] as num).toInt(),
  note: json['note'] as String,
  created: DateTime.parse(json['created'] as String),
  user: json['user'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$$NoteImplToJson(_$NoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'note': instance.note,
      'created': instance.created.toIso8601String(),
      'user': instance.user,
    };

_$NoteUserImpl _$$NoteUserImplFromJson(Map<String, dynamic> json) =>
    _$NoteUserImpl(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
    );

Map<String, dynamic> _$$NoteUserImplToJson(_$NoteUserImpl instance) =>
    <String, dynamic>{'id': instance.id, 'username': instance.username};
