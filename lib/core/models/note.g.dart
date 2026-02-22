// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteImpl _$$NoteImplFromJson(Map<String, dynamic> json) => _$NoteImpl(
  id: (json['id'] as num).toInt(),
  note: json['note'] as String,
  created: DateTime.parse(json['created'] as String),
  user: (json['user'] as num?)?.toInt(),
);

Map<String, dynamic> _$$NoteImplToJson(_$NoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'note': instance.note,
      'created': instance.created.toIso8601String(),
      'user': instance.user,
    };
