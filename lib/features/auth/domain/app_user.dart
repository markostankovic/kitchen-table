import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// The signed-in identity, as far as auth is concerned.
///
/// Deliberately thin: display name and locale live on [Profile], because they
/// are editable user data rather than facts about the session.
///
/// Pure Dart (CLAUDE.md rule 7).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
