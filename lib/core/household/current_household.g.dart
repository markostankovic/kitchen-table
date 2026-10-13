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

/// The current household's id, name and member count, and how many other
/// households the caller is in; or null when there is no household -- see
/// this file's doc comment for why a record.
///
/// [otherHouseholdCount] falls to 0 on an [AppFailure]: `myHouseholds` is
/// network-only while the current household has a cache, so offline the row
/// takes the one-household look rather than failing whole.

@ProviderFor(currentHouseholdSummary)
final currentHouseholdSummaryProvider = CurrentHouseholdSummaryProvider._();

/// The current household's id, name and member count, and how many other
/// households the caller is in; or null when there is no household -- see
/// this file's doc comment for why a record.
///
/// [otherHouseholdCount] falls to 0 on an [AppFailure]: `myHouseholds` is
/// network-only while the current household has a cache, so offline the row
/// takes the one-household look rather than failing whole.

final class CurrentHouseholdSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<
            ({
              String id,
              int memberCount,
              String name,
              int otherHouseholdCount,
            })?
          >,
          ({String id, int memberCount, String name, int otherHouseholdCount})?,
          FutureOr<
            ({
              String id,
              int memberCount,
              String name,
              int otherHouseholdCount,
            })?
          >
        >
    with
        $FutureModifier<
          ({String id, int memberCount, String name, int otherHouseholdCount})?
        >,
        $FutureProvider<
          ({String id, int memberCount, String name, int otherHouseholdCount})?
        > {
  /// The current household's id, name and member count, and how many other
  /// households the caller is in; or null when there is no household -- see
  /// this file's doc comment for why a record.
  ///
  /// [otherHouseholdCount] falls to 0 on an [AppFailure]: `myHouseholds` is
  /// network-only while the current household has a cache, so offline the row
  /// takes the one-household look rather than failing whole.
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
  $FutureProviderElement<
    ({String id, int memberCount, String name, int otherHouseholdCount})?
  >
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<
    ({String id, int memberCount, String name, int otherHouseholdCount})?
  >
  create(Ref ref) {
    return currentHouseholdSummary(ref);
  }
}

String _$currentHouseholdSummaryHash() =>
    r'eacbbb02fb146a9d62fd2d478da4ee69f4d0f357';

/// The current household's name when the caller has others to switch to;
/// null with one, while unknown, or offline (myHouseholds is network-only)
/// -- the tab header's whole condition for showing its second line.
///
/// Reads no members, unlike [currentHouseholdSummary]: the header must not
/// wait on a member-count query.

@ProviderFor(householdSwitcherName)
final householdSwitcherNameProvider = HouseholdSwitcherNameProvider._();

/// The current household's name when the caller has others to switch to;
/// null with one, while unknown, or offline (myHouseholds is network-only)
/// -- the tab header's whole condition for showing its second line.
///
/// Reads no members, unlike [currentHouseholdSummary]: the header must not
/// wait on a member-count query.

final class HouseholdSwitcherNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The current household's name when the caller has others to switch to;
  /// null with one, while unknown, or offline (myHouseholds is network-only)
  /// -- the tab header's whole condition for showing its second line.
  ///
  /// Reads no members, unlike [currentHouseholdSummary]: the header must not
  /// wait on a member-count query.
  HouseholdSwitcherNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdSwitcherNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdSwitcherNameHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return householdSwitcherName(ref);
  }
}

String _$householdSwitcherNameHash() =>
    r'b144d96651d23df5b47c57bd546fe2f4eebbf3d0';

/// Whether a household switch is in flight (`CurrentHousehold.switchTo`,
/// from the header, its Undo, or the Households list).

@ProviderFor(householdSwitchPending)
final householdSwitchPendingProvider = HouseholdSwitchPendingProvider._();

/// Whether a household switch is in flight (`CurrentHousehold.switchTo`,
/// from the header, its Undo, or the Households list).

final class HouseholdSwitchPendingProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a household switch is in flight (`CurrentHousehold.switchTo`,
  /// from the header, its Undo, or the Households list).
  HouseholdSwitchPendingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdSwitchPendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdSwitchPendingHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return householdSwitchPending(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$householdSwitchPendingHash() =>
    r'3954aa50d1daac78b6b614663f87683e8d6ea5cf';

/// The name of the household a switch in flight is switching to; null when
/// none is, or while the caller's households are not yet known.
///
/// `myHouseholds` reloads during a switch but keeps its previous value, so
/// `.value` is still the list the sheet was built from.

@ProviderFor(householdSwitchTargetName)
final householdSwitchTargetNameProvider = HouseholdSwitchTargetNameProvider._();

/// The name of the household a switch in flight is switching to; null when
/// none is, or while the caller's households are not yet known.
///
/// `myHouseholds` reloads during a switch but keeps its previous value, so
/// `.value` is still the list the sheet was built from.

final class HouseholdSwitchTargetNameProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The name of the household a switch in flight is switching to; null when
  /// none is, or while the caller's households are not yet known.
  ///
  /// `myHouseholds` reloads during a switch but keeps its previous value, so
  /// `.value` is still the list the sheet was built from.
  HouseholdSwitchTargetNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdSwitchTargetNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdSwitchTargetNameHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return householdSwitchTargetName(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$householdSwitchTargetNameHash() =>
    r'a9c4ac7c24ca10a9ee5f7b0470ff773e5d225b28';
