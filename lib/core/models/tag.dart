import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

@freezed
class Tag with _$Tag {
  const factory Tag({
    required int id,
    required String name,
    required String slug,
    @JsonKey(name: 'color') String? colour,
    @JsonKey(name: 'is_inbox_tag') @Default(false) bool isInboxTag,
    @JsonKey(name: 'document_count') @Default(0) int documentCount,
    @JsonKey(name: 'matching_algorithm') @Default(0) int matchingAlgorithm,
    @JsonKey(name: 'match') @Default('') String match,
    @JsonKey(name: 'is_insensitive') @Default(true) bool isInsensitive,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
