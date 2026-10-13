import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_membership.dart';

import 'fake_household_repository.dart';
import 'fixed_current_household.dart';

/// A [FakeHouseholdRepository] that can hold a switch open
/// (phase9-household-switch-loading): while [currentHold] is set,
/// `fetchCurrent` waits on it; while [membershipsHold] is set,
/// `fetchMemberships` does. [selectFailure] makes `select` throw, the way a
/// failed switch does before anything reloads.
class HeldHouseholdRepository extends FakeHouseholdRepository {
  HeldHouseholdRepository(super.households);

  Completer<void>? currentHold;
  Completer<void>? membershipsHold;
  AppFailure? selectFailure;

  @override
  Future<Household?> fetchCurrent({
    required String userId,
    void Function()? onReachable,
    void Function()? onUnreachable,
  }) async {
    final Completer<void>? hold = currentHold;
    if (hold != null) await hold.future;
    return super.fetchCurrent(userId: userId);
  }

  @override
  Future<List<HouseholdMembership>> fetchMemberships({
    required String userId,
  }) async {
    final Completer<void>? hold = membershipsHold;
    if (hold != null) await hold.future;
    return super.fetchMemberships(userId: userId);
  }

  @override
  Future<void> select({
    required String userId,
    required String householdId,
  }) async {
    final AppFailure? f = selectFailure;
    if (f != null) throw f;
    return super.select(userId: userId, householdId: householdId);
  }
}

/// Signed in as `u1`, households from [repo], `currentHouseholdProvider`
/// reading [repo] on every rebuild -- what a widget test needs for a real
/// `switchTo` to run end to end.
List<Override> householdSwitchOverrides(FakeHouseholdRepository repo) =>
    <Override>[
      householdRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWith(
        (Ref ref) => Stream<String?>.value('u1'),
      ),
      currentHouseholdProvider.overrideWith(
        () => FixedCurrentHousehold(() => repo.fetchCurrent(userId: 'u1')),
      ),
    ];
