import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// The locales this app supports. `sr` and `en`, nothing else (CLAUDE.md).
@JsonEnum(valueField: 'code')
enum AppLocale {
  sr('sr'),
  en('en');

  const AppLocale(this.code);

  final String code;

  static AppLocale fromCode(String code) => AppLocale.values.firstWhere(
        (AppLocale l) => l.code == code,
        orElse: () => AppLocale.sr,
      );
}

/// A user's own profile row.
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String displayName,
    @Default(AppLocale.sr) AppLocale locale,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
