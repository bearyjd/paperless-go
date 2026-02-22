// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SavedViewImpl _$$SavedViewImplFromJson(Map<String, dynamic> json) =>
    _$SavedViewImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      showOnDashboard: json['show_on_dashboard'] as bool? ?? false,
      showInSidebar: json['show_in_sidebar'] as bool? ?? false,
      sortField: json['sort_field'] as String? ?? 'created',
      sortReverse: json['sort_reverse'] as bool? ?? true,
      filterRules:
          (json['filter_rules'] as List<dynamic>?)
              ?.map((e) => FilterRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SavedViewImplToJson(_$SavedViewImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'show_on_dashboard': instance.showOnDashboard,
      'show_in_sidebar': instance.showInSidebar,
      'sort_field': instance.sortField,
      'sort_reverse': instance.sortReverse,
      'filter_rules': instance.filterRules,
    };

_$FilterRuleImpl _$$FilterRuleImplFromJson(Map<String, dynamic> json) =>
    _$FilterRuleImpl(
      ruleType: (json['rule_type'] as num).toInt(),
      value: json['value'] as String,
    );

Map<String, dynamic> _$$FilterRuleImplToJson(_$FilterRuleImpl instance) =>
    <String, dynamic>{'rule_type': instance.ruleType, 'value': instance.value};
