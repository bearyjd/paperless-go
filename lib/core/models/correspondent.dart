import 'package:freezed_annotation/freezed_annotation.dart';

part 'correspondent.freezed.dart';
part 'correspondent.g.dart';

@freezed
class Correspondent with _$Correspondent {
  const factory Correspondent({
    required int id,
    required String name,
    required String slug,
    @JsonKey(name: 'document_count') @Default(0) int documentCount,
    @JsonKey(name: 'matching_algorithm') @Default(0) int matchingAlgorithm,
    @JsonKey(name: 'match') @Default('') String match,
    @JsonKey(name: 'is_insensitive') @Default(true) bool isInsensitive,
    @JsonKey(name: 'last_correspondence') DateTime? lastCorrespondence,
  }) = _Correspondent;

  factory Correspondent.fromJson(Map<String, dynamic> json) =>
      _$CorrespondentFromJson(json);
}
