import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_view.freezed.dart';
part 'saved_view.g.dart';

@freezed
class SavedView with _$SavedView {
  const factory SavedView({
    required int id,
    required String name,
    @JsonKey(name: 'show_on_dashboard') @Default(false) bool showOnDashboard,
    @JsonKey(name: 'show_in_sidebar') @Default(false) bool showInSidebar,
    @JsonKey(name: 'sort_field') @Default('created') String sortField,
    @JsonKey(name: 'sort_reverse') @Default(true) bool sortReverse,
    @JsonKey(name: 'filter_rules') @Default([]) List<FilterRule> filterRules,
  }) = _SavedView;

  factory SavedView.fromJson(Map<String, dynamic> json) =>
      _$SavedViewFromJson(json);
}

@freezed
class FilterRule with _$FilterRule {
  const factory FilterRule({
    @JsonKey(name: 'rule_type') required int ruleType,
    required String value,
  }) = _FilterRule;

  factory FilterRule.fromJson(Map<String, dynamic> json) =>
      _$FilterRuleFromJson(json);
}
