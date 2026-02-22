// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DocumentTypeImpl _$$DocumentTypeImplFromJson(Map<String, dynamic> json) =>
    _$DocumentTypeImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      documentCount: (json['document_count'] as num?)?.toInt() ?? 0,
      matchingAlgorithm: (json['matching_algorithm'] as num?)?.toInt() ?? 0,
      match: json['match'] as String? ?? '',
      isInsensitive: json['is_insensitive'] as bool? ?? true,
    );

Map<String, dynamic> _$$DocumentTypeImplToJson(_$DocumentTypeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'document_count': instance.documentCount,
      'matching_algorithm': instance.matchingAlgorithm,
      'match': instance.match,
      'is_insensitive': instance.isInsensitive,
    };
