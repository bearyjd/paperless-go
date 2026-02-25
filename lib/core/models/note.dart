import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';
part 'note.g.dart';

@freezed
class Note with _$Note {
  const factory Note({
    required int id,
    required String note,
    required DateTime created,
    Map<String, dynamic>? user,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}

@freezed
class NoteUser with _$NoteUser {
  const factory NoteUser({
    required int id,
    required String username,
  }) = _NoteUser;

  factory NoteUser.fromJson(Map<String, dynamic> json) =>
      _$NoteUserFromJson(json);
}
