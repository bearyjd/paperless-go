// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_path.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoragePathImpl _$$StoragePathImplFromJson(Map<String, dynamic> json) =>
    _$StoragePathImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      path: json['path'] as String? ?? '',
      documentCount: (json['document_count'] as num?)?.toInt() ?? 0,
      matchingAlgorithm: (json['matching_algorithm'] as num?)?.toInt() ?? 0,
      match: json['match'] as String? ?? '',
      isInsensitive: json['is_insensitive'] as bool? ?? true,
    );

Map<String, dynamic> _$$StoragePathImplToJson(_$StoragePathImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'path': instance.path,
      'document_count': instance.documentCount,
      'matching_algorithm': instance.matchingAlgorithm,
      'match': instance.match,
      'is_insensitive': instance.isInsensitive,
    };
