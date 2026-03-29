// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkflowTriggerImpl _$$WorkflowTriggerImplFromJson(
  Map<String, dynamic> json,
) => _$WorkflowTriggerImpl(
  id: (json['id'] as num).toInt(),
  type: (json['type'] as num).toInt(),
  sources:
      (json['sources'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  filterFilename: json['filter_filename'] as String?,
  filterPath: json['filter_path'] as String?,
  filterMailrule: (json['filter_mailrule'] as num?)?.toInt(),
  matchingAlgorithm: (json['matching_algorithm'] as num?)?.toInt() ?? 0,
  match: json['match'] as String? ?? '',
  isInsensitive: json['is_insensitive'] as bool? ?? false,
  filterHasTags:
      (json['filter_has_tags'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  filterHasCorrespondent: (json['filter_has_correspondent'] as num?)?.toInt(),
  filterHasDocumentType: (json['filter_has_document_type'] as num?)?.toInt(),
);

Map<String, dynamic> _$$WorkflowTriggerImplToJson(
  _$WorkflowTriggerImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'sources': instance.sources,
  'filter_filename': instance.filterFilename,
  'filter_path': instance.filterPath,
  'filter_mailrule': instance.filterMailrule,
  'matching_algorithm': instance.matchingAlgorithm,
  'match': instance.match,
  'is_insensitive': instance.isInsensitive,
  'filter_has_tags': instance.filterHasTags,
  'filter_has_correspondent': instance.filterHasCorrespondent,
  'filter_has_document_type': instance.filterHasDocumentType,
};

_$WorkflowActionImpl _$$WorkflowActionImplFromJson(Map<String, dynamic> json) =>
    _$WorkflowActionImpl(
      id: (json['id'] as num).toInt(),
      type: (json['type'] as num).toInt(),
      assignTitle: json['assign_title'] as String?,
      assignTags:
          (json['assign_tags'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      assignCorrespondent: (json['assign_correspondent'] as num?)?.toInt(),
      assignDocumentType: (json['assign_document_type'] as num?)?.toInt(),
      assignStoragePath: (json['assign_storage_path'] as num?)?.toInt(),
      assignOwner: (json['assign_owner'] as num?)?.toInt(),
      assignViewUsers:
          (json['assign_view_users'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      assignViewGroups:
          (json['assign_view_groups'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      assignChangeUsers:
          (json['assign_change_users'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      assignChangeGroups:
          (json['assign_change_groups'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      assignCustomFields:
          (json['assign_custom_fields'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkflowActionImplToJson(
  _$WorkflowActionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'assign_title': instance.assignTitle,
  'assign_tags': instance.assignTags,
  'assign_correspondent': instance.assignCorrespondent,
  'assign_document_type': instance.assignDocumentType,
  'assign_storage_path': instance.assignStoragePath,
  'assign_owner': instance.assignOwner,
  'assign_view_users': instance.assignViewUsers,
  'assign_view_groups': instance.assignViewGroups,
  'assign_change_users': instance.assignChangeUsers,
  'assign_change_groups': instance.assignChangeGroups,
  'assign_custom_fields': instance.assignCustomFields,
};

_$WorkflowImpl _$$WorkflowImplFromJson(Map<String, dynamic> json) =>
    _$WorkflowImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      triggers:
          (json['triggers'] as List<dynamic>?)
              ?.map((e) => WorkflowTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((e) => WorkflowAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkflowImplToJson(_$WorkflowImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'order': instance.order,
      'enabled': instance.enabled,
      'triggers': instance.triggers.map((e) => e.toJson()).toList(),
      'actions': instance.actions.map((e) => e.toJson()).toList(),
    };
