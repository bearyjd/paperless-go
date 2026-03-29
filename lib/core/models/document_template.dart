import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_template.freezed.dart';
part 'document_template.g.dart';

@freezed
class DocumentTemplate with _$DocumentTemplate {
  const factory DocumentTemplate({
    required int id,
    required String name,
    int? correspondentId,
    int? documentTypeId,
    @Default([]) List<int> tagIds,
    int? storagePathId,
  }) = _DocumentTemplate;

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) =>
      _$DocumentTemplateFromJson(json);
}
