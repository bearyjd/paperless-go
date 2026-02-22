// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaginatedResponseImpl<T> _$$PaginatedResponseImplFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _$PaginatedResponseImpl<T>(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  all:
      (json['all'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  results: (json['results'] as List<dynamic>).map(fromJsonT).toList(),
);

Map<String, dynamic> _$$PaginatedResponseImplToJson<T>(
  _$PaginatedResponseImpl<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'all': instance.all,
  'results': instance.results.map(toJsonT).toList(),
};
