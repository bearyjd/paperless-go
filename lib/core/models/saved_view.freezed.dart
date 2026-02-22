// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SavedView _$SavedViewFromJson(Map<String, dynamic> json) {
  return _SavedView.fromJson(json);
}

/// @nodoc
mixin _$SavedView {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_on_dashboard')
  bool get showOnDashboard => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_in_sidebar')
  bool get showInSidebar => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_field')
  String get sortField => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_reverse')
  bool get sortReverse => throw _privateConstructorUsedError;
  @JsonKey(name: 'filter_rules')
  List<FilterRule> get filterRules => throw _privateConstructorUsedError;

  /// Serializes this SavedView to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SavedView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SavedViewCopyWith<SavedView> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedViewCopyWith<$Res> {
  factory $SavedViewCopyWith(SavedView value, $Res Function(SavedView) then) =
      _$SavedViewCopyWithImpl<$Res, SavedView>;
  @useResult
  $Res call({
    int id,
    String name,
    @JsonKey(name: 'show_on_dashboard') bool showOnDashboard,
    @JsonKey(name: 'show_in_sidebar') bool showInSidebar,
    @JsonKey(name: 'sort_field') String sortField,
    @JsonKey(name: 'sort_reverse') bool sortReverse,
    @JsonKey(name: 'filter_rules') List<FilterRule> filterRules,
  });
}

/// @nodoc
class _$SavedViewCopyWithImpl<$Res, $Val extends SavedView>
    implements $SavedViewCopyWith<$Res> {
  _$SavedViewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SavedView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? showOnDashboard = null,
    Object? showInSidebar = null,
    Object? sortField = null,
    Object? sortReverse = null,
    Object? filterRules = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            showOnDashboard: null == showOnDashboard
                ? _value.showOnDashboard
                : showOnDashboard // ignore: cast_nullable_to_non_nullable
                      as bool,
            showInSidebar: null == showInSidebar
                ? _value.showInSidebar
                : showInSidebar // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortField: null == sortField
                ? _value.sortField
                : sortField // ignore: cast_nullable_to_non_nullable
                      as String,
            sortReverse: null == sortReverse
                ? _value.sortReverse
                : sortReverse // ignore: cast_nullable_to_non_nullable
                      as bool,
            filterRules: null == filterRules
                ? _value.filterRules
                : filterRules // ignore: cast_nullable_to_non_nullable
                      as List<FilterRule>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SavedViewImplCopyWith<$Res>
    implements $SavedViewCopyWith<$Res> {
  factory _$$SavedViewImplCopyWith(
    _$SavedViewImpl value,
    $Res Function(_$SavedViewImpl) then,
  ) = __$$SavedViewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    @JsonKey(name: 'show_on_dashboard') bool showOnDashboard,
    @JsonKey(name: 'show_in_sidebar') bool showInSidebar,
    @JsonKey(name: 'sort_field') String sortField,
    @JsonKey(name: 'sort_reverse') bool sortReverse,
    @JsonKey(name: 'filter_rules') List<FilterRule> filterRules,
  });
}

