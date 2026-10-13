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

String _$currentHouseholdHash() => r'e3b8598bb04b7e5fdaae2d1c4e4272be8f4d8861';

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

/// The household a [CurrentHousehold.switchTo] is switching to, or null when
/// none is in flight (phase9-household-switch-loading).
///
/// Owned by `switchTo` rather than by whoever called it: the header, its
/// Undo and the Households list all switch, and all three must put every tab
/// into the same loading state. Crosses to other features only as
/// `core/household/current_household.dart`'s narrow facts.
///
/// `keepAlive`, because `switchTo` writes it whether or not anything is
/// listening yet.

@ProviderFor(HouseholdSwitchInFlight)
final householdSwitchInFlightProvider = HouseholdSwitchInFlightProvider._();

/// The household a [CurrentHousehold.switchTo] is switching to, or null when
/// none is in flight (phase9-household-switch-loading).
///
/// Owned by `switchTo` rather than by whoever called it: the header, its
/// Undo and the Households list all switch, and all three must put every tab
/// into the same loading state. Crosses to other features only as
/// `core/household/current_household.dart`'s narrow facts.
///
/// `keepAlive`, because `switchTo` writes it whether or not anything is
/// listening yet.
final class HouseholdSwitchInFlightProvider
    extends $NotifierProvider<HouseholdSwitchInFlight, String?> {
  /// The household a [CurrentHousehold.switchTo] is switching to, or null when
  /// none is in flight (phase9-household-switch-loading).
  ///
  /// Owned by `switchTo` rather than by whoever called it: the header, its
  /// Undo and the Households list all switch, and all three must put every tab
  /// into the same loading state. Crosses to other features only as
  /// `core/household/current_household.dart`'s narrow facts.
  ///
  /// `keepAlive`, because `switchTo` writes it whether or not anything is
  /// listening yet.
  HouseholdSwitchInFlightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdSwitchInFlightProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdSwitchInFlightHash();

  @$internal
  @override
  HouseholdSwitchInFlight create() => HouseholdSwitchInFlight();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$householdSwitchInFlightHash() =>
    r'52577f8433af62a9b50aded03ab4121344e3d020';

/// The household a [CurrentHousehold.switchTo] is switching to, or null when
/// none is in flight (phase9-household-switch-loading).
///
/// Owned by `switchTo` rather than by whoever called it: the header, its
/// Undo and the Households list all switch, and all three must put every tab
/// into the same loading state. Crosses to other features only as
/// `core/household/current_household.dart`'s narrow facts.
///
/// `keepAlive`, because `switchTo` writes it whether or not anything is
/// listening yet.

abstract class _$HouseholdSwitchInFlight extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Every household the caller belongs to, in the order they joined, with
/// their role in it and its member count -- the Households list.
///
/// Its own membership query (`fetchMemberships`), not `fetchCurrent`'s
/// oldest-first rows: that order is D169's fallback and stays as it is.
/// Network-only, like `fetchMine` (D88 caches the current row only).
///
/// Watches [currentHouseholdProvider] only to refresh after create, join,
/// leave, delete, rename or a switch -- each of those re-reads it.

@ProviderFor(myHouseholds)
final myHouseholdsProvider = MyHouseholdsProvider._();

/// Every household the caller belongs to, in the order they joined, with
/// their role in it and its member count -- the Households list.
///
/// Its own membership query (`fetchMemberships`), not `fetchCurrent`'s
/// oldest-first rows: that order is D169's fallback and stays as it is.
/// Network-only, like `fetchMine` (D88 caches the current row only).
///
/// Watches [currentHouseholdProvider] only to refresh after create, join,
/// leave, delete, rename or a switch -- each of those re-reads it.

final class MyHouseholdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HouseholdMembership>>,
          List<HouseholdMembership>,
          FutureOr<List<HouseholdMembership>>
        >
    with
        $FutureModifier<List<HouseholdMembership>>,
        $FutureProvider<List<HouseholdMembership>> {
  /// Every household the caller belongs to, in the order they joined, with
  /// their role in it and its member count -- the Households list.
  ///
  /// Its own membership query (`fetchMemberships`), not `fetchCurrent`'s
  /// oldest-first rows: that order is D169's fallback and stays as it is.
  /// Network-only, like `fetchMine` (D88 caches the current row only).
  ///
  /// Watches [currentHouseholdProvider] only to refresh after create, join,
  /// leave, delete, rename or a switch -- each of those re-reads it.
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
  $FutureProviderElement<List<HouseholdMembership>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HouseholdMembership>> create(Ref ref) {
    return myHouseholds(ref);
  }
}

String _$myHouseholdsHash() => r'2414cad7cfee6c32d5318582b0d166c25ec184fa';

/// Where the caller would land after leaving or deleting [householdId]: the
/// most recently used other household on this device, else the first other
/// one in join order, else null (D174, `nextHouseholdAfter`).
///
/// Resolved before the confirm dialog opens, so the dialog can name it and
/// the post-confirm `switchTo` lands exactly there -- not on
/// `fetchCurrent`'s oldest-first fallback (D169), which may differ.

@ProviderFor(nextHouseholdAfterLeaving)
final nextHouseholdAfterLeavingProvider = NextHouseholdAfterLeavingFamily._();

/// Where the caller would land after leaving or deleting [householdId]: the
/// most recently used other household on this device, else the first other
/// one in join order, else null (D174, `nextHouseholdAfter`).
///
/// Resolved before the confirm dialog opens, so the dialog can name it and
/// the post-confirm `switchTo` lands exactly there -- not on
/// `fetchCurrent`'s oldest-first fallback (D169), which may differ.

final class NextHouseholdAfterLeavingProvider
    extends
        $FunctionalProvider<
          AsyncValue<HouseholdMembership?>,
          HouseholdMembership?,
          FutureOr<HouseholdMembership?>
        >
    with
        $FutureModifier<HouseholdMembership?>,
        $FutureProvider<HouseholdMembership?> {
  /// Where the caller would land after leaving or deleting [householdId]: the
  /// most recently used other household on this device, else the first other
  /// one in join order, else null (D174, `nextHouseholdAfter`).
  ///
  /// Resolved before the confirm dialog opens, so the dialog can name it and
  /// the post-confirm `switchTo` lands exactly there -- not on
  /// `fetchCurrent`'s oldest-first fallback (D169), which may differ.
  NextHouseholdAfterLeavingProvider._({
    required NextHouseholdAfterLeavingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'nextHouseholdAfterLeavingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nextHouseholdAfterLeavingHash();

  @override
  String toString() {
    return r'nextHouseholdAfterLeavingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<HouseholdMembership?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HouseholdMembership?> create(Ref ref) {
    final argument = this.argument as String;
    return nextHouseholdAfterLeaving(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NextHouseholdAfterLeavingProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nextHouseholdAfterLeavingHash() =>
    r'a10c34c85ec792e6401f2688b0483a6cfabc3db6';

/// Where the caller would land after leaving or deleting [householdId]: the
/// most recently used other household on this device, else the first other
/// one in join order, else null (D174, `nextHouseholdAfter`).
///
/// Resolved before the confirm dialog opens, so the dialog can name it and
/// the post-confirm `switchTo` lands exactly there -- not on
/// `fetchCurrent`'s oldest-first fallback (D169), which may differ.

final class NextHouseholdAfterLeavingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<HouseholdMembership?>, String> {
  NextHouseholdAfterLeavingFamily._()
    : super(
        retry: null,
        name: r'nextHouseholdAfterLeavingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Where the caller would land after leaving or deleting [householdId]: the
  /// most recently used other household on this device, else the first other
  /// one in join order, else null (D174, `nextHouseholdAfter`).
  ///
  /// Resolved before the confirm dialog opens, so the dialog can name it and
  /// the post-confirm `switchTo` lands exactly there -- not on
  /// `fetchCurrent`'s oldest-first fallback (D169), which may differ.

  NextHouseholdAfterLeavingProvider call(String householdId) =>
      NextHouseholdAfterLeavingProvider._(argument: householdId, from: this);

  @override
  String toString() => r'nextHouseholdAfterLeavingProvider';
}

/// [householdId], if it is one of the caller's households, else null -- the
/// Household screen's header, which may show a household other than the
/// current one.

@ProviderFor(householdById)
final householdByIdProvider = HouseholdByIdFamily._();

/// [householdId], if it is one of the caller's households, else null -- the
/// Household screen's header, which may show a household other than the
/// current one.

final class HouseholdByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Household?>,
          Household?,
          FutureOr<Household?>
        >
    with $FutureModifier<Household?>, $FutureProvider<Household?> {
  /// [householdId], if it is one of the caller's households, else null -- the
  /// Household screen's header, which may show a household other than the
  /// current one.
  HouseholdByIdProvider._({
    required HouseholdByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'householdByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$householdByIdHash();

  @override
  String toString() {
    return r'householdByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Household?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Household?> create(Ref ref) {
    final argument = this.argument as String;
    return householdById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HouseholdByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$householdByIdHash() => r'77cdd5eb4ff2e06dc6553d078528a903f4c47d1f';

/// [householdId], if it is one of the caller's households, else null -- the
/// Household screen's header, which may show a household other than the
/// current one.

final class HouseholdByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Household?>, String> {
  HouseholdByIdFamily._()
    : super(
        retry: null,
        name: r'householdByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [householdId], if it is one of the caller's households, else null -- the
  /// Household screen's header, which may show a household other than the
  /// current one.

  HouseholdByIdProvider call(String householdId) =>
      HouseholdByIdProvider._(argument: householdId, from: this);

  @override
  String toString() => r'householdByIdProvider';
}

/// Everyone in [householdId], for the member list.
///
/// Display names depend on `profiles_select_co_member`; without that policy
/// every co-member renders as unknown.

@ProviderFor(householdMembers)
final householdMembersProvider = HouseholdMembersFamily._();

/// Everyone in [householdId], for the member list.
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
  /// Everyone in [householdId], for the member list.
  ///
  /// Display names depend on `profiles_select_co_member`; without that policy
  /// every co-member renders as unknown.
  HouseholdMembersProvider._({
    required HouseholdMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'householdMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$householdMembersHash();

  @override
  String toString() {
    return r'householdMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HouseholdMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HouseholdMember>> create(Ref ref) {
    final argument = this.argument as String;
    return householdMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HouseholdMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$householdMembersHash() => r'c1777ffc62c1d0f728739dcd70a9714c27d9387b';

/// Everyone in [householdId], for the member list.
///
/// Display names depend on `profiles_select_co_member`; without that policy
/// every co-member renders as unknown.

final class HouseholdMembersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<HouseholdMember>>, String> {
  HouseholdMembersFamily._()
    : super(
        retry: null,
        name: r'householdMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everyone in [householdId], for the member list.
  ///
  /// Display names depend on `profiles_select_co_member`; without that policy
  /// every co-member renders as unknown.

  HouseholdMembersProvider call(String householdId) =>
      HouseholdMembersProvider._(argument: householdId, from: this);

  @override
  String toString() => r'householdMembersProvider';
}

/// [householdId]'s invite codes that can still be redeemed, newest first.

@ProviderFor(liveInvites)
final liveInvitesProvider = LiveInvitesFamily._();

/// [householdId]'s invite codes that can still be redeemed, newest first.

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
  /// [householdId]'s invite codes that can still be redeemed, newest first.
  LiveInvitesProvider._({
    required LiveInvitesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'liveInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveInvitesHash();

  @override
  String toString() {
    return r'liveInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HouseholdInvite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HouseholdInvite>> create(Ref ref) {
    final argument = this.argument as String;
    return liveInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveInvitesHash() => r'3c344bf062b88e3cbbc69fca806c6780cc85c0cf';

/// [householdId]'s invite codes that can still be redeemed, newest first.

final class LiveInvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<HouseholdInvite>>, String> {
  LiveInvitesFamily._()
    : super(
        retry: null,
        name: r'liveInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [householdId]'s invite codes that can still be redeemed, newest first.

  LiveInvitesProvider call(String householdId) =>
      LiveInvitesProvider._(argument: householdId, from: this);

  @override
  String toString() => r'liveInvitesProvider';
}
