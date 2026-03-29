import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

@freezed
class WorkflowTrigger with _$WorkflowTrigger {
  const factory WorkflowTrigger({
    required int id,
    required int type,
    @Default([]) List<int> sources,
    @JsonKey(name: 'filter_filename') String? filterFilename,
    @JsonKey(name: 'filter_path') String? filterPath,
    @JsonKey(name: 'filter_mailrule') int? filterMailrule,
    @JsonKey(name: 'matching_algorithm') @Default(0) int matchingAlgorithm,
    @Default('') String match,
    @JsonKey(name: 'is_insensitive') @Default(false) bool isInsensitive,
    @JsonKey(name: 'filter_has_tags') @Default([]) List<int> filterHasTags,
    @JsonKey(name: 'filter_has_correspondent') int? filterHasCorrespondent,
    @JsonKey(name: 'filter_has_document_type') int? filterHasDocumentType,
  }) = _WorkflowTrigger;

  factory WorkflowTrigger.fromJson(Map<String, dynamic> json) =>
      _$WorkflowTriggerFromJson(json);
}

@freezed
class WorkflowAction with _$WorkflowAction {
  const factory WorkflowAction({
    required int id,
    required int type,
    @JsonKey(name: 'assign_title') String? assignTitle,
    @JsonKey(name: 'assign_tags') @Default([]) List<int> assignTags,
    @JsonKey(name: 'assign_correspondent') int? assignCorrespondent,
    @JsonKey(name: 'assign_document_type') int? assignDocumentType,
    @JsonKey(name: 'assign_storage_path') int? assignStoragePath,
    @JsonKey(name: 'assign_owner') int? assignOwner,
    @JsonKey(name: 'assign_view_users') @Default([]) List<int> assignViewUsers,
    @JsonKey(name: 'assign_view_groups') @Default([]) List<int> assignViewGroups,
    @JsonKey(name: 'assign_change_users') @Default([]) List<int> assignChangeUsers,
    @JsonKey(name: 'assign_change_groups') @Default([]) List<int> assignChangeGroups,
    @JsonKey(name: 'assign_custom_fields') @Default([]) List<int> assignCustomFields,
  }) = _WorkflowAction;

  factory WorkflowAction.fromJson(Map<String, dynamic> json) =>
      _$WorkflowActionFromJson(json);
}

@freezed
class Workflow with _$Workflow {
  const factory Workflow({
    required int id,
    required String name,
    @Default(0) int order,
    @Default(true) bool enabled,
    @Default([]) List<WorkflowTrigger> triggers,
    @Default([]) List<WorkflowAction> actions,
  }) = _Workflow;

  factory Workflow.fromJson(Map<String, dynamic> json) =>
      _$WorkflowFromJson(json);
}
