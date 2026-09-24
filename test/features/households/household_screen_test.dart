// Phase 6 part 3a -- the household screen's rename affordance.
//
// Providers are overridden rather than mocked -- Riverpod's own override
// mechanism means no mocking package, so CLAUDE.md rule 8 is never
// triggered (app_shell_test.dart's own precedent).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/data/household_repository.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_invite.dart';
import 'package:kitchen_table/features/households/domain/household_member.dart';
import 'package:kitchen_table/features/households/presentation/household_screen.dart';

final AppLocalizations sr = AppLocalizationsSr();

/// `implements`, not `extends` -- the house style (D87's own test file):
/// every unstubbed member throws by omission, so a test that accidentally
/// reaches one fails loudly rather than hitting Supabase.
class _FakeRepo implements HouseholdRepository {
  String? renamedId;
  String? renamedTo;
  List<HouseholdMember> members = const <HouseholdMember>[];
  List<HouseholdInvite> invites = const <HouseholdInvite>[];
  String? removedMemberId;
  int leaveHouseholdCalls = 0;
  int deleteHouseholdCalls = 0;
  String? revokedInviteId;
  AppFailure? nextFailure;

  @override
  Future<void> rename(String id, String name) async {
    renamedId = id;
    renamedTo = name;
  }

  @override
  Future<List<HouseholdMember>> fetchMembers(String householdId) async =>
      members;

  @override
  Future<List<HouseholdInvite>> fetchLiveInvites(String householdId) async =>
      invites;

  @override
  Future<List<Household>> fetchMine() => throw UnimplementedError();

  @override
  Future<Household?> fetchCurrent({
    required String userId,
    void Function()? onReachable,
    void Function()? onUnreachable,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> create(String name) => throw UnimplementedError();

  @override
  Future<HouseholdInvite> createInvite() => throw UnimplementedError();

  @override
  Future<void> redeemInvite(String code) => throw UnimplementedError();

  @override
  Future<void> removeMember(String userId) async {
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    removedMemberId = userId;
  }

  @override
  Future<void> leaveHousehold() async {
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    leaveHouseholdCalls++;
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    revokedInviteId = inviteId;
  }

  @override
  Future<void> deleteHousehold() async {
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    deleteHouseholdCalls++;
  }
}

const String _householdId = 'h1';

Future<void> _pump(
  WidgetTester tester, {
  required _FakeRepo repo,
  required String Function() readName,
  String userId = 'u1',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        householdRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWith(
          (Ref ref) => Stream<String?>.value(userId),
        ),
        // A mutable local read on every rebuild, so the invalidate-then-
        // re-await in HouseholdScreen._rename sees the name HouseholdScreen
        // just wrote, exactly as the real provider would after a confirming
        // re-fetch (household_repository.dart's own doc comment on why
        // `rename` doesn't clear the local cache).
        currentHouseholdProvider.overrideWith(
          (Ref ref) async => Household(
            id: _householdId,
            name: readName(),
            createdBy: 'u1',
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        locale: const Locale('sr'),
        home: const HouseholdScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the edit icon opens the rename dialog',
      (WidgetTester tester) async {
    const String name = 'Test Household';
    await _pump(tester, repo: _FakeRepo(), readName: () => name);

    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(sr.renameHouseholdDialogTitle), findsOneWidget);
  });

  testWidgets('Save writes the trimmed name, and the row shows it',
      (WidgetTester tester) async {
    String name = 'Test Household';
    final _FakeRepo repo = _FakeRepo();
    await _pump(tester, repo: repo, readName: () => name);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '  New Name  ');
    // What HouseholdScreen._rename writes through the repository, and what
    // the confirming re-fetch would return -- the fake stands in for both.
    name = 'New Name';
    await tester.tap(find.widgetWithText(FilledButton, sr.saveButton));
    await tester.pumpAndSettle();

    expect(repo.renamedId, _householdId);
    expect(repo.renamedTo, 'New Name');
    expect(find.text('New Name'), findsOneWidget);
    expect(find.text(sr.householdRenamedSnackbar), findsOneWidget);
  });

  testWidgets('an empty field is refused and writes nothing',
      (WidgetTester tester) async {
    const String name = 'Test Household';
    final _FakeRepo repo = _FakeRepo();
    await _pump(tester, repo: repo, readName: () => name);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.widgetWithText(FilledButton, sr.saveButton));
    await tester.pumpAndSettle();

    expect(find.text(sr.householdNameEmptyError), findsOneWidget);
    expect(repo.renamedId, isNull);
    expect(find.text('Test Household'), findsOneWidget);
  });

  testWidgets('cancelling writes nothing', (WidgetTester tester) async {
    const String name = 'Test Household';
    final _FakeRepo repo = _FakeRepo();
    await _pump(tester, repo: repo, readName: () => name);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Ignored Name');
    await tester.tap(find.widgetWithText(TextButton, sr.cancelButton));
    await tester.pumpAndSettle();

    expect(repo.renamedId, isNull);
    expect(find.text('Test Household'), findsOneWidget);
  });

  group('member row affordances (phase6-part3b)', () {
    testWidgets(
      'the owner sees Remove on another member\'s row and nothing on their '
      'own',
      (WidgetTester tester) async {
        final _FakeRepo repo = _FakeRepo()
          ..members = const <HouseholdMember>[
            HouseholdMember(
                householdId: _householdId,
                userId: 'u1',
                role: HouseholdRole.owner,
                displayName: 'Owner'),
            HouseholdMember(
                householdId: _householdId,
                userId: 'u2',
                role: HouseholdRole.adult,
                displayName: 'Adult'),
          ];
        await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

        expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsNothing);
      },
    );

    testWidgets(
      'an adult sees Leave on their own row and nothing on the owner\'s',
      (WidgetTester tester) async {
        final _FakeRepo repo = _FakeRepo()
          ..members = const <HouseholdMember>[
            HouseholdMember(
                householdId: _householdId,
                userId: 'u1',
                role: HouseholdRole.owner,
                displayName: 'Owner'),
            HouseholdMember(
                householdId: _householdId,
                userId: 'u2',
                role: HouseholdRole.adult,
                displayName: 'Adult'),
          ];
        await _pump(tester, repo: repo, readName: () => 'H', userId: 'u2');

        expect(find.byIcon(Icons.logout), findsOneWidget);
        expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
      },
    );
  });

