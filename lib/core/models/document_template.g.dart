// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DocumentTemplateImpl _$$DocumentTemplateImplFromJson(
  Map<String, dynamic> json,
) => _$DocumentTemplateImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  correspondentId: (json['correspondentId'] as num?)?.toInt(),
  documentTypeId: (json['documentTypeId'] as num?)?.toInt(),
  tagIds:
      (json['tagIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  storagePathId: (json['storagePathId'] as num?)?.toInt(),
);

Map<String, dynamic> _$$DocumentTemplateImplToJson(
  _$DocumentTemplateImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'correspondentId': instance.correspondentId,
  'documentTypeId': instance.documentTypeId,
  'tagIds': instance.tagIds,
  'storagePathId': instance.storagePathId,
};
