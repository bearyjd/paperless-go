import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_path.freezed.dart';
part 'storage_path.g.dart';

@freezed
class StoragePath with _$StoragePath {
  const factory StoragePath({
    required int id,
    required String name,
    required String slug,
    required String path,
    @JsonKey(name: 'document_count') @Default(0) int documentCount,
    @JsonKey(name: 'matching_algorithm') @Default(0) int matchingAlgorithm,
    @JsonKey(name: 'match') @Default('') String match,
    @JsonKey(name: 'is_insensitive') @Default(true) bool isInsensitive,
  }) = _StoragePath;

  factory StoragePath.fromJson(Map<String, dynamic> json) =>
      _$StoragePathFromJson(json);
}
