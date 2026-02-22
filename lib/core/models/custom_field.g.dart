// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomFieldImpl _$$CustomFieldImplFromJson(Map<String, dynamic> json) =>
    _$CustomFieldImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      dataType: json['data_type'] as String,
      extraData: json['extra_data'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$CustomFieldImplToJson(_$CustomFieldImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'data_type': instance.dataType,
      'extra_data': instance.extraData,
    };

_$CustomFieldInstanceImpl _$$CustomFieldInstanceImplFromJson(
  Map<String, dynamic> json,
) => _$CustomFieldInstanceImpl(
  field: (json['field'] as num).toInt(),
  value: json['value'],
);

Map<String, dynamic> _$$CustomFieldInstanceImplToJson(
  _$CustomFieldInstanceImpl instance,
) => <String, dynamic>{'field': instance.field, 'value': instance.value};
