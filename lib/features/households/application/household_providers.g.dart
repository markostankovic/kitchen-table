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
    r'6395757d69fe07446cc772ce1d1022c9cbb1f5a6';

/// The caller's current household, or null if they have not created one.
///
/// "Current" is the household last selected on this device, else the oldest
/// (`HouseholdRepository.fetchCurrent`, D169). [switchTo] changes it.
///
/// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
/// own provider: a different user has a different household, and a signed-out
/// one has none -- but reaching into `features/auth/application/` would be the
/// cross-feature import CLAUDE.md forbids.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation to decide whether onboarding is finished.
///
/// Passes [userId] into `fetchCurrent` rather than letting the repository
/// read `Supabase.instance.client.auth.currentUser` itself (Phase 2 part 7,
/// D87, D88): `currentUserIdProvider` is already the one definition of "who
/// is signed in" this app keeps, and a second one inside `data/` would be
/// exactly the duplication that provider exists to prevent. Reports
/// reachability into `networkStatusProvider`, on the three screen providers'
/// own precedent (`RecipeList`, `MealPlanEditor`, `CurrentShoppingList`) --
/// this is what makes the global offline banner reachable on a COLD start at
/// all: today its three producers all sit behind this same gate.

@ProviderFor(CurrentHousehold)
final currentHouseholdProvider = CurrentHouseholdProvider._();

/// The caller's current household, or null if they have not created one.
///
/// "Current" is the household last selected on this device, else the oldest
/// (`HouseholdRepository.fetchCurrent`, D169). [switchTo] changes it.
///
/// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
/// own provider: a different user has a different household, and a signed-out
/// one has none -- but reaching into `features/auth/application/` would be the
/// cross-feature import CLAUDE.md forbids.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation to decide whether onboarding is finished.
///
/// Passes [userId] into `fetchCurrent` rather than letting the repository
/// read `Supabase.instance.client.auth.currentUser` itself (Phase 2 part 7,
/// D87, D88): `currentUserIdProvider` is already the one definition of "who
/// is signed in" this app keeps, and a second one inside `data/` would be
/// exactly the duplication that provider exists to prevent. Reports
/// reachability into `networkStatusProvider`, on the three screen providers'
/// own precedent (`RecipeList`, `MealPlanEditor`, `CurrentShoppingList`) --
/// this is what makes the global offline banner reachable on a COLD start at
/// all: today its three producers all sit behind this same gate.
final class CurrentHouseholdProvider
    extends $AsyncNotifierProvider<CurrentHousehold, Household?> {
  /// The caller's current household, or null if they have not created one.
  ///
  /// "Current" is the household last selected on this device, else the oldest
  /// (`HouseholdRepository.fetchCurrent`, D169). [switchTo] changes it.
  ///
  /// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
  /// own provider: a different user has a different household, and a signed-out
  /// one has none -- but reaching into `features/auth/application/` would be the
  /// cross-feature import CLAUDE.md forbids.
  ///
  /// `keepAlive` is justified: the router's redirect reads this on every
  /// navigation to decide whether onboarding is finished.
  ///
  /// Passes [userId] into `fetchCurrent` rather than letting the repository
  /// read `Supabase.instance.client.auth.currentUser` itself (Phase 2 part 7,
  /// D87, D88): `currentUserIdProvider` is already the one definition of "who
  /// is signed in" this app keeps, and a second one inside `data/` would be
  /// exactly the duplication that provider exists to prevent. Reports
  /// reachability into `networkStatusProvider`, on the three screen providers'
  /// own precedent (`RecipeList`, `MealPlanEditor`, `CurrentShoppingList`) --
  /// this is what makes the global offline banner reachable on a COLD start at
  /// all: today its three producers all sit behind this same gate.
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
  CurrentHousehold create() => CurrentHousehold();
}

String _$currentHouseholdHash() => r'9a208d87b1ef2ee04e664fd2bc983ac06789266a';

/// The caller's current household, or null if they have not created one.
///
/// "Current" is the household last selected on this device, else the oldest
/// (`HouseholdRepository.fetchCurrent`, D169). [switchTo] changes it.
///
/// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
/// own provider: a different user has a different household, and a signed-out
/// one has none -- but reaching into `features/auth/application/` would be the
/// cross-feature import CLAUDE.md forbids.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation to decide whether onboarding is finished.
///
/// Passes [userId] into `fetchCurrent` rather than letting the repository
/// read `Supabase.instance.client.auth.currentUser` itself (Phase 2 part 7,
/// D87, D88): `currentUserIdProvider` is already the one definition of "who
/// is signed in" this app keeps, and a second one inside `data/` would be
/// exactly the duplication that provider exists to prevent. Reports
/// reachability into `networkStatusProvider`, on the three screen providers'
/// own precedent (`RecipeList`, `MealPlanEditor`, `CurrentShoppingList`) --
/// this is what makes the global offline banner reachable on a COLD start at
/// all: today its three producers all sit behind this same gate.

abstract class _$CurrentHousehold extends $AsyncNotifier<Household?> {
  FutureOr<Household?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Household?>, Household?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Household?>, Household?>,
              AsyncValue<Household?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Every household the caller belongs to, oldest first, for slice C's
/// household picker (multi-household-b). Nothing reads it yet.
///
/// Watches [currentHouseholdProvider] only to refresh after create, join,
/// leave, delete or a switch -- each of those re-reads it.

@ProviderFor(myHouseholds)
final myHouseholdsProvider = MyHouseholdsProvider._();

/// Every household the caller belongs to, oldest first, for slice C's
/// household picker (multi-household-b). Nothing reads it yet.
///
/// Watches [currentHouseholdProvider] only to refresh after create, join,
/// leave, delete or a switch -- each of those re-reads it.

final class MyHouseholdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Household>>,
          List<Household>,
          FutureOr<List<Household>>
        >
    with $FutureModifier<List<Household>>, $FutureProvider<List<Household>> {
  /// Every household the caller belongs to, oldest first, for slice C's
  /// household picker (multi-household-b). Nothing reads it yet.
  ///
  /// Watches [currentHouseholdProvider] only to refresh after create, join,
  /// leave, delete or a switch -- each of those re-reads it.
  MyHouseholdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myHouseholdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myHouseholdsHash();

  @$internal
  @override
  $FutureProviderElement<List<Household>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Household>> create(Ref ref) {
    return myHouseholds(ref);
  }
}

String _$myHouseholdsHash() => r'ed75be9815de8a73b28e1991749bae2e9f19975f';

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
