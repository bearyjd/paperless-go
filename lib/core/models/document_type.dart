import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_type.freezed.dart';
part 'document_type.g.dart';

@freezed
class DocumentType with _$DocumentType {
  const factory DocumentType({
    required int id,
    required String name,
    required String slug,
    @JsonKey(name: 'document_count') @Default(0) int documentCount,
    @JsonKey(name: 'matching_algorithm') @Default(0) int matchingAlgorithm,
    @JsonKey(name: 'match') @Default('') String match,
    @JsonKey(name: 'is_insensitive') @Default(true) bool isInsensitive,
  }) = _DocumentType;

  factory DocumentType.fromJson(Map<String, dynamic> json) =>
      _$DocumentTypeFromJson(json);
}
