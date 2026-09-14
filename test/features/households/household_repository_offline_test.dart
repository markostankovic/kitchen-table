// Phase 2 part 7 (D87-D90) -- HouseholdRepository.fetchCurrent's read order,
// proved against a real HouseholdRepository/LocalHouseholdDataSource over
// NativeDatabase.memory() and a hand-written fake for the network edge (no
// mocking package, the house style, on recipe_repository_offline_test.dart's
// precedent).
//
// This is the test D87 is a report about the absence of:
// IngredientRepository.fetchUnitCatalog() has the same try/on NetworkFailure
// shape and has never had one, because there was never a seam to fake
// SupabaseClient against. RemoteHouseholdDataSource.fetchMineRows() is that
// seam.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/features/households/data/household_repository.dart';
import 'package:kitchen_table/features/households/data/local_household_datasource.dart';
import 'package:kitchen_table/features/households/data/remote_household_datasource.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_invite.dart';
import 'package:kitchen_table/features/households/domain/household_member.dart';

Map<String, dynamic> _row({String id = 'h1', String? deletedAt}) =>
    <String, dynamic>{
      'id': id,
      'name': 'Household $id',
      'created_by': 'u1',
      'deleted_at': deletedAt,
    };

/// Controls exactly the network calls the methods under test make.
/// `implements` rather than `extends`: every other member throws by
/// omission, so a test that accidentally reached one fails loudly.
class _FakeRemote implements RemoteHouseholdDataSource {
  List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  AppFailure? nextFailure;
  int fetchMineRowsCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchMineRows() async {
    fetchMineRowsCalls++;
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    return rows;
  }

  @override
  Future<String> create(String name) async => 'new-household-id';

  @override
  Future<List<HouseholdMember>> fetchMembers(String householdId) =>
      throw UnimplementedError();

  @override
  Future<List<HouseholdInvite>> fetchLiveInvites(String householdId) =>
      throw UnimplementedError();

  @override
  Future<HouseholdInvite> createInvite() => throw UnimplementedError();

  @override
  Future<void> redeemInvite(String code) async {}
}

void main() {
  late AppDatabase db;
  late _FakeRemote remote;
  late HouseholdRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = _FakeRemote();
    repo = HouseholdRepository(remote, LocalHouseholdDataSource(db));
  });

  tearDown(() => db.close());

  group('fetchCurrent', () {
    test(
      'network success returns the server\'s answer and writes it through',
      () async {
        remote.rows = <Map<String, dynamic>>[_row(id: 'h1')];

        bool reachable = false;
        final Household? household = await repo.fetchCurrent(
          userId: 'u1',
          onReachable: () => reachable = true,
        );

        expect(household?.id, 'h1');
        expect(reachable, isTrue);

        final Map<String, dynamic>? cached =
            await LocalHouseholdDataSource(db).readCurrent('u1');
        expect(cached?['id'], 'h1');
      },
    );

    test(
      'a NetworkFailure with a warm cache returns the cached household and '
      'reports unreachable',
      () async {
        // Warm the cache with a first, successful fetch.
        remote.rows = <Map<String, dynamic>>[_row(id: 'h1')];
        await repo.fetchCurrent(userId: 'u1');

        remote.nextFailure = const NetworkFailure();
        bool unreachable = false;
        final Household? household = await repo.fetchCurrent(
          userId: 'u1',
          onUnreachable: () => unreachable = true,
        );

        expect(household?.id, 'h1');
        expect(unreachable, isTrue);
      },
    );

    test('a NetworkFailure with a cold cache rethrows', () async {
      remote.nextFailure = const NetworkFailure();

      await expectLater(
        repo.fetchCurrent(userId: 'u1'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test(
      'a fetch that returns no households clears any cached row, and the '
      'result reads as no household rather than a stale one',
      () async {
        // Warm the cache first.
        remote.rows = <Map<String, dynamic>>[_row(id: 'h1')];
        await repo.fetchCurrent(userId: 'u1');

        // The caller left every household since.
        remote.rows = <Map<String, dynamic>>[];
        final Household? household = await repo.fetchCurrent(userId: 'u1');

        expect(household, isNull);
        expect(
          await LocalHouseholdDataSource(db).readCurrent('u1'),
          isNull,
        );

        // And offline, that absence now reads honestly rather than
        // resurrecting the household that used to be cached.
        remote.nextFailure = const NetworkFailure();
        await expectLater(
          repo.fetchCurrent(userId: 'u1'),
          throwsA(isA<NetworkFailure>()),
        );
      },
    );

    test(
      'a non-NetworkFailure does not fall back to a populated cache',
      () async {
        remote.rows = <Map<String, dynamic>>[_row(id: 'h1')];
        await repo.fetchCurrent(userId: 'u1');

        remote.nextFailure = const UnauthorizedFailure();
        await expectLater(
          repo.fetchCurrent(userId: 'u1'),
          throwsA(isA<UnauthorizedFailure>()),
        );
      },
    );

    test(
      'the oldest household wins (D52), and that is the one cached',
      () async {
        remote.rows = <Map<String, dynamic>>[
          _row(id: 'oldest'),
          _row(id: 'newer'),
        ];

        final Household? household = await repo.fetchCurrent(userId: 'u1');
        expect(household?.id, 'oldest');

        final Map<String, dynamic>? cached =
            await LocalHouseholdDataSource(db).readCurrent('u1');
        expect(cached?['id'], 'oldest');
      },
    );

    test('a user\'s stale cache is never served to a different user',
        () async {
      remote.rows = <Map<String, dynamic>>[_row(id: 'h1')];
      await repo.fetchCurrent(userId: 'u1');

      remote.nextFailure = const NetworkFailure();
      await expectLater(
        repo.fetchCurrent(userId: 'u2'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('create / redeemInvite clear the cache (D88)', () {
    test(
      'a successful create clears the cache; a subsequent NetworkFailure '
      'rethrows rather than resurrecting the old household',
      () async {
        remote.rows = <Map<String, dynamic>>[_row(id: 'old')];
        await repo.fetchCurrent(userId: 'u1');

        await repo.create('New household');

        remote.nextFailure = const NetworkFailure();
        await expectLater(
          repo.fetchCurrent(userId: 'u1'),
          throwsA(isA<NetworkFailure>()),
        );
      },
    );

    test(
      'a successful redeemInvite clears the cache; a subsequent '
      'NetworkFailure rethrows rather than resurrecting the old household',
      () async {
        remote.rows = <Map<String, dynamic>>[_row(id: 'old')];
        await repo.fetchCurrent(userId: 'u1');

        await repo.redeemInvite('123456');

        remote.nextFailure = const NetworkFailure();
        await expectLater(
          repo.fetchCurrent(userId: 'u1'),
          throwsA(isA<NetworkFailure>()),
        );
      },
    );
  });
}
