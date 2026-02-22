// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TagImpl _$$TagImplFromJson(Map<String, dynamic> json) => _$TagImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  slug: json['slug'] as String,
  colour: json['colour'] as String?,
  textColor: json['text_color'] as String?,
  isInboxTag: json['is_inbox_tag'] as bool? ?? false,
  documentCount: (json['document_count'] as num?)?.toInt() ?? 0,
  matchingAlgorithm: (json['matching_algorithm'] as num?)?.toInt() ?? 0,
  match: json['match'] as String? ?? '',
  isInsensitive: json['is_insensitive'] as bool? ?? true,
);

Map<String, dynamic> _$$TagImplToJson(_$TagImpl instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'colour': instance.colour,
  'text_color': instance.textColor,
  'is_inbox_tag': instance.isInboxTag,
  'document_count': instance.documentCount,
  'matching_algorithm': instance.matchingAlgorithm,
  'match': instance.match,
  'is_insensitive': instance.isInsensitive,
};