  group('remove member', () {
    testWidgets('confirming removes and shows a snackbar',
        (WidgetTester tester) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
              householdId: _householdId,
              userId: 'u1',
              role: HouseholdRole.owner,
              displayName: 'Owner'),
          HouseholdMember(
              householdId: _householdId,
              userId: 'u2',
              role: HouseholdRole.adult,
              displayName: 'Adult'),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

      await tester.tap(find.byIcon(Icons.person_remove_outlined));
      await tester.pumpAndSettle();
      expect(find.text(sr.removeMemberDialogTitle), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, sr.removeButton));
      await tester.pumpAndSettle();

      expect(repo.removedMemberId, 'u2');
      expect(find.text(sr.memberRemovedSnackbar), findsOneWidget);
    });

    testWidgets('cancelling removes nothing', (WidgetTester tester) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
              householdId: _householdId,
              userId: 'u1',
              role: HouseholdRole.owner,
              displayName: 'Owner'),
          HouseholdMember(
              householdId: _householdId,
              userId: 'u2',
              role: HouseholdRole.adult,
              displayName: 'Adult'),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

      await tester.tap(find.byIcon(Icons.person_remove_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, sr.cancelButton));
      await tester.pumpAndSettle();

      expect(repo.removedMemberId, isNull);
    });
  });

  group('leave household', () {
    testWidgets('confirming calls leaveHousehold', (WidgetTester tester) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
              householdId: _householdId,
              userId: 'u1',
              role: HouseholdRole.owner,
              displayName: 'Owner'),
          HouseholdMember(
              householdId: _householdId,
              userId: 'u2',
              role: HouseholdRole.adult,
              displayName: 'Adult'),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u2');

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.text(sr.leaveHouseholdDialogTitle), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, sr.leaveButton));
      await tester.pumpAndSettle();

      expect(repo.leaveHouseholdCalls, 1);
    });

    testWidgets('cancelling leaves nothing called', (WidgetTester tester) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
              householdId: _householdId,
              userId: 'u1',
              role: HouseholdRole.owner,
              displayName: 'Owner'),
          HouseholdMember(
              householdId: _householdId,
              userId: 'u2',
              role: HouseholdRole.adult,
              displayName: 'Adult'),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u2');

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, sr.cancelButton));
      await tester.pumpAndSettle();

      expect(repo.leaveHouseholdCalls, 0);
    });
  });

  group('delete household', () {
    testWidgets(
      'the owner sees the row and confirming calls deleteHousehold once',
      (WidgetTester tester) async {
        final _FakeRepo repo = _FakeRepo()
          ..members = const <HouseholdMember>[
            HouseholdMember(
                householdId: _householdId,
                userId: 'u1',
                role: HouseholdRole.owner,
                displayName: 'Owner'),
            HouseholdMember(
                householdId: _householdId,
                userId: 'u2',
                role: HouseholdRole.adult,
                displayName: 'Adult'),
          ];
        await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

        expect(find.text(sr.deleteHouseholdButton), findsOneWidget);

        await tester.tap(find.text(sr.deleteHouseholdButton));
        await tester.pumpAndSettle();
        expect(find.text(sr.deleteHouseholdDialogTitle), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, sr.deleteButton));
        await tester.pumpAndSettle();

        expect(repo.deleteHouseholdCalls, 1);
      },
    );

    testWidgets('cancelling calls nothing', (WidgetTester tester) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
              householdId: _householdId,
              userId: 'u1',
              role: HouseholdRole.owner,
              displayName: 'Owner'),
          HouseholdMember(
              householdId: _householdId,
              userId: 'u2',
              role: HouseholdRole.adult,
              displayName: 'Adult'),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

      await tester.tap(find.text(sr.deleteHouseholdButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, sr.cancelButton));
      await tester.pumpAndSettle();

      expect(repo.deleteHouseholdCalls, 0);
    });

    testWidgets('an adult does not see the delete row at all',
        (WidgetTester tester) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
              householdId: _householdId,
              userId: 'u1',
              role: HouseholdRole.owner,
              displayName: 'Owner'),
          HouseholdMember(
              householdId: _householdId,
              userId: 'u2',
              role: HouseholdRole.adult,
              displayName: 'Adult'),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u2');

      expect(find.text(sr.deleteHouseholdButton), findsNothing);
    });
  });

  group('revoke invite', () {
    testWidgets(
      'tapping revoke calls revokeInvite immediately -- no confirm dialog',
      (WidgetTester tester) async {
        final _FakeRepo repo = _FakeRepo()
          ..invites = <HouseholdInvite>[
            HouseholdInvite(
              id: 'inv1',
              householdId: _householdId,
              code: '123456',
              createdBy: 'u1',
              createdAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(days: 1)),
            ),
          ];
        await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

        await tester.tap(find.byIcon(Icons.link_off));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(repo.revokedInviteId, 'inv1');
        expect(find.text(sr.inviteRevokedSnackbar), findsOneWidget);
      },
    );
  });
}
