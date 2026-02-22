// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correspondent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CorrespondentImpl _$$CorrespondentImplFromJson(Map<String, dynamic> json) =>
    _$CorrespondentImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      documentCount: (json['document_count'] as num?)?.toInt() ?? 0,
      matchingAlgorithm: (json['matching_algorithm'] as num?)?.toInt() ?? 0,
      match: json['match'] as String? ?? '',
      isInsensitive: json['is_insensitive'] as bool? ?? true,
      lastCorrespondence: json['last_correspondence'] == null
          ? null
          : DateTime.parse(json['last_correspondence'] as String),
    );

Map<String, dynamic> _$$CorrespondentImplToJson(_$CorrespondentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'document_count': instance.documentCount,
      'matching_algorithm': instance.matchingAlgorithm,
      'match': instance.match,
      'is_insensitive': instance.isInsensitive,
      'last_correspondence': instance.lastCorrespondence?.toIso8601String(),
    };
