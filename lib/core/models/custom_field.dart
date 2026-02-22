import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_field.freezed.dart';
part 'custom_field.g.dart';

/// Custom field definition from the server.
@freezed
class CustomField with _$CustomField {
  const factory CustomField({
    required int id,
    required String name,
    @JsonKey(name: 'data_type') required String dataType,
    @JsonKey(name: 'extra_data') @Default({}) Map<String, dynamic> extraData,
  }) = _CustomField;

  factory CustomField.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldFromJson(json);
}

/// A custom field value assigned to a document.
@freezed
class CustomFieldInstance with _$CustomFieldInstance {
  const factory CustomFieldInstance({
    required int field,
    dynamic value,
  }) = _CustomFieldInstance;

  factory CustomFieldInstance.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldInstanceFromJson(json);
}