/// @nodoc
class __$$SavedViewImplCopyWithImpl<$Res>
    extends _$SavedViewCopyWithImpl<$Res, _$SavedViewImpl>
    implements _$$SavedViewImplCopyWith<$Res> {
  __$$SavedViewImplCopyWithImpl(
    _$SavedViewImpl _value,
    $Res Function(_$SavedViewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SavedView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? showOnDashboard = null,
    Object? showInSidebar = null,
    Object? sortField = null,
    Object? sortReverse = null,
    Object? filterRules = null,
  }) {
    return _then(
      _$SavedViewImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        showOnDashboard: null == showOnDashboard
            ? _value.showOnDashboard
            : showOnDashboard // ignore: cast_nullable_to_non_nullable
                  as bool,
        showInSidebar: null == showInSidebar
            ? _value.showInSidebar
            : showInSidebar // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortField: null == sortField
            ? _value.sortField
            : sortField // ignore: cast_nullable_to_non_nullable
                  as String,
        sortReverse: null == sortReverse
            ? _value.sortReverse
            : sortReverse // ignore: cast_nullable_to_non_nullable
                  as bool,
        filterRules: null == filterRules
            ? _value._filterRules
            : filterRules // ignore: cast_nullable_to_non_nullable
                  as List<FilterRule>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SavedViewImpl implements _SavedView {
  const _$SavedViewImpl({
    required this.id,
    required this.name,
    @JsonKey(name: 'show_on_dashboard') this.showOnDashboard = false,
    @JsonKey(name: 'show_in_sidebar') this.showInSidebar = false,
    @JsonKey(name: 'sort_field') this.sortField = 'created',
    @JsonKey(name: 'sort_reverse') this.sortReverse = true,
    @JsonKey(name: 'filter_rules')
    final List<FilterRule> filterRules = const [],
  }) : _filterRules = filterRules;

  factory _$SavedViewImpl.fromJson(Map<String, dynamic> json) =>
      _$$SavedViewImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey(name: 'show_on_dashboard')
  final bool showOnDashboard;
  @override
  @JsonKey(name: 'show_in_sidebar')
  final bool showInSidebar;
  @override
  @JsonKey(name: 'sort_field')
  final String sortField;
  @override
  @JsonKey(name: 'sort_reverse')
  final bool sortReverse;
  final List<FilterRule> _filterRules;
  @override
  @JsonKey(name: 'filter_rules')
  List<FilterRule> get filterRules {
    if (_filterRules is EqualUnmodifiableListView) return _filterRules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filterRules);
  }

  @override
  String toString() {
    return 'SavedView(id: $id, name: $name, showOnDashboard: $showOnDashboard, showInSidebar: $showInSidebar, sortField: $sortField, sortReverse: $sortReverse, filterRules: $filterRules)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavedViewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.showOnDashboard, showOnDashboard) ||
                other.showOnDashboard == showOnDashboard) &&
            (identical(other.showInSidebar, showInSidebar) ||
                other.showInSidebar == showInSidebar) &&
            (identical(other.sortField, sortField) ||
                other.sortField == sortField) &&
            (identical(other.sortReverse, sortReverse) ||
                other.sortReverse == sortReverse) &&
            const DeepCollectionEquality().equals(
              other._filterRules,
              _filterRules,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    showOnDashboard,
    showInSidebar,
    sortField,
    sortReverse,
    const DeepCollectionEquality().hash(_filterRules),
  );

  /// Create a copy of SavedView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SavedViewImplCopyWith<_$SavedViewImpl> get copyWith =>
      __$$SavedViewImplCopyWithImpl<_$SavedViewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SavedViewImplToJson(this);
  }
}

abstract class _SavedView implements SavedView {
  const factory _SavedView({
    required final int id,
    required final String name,
    @JsonKey(name: 'show_on_dashboard') final bool showOnDashboard,
    @JsonKey(name: 'show_in_sidebar') final bool showInSidebar,
    @JsonKey(name: 'sort_field') final String sortField,
    @JsonKey(name: 'sort_reverse') final bool sortReverse,
    @JsonKey(name: 'filter_rules') final List<FilterRule> filterRules,
  }) = _$SavedViewImpl;

  factory _SavedView.fromJson(Map<String, dynamic> json) =
      _$SavedViewImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'show_on_dashboard')
  bool get showOnDashboard;
  @override
  @JsonKey(name: 'show_in_sidebar')
  bool get showInSidebar;
  @override
  @JsonKey(name: 'sort_field')
  String get sortField;
  @override
  @JsonKey(name: 'sort_reverse')
  bool get sortReverse;
  @override
  @JsonKey(name: 'filter_rules')
  List<FilterRule> get filterRules;

  /// Create a copy of SavedView
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SavedViewImplCopyWith<_$SavedViewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FilterRule _$FilterRuleFromJson(Map<String, dynamic> json) {
  return _FilterRule.fromJson(json);
}

/// @nodoc
mixin _$FilterRule {
  @JsonKey(name: 'rule_type')
  int get ruleType => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;

  /// Serializes this FilterRule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FilterRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterRuleCopyWith<FilterRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterRuleCopyWith<$Res> {
  factory $FilterRuleCopyWith(
    FilterRule value,
    $Res Function(FilterRule) then,
  ) = _$FilterRuleCopyWithImpl<$Res, FilterRule>;
  @useResult
  $Res call({@JsonKey(name: 'rule_type') int ruleType, String value});
}

/// @nodoc
class _$FilterRuleCopyWithImpl<$Res, $Val extends FilterRule>
    implements $FilterRuleCopyWith<$Res> {
  _$FilterRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? ruleType = null, Object? value = null}) {
    return _then(
      _value.copyWith(
            ruleType: null == ruleType
                ? _value.ruleType
                : ruleType // ignore: cast_nullable_to_non_nullable
                      as int,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FilterRuleImplCopyWith<$Res>
    implements $FilterRuleCopyWith<$Res> {
  factory _$$FilterRuleImplCopyWith(
    _$FilterRuleImpl value,
    $Res Function(_$FilterRuleImpl) then,
  ) = __$$FilterRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'rule_type') int ruleType, String value});
}

/// @nodoc
class __$$FilterRuleImplCopyWithImpl<$Res>
    extends _$FilterRuleCopyWithImpl<$Res, _$FilterRuleImpl>
    implements _$$FilterRuleImplCopyWith<$Res> {
  __$$FilterRuleImplCopyWithImpl(
    _$FilterRuleImpl _value,
    $Res Function(_$FilterRuleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FilterRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? ruleType = null, Object? value = null}) {
    return _then(
      _$FilterRuleImpl(
        ruleType: null == ruleType
            ? _value.ruleType
            : ruleType // ignore: cast_nullable_to_non_nullable
                  as int,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FilterRuleImpl implements _FilterRule {
  const _$FilterRuleImpl({
    @JsonKey(name: 'rule_type') required this.ruleType,
    required this.value,
  });

  factory _$FilterRuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterRuleImplFromJson(json);

  @override
  @JsonKey(name: 'rule_type')
  final int ruleType;
  @override
  final String value;

  @override
  String toString() {
    return 'FilterRule(ruleType: $ruleType, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterRuleImpl &&
            (identical(other.ruleType, ruleType) ||
                other.ruleType == ruleType) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, ruleType, value);

  /// Create a copy of FilterRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterRuleImplCopyWith<_$FilterRuleImpl> get copyWith =>
      __$$FilterRuleImplCopyWithImpl<_$FilterRuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterRuleImplToJson(this);
  }
}

abstract class _FilterRule implements FilterRule {
  const factory _FilterRule({
    @JsonKey(name: 'rule_type') required final int ruleType,
    required final String value,
  }) = _$FilterRuleImpl;

  factory _FilterRule.fromJson(Map<String, dynamic> json) =
      _$FilterRuleImpl.fromJson;

  @override
  @JsonKey(name: 'rule_type')
  int get ruleType;
  @override
  String get value;

  /// Create a copy of FilterRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterRuleImplCopyWith<_$FilterRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
