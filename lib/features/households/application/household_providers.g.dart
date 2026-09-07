// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(householdRepository)
final householdRepositoryProvider = HouseholdRepositoryProvider._();

final class HouseholdRepositoryProvider
    extends
        $FunctionalProvider<
          HouseholdRepository,
          HouseholdRepository,
          HouseholdRepository
        >
    with $Provider<HouseholdRepository> {
  HouseholdRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdRepositoryHash();

  @$internal
  @override
  $ProviderElement<HouseholdRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdRepository create(Ref ref) {
    return householdRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdRepository>(value),
    );
  }
}

String _$householdRepositoryHash() =>
    r'7f0573c067c3674a410e97044bce41a0b3412938';

/// The caller's current household, or null if they have not created one.
///
/// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
/// own provider: a different user has a different household, and a signed-out
/// one has none -- but reaching into `features/auth/application/` would be the
/// cross-feature import CLAUDE.md forbids.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation to decide whether onboarding is finished.

@ProviderFor(currentHousehold)
final currentHouseholdProvider = CurrentHouseholdProvider._();

/// The caller's current household, or null if they have not created one.
///
/// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
/// own provider: a different user has a different household, and a signed-out
/// one has none -- but reaching into `features/auth/application/` would be the
/// cross-feature import CLAUDE.md forbids.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation to decide whether onboarding is finished.

final class CurrentHouseholdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Household?>,
          Household?,
          FutureOr<Household?>
        >
    with $FutureModifier<Household?>, $FutureProvider<Household?> {
  /// The caller's current household, or null if they have not created one.
  ///
  /// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
  /// own provider: a different user has a different household, and a signed-out
  /// one has none -- but reaching into `features/auth/application/` would be the
  /// cross-feature import CLAUDE.md forbids.
  ///
  /// `keepAlive` is justified: the router's redirect reads this on every
  /// navigation to decide whether onboarding is finished.
  CurrentHouseholdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentHouseholdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentHouseholdHash();

  @$internal
  @override
  $FutureProviderElement<Household?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Household?> create(Ref ref) {
    return currentHousehold(ref);
  }
}

String _$currentHouseholdHash() => r'fcdf29d5844120bfc7a306ede57a8f800c21d303';

/// Everyone in the caller's household, for the member list.
///
/// Display names depend on `profiles_select_co_member`; without that policy
/// every co-member renders as unknown.

@ProviderFor(householdMembers)
final householdMembersProvider = HouseholdMembersProvider._();

/// Everyone in the caller's household, for the member list.
///
/// Display names depend on `profiles_select_co_member`; without that policy
/// every co-member renders as unknown.

final class HouseholdMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HouseholdMember>>,
          List<HouseholdMember>,
          FutureOr<List<HouseholdMember>>
        >
    with
        $FutureModifier<List<HouseholdMember>>,
        $FutureProvider<List<HouseholdMember>> {
  /// Everyone in the caller's household, for the member list.
  ///
  /// Display names depend on `profiles_select_co_member`; without that policy
  /// every co-member renders as unknown.
  HouseholdMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdMembersHash();

  @$internal
  @override
  $FutureProviderElement<List<HouseholdMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HouseholdMember>> create(Ref ref) {
    return householdMembers(ref);
  }
}

String _$householdMembersHash() => r'da6342bcdf5be05e316d6df64926f0323cb8be64';

/// Invite codes that can still be redeemed, newest first.

@ProviderFor(liveInvites)
final liveInvitesProvider = LiveInvitesProvider._();

/// Invite codes that can still be redeemed, newest first.

final class LiveInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HouseholdInvite>>,
          List<HouseholdInvite>,
          FutureOr<List<HouseholdInvite>>
        >
    with
        $FutureModifier<List<HouseholdInvite>>,
        $FutureProvider<List<HouseholdInvite>> {
  /// Invite codes that can still be redeemed, newest first.
  LiveInvitesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveInvitesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveInvitesHash();

  @$internal
  @override
  $FutureProviderElement<List<HouseholdInvite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HouseholdInvite>> create(Ref ref) {
    return liveInvites(ref);
  }
}

String _$liveInvitesHash() => r'76b21836967f4bdcdea7056cf816bbd88d519f8e';
