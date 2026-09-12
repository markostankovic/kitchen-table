// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_locale.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appLocale)
final appLocaleProvider = AppLocaleProvider._();

final class AppLocaleProvider
    extends $FunctionalProvider<Locale, Locale, Locale>
    with $Provider<Locale> {
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  $ProviderElement<Locale> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Locale create(Ref ref) {
    return appLocale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$appLocaleHash() => r'0561239d42745653c36cd371195272cd96ea6ae8';
