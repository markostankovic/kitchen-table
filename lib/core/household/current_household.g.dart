// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_household.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentHouseholdId)
final currentHouseholdIdProvider = CurrentHouseholdIdProvider._();

final class CurrentHouseholdIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  CurrentHouseholdIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentHouseholdIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentHouseholdIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return currentHouseholdId(ref);
  }
}

String _$currentHouseholdIdHash() =>
    r'07088488b8a7d0d635971cc10dfaaa5122109b74';

/// The current household's name and member count, or null when there is no
/// household -- see this file's doc comment for why a record.

@ProviderFor(currentHouseholdSummary)
final currentHouseholdSummaryProvider = CurrentHouseholdSummaryProvider._();

/// The current household's name and member count, or null when there is no
/// household -- see this file's doc comment for why a record.

final class CurrentHouseholdSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<({int memberCount, String name})?>,
          ({int memberCount, String name})?,
          FutureOr<({int memberCount, String name})?>
        >
    with
        $FutureModifier<({int memberCount, String name})?>,
        $FutureProvider<({int memberCount, String name})?> {
  /// The current household's name and member count, or null when there is no
  /// household -- see this file's doc comment for why a record.
  CurrentHouseholdSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentHouseholdSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentHouseholdSummaryHash();

  @$internal
  @override
  $FutureProviderElement<({int memberCount, String name})?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<({int memberCount, String name})?> create(Ref ref) {
    return currentHouseholdSummary(ref);
  }
}

String _$currentHouseholdSummaryHash() =>
    r'662f1c8bf79b5e1a6aa35e607ff3befe103caa1b';
