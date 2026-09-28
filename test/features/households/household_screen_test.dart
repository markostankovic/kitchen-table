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
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/theme/kitchen_colors.dart';
import 'package:kitchen_table/core/widgets/app_monogram_tile.dart';
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
  }) => throw UnimplementedError();

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
          (Ref ref) async =>
              Household(id: _householdId, name: readName(), createdBy: 'u1'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        locale: const Locale('sr'),
        home: const HouseholdScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const List<HouseholdMember> _ownerAndAdult = <HouseholdMember>[
  HouseholdMember(
    householdId: _householdId,
    userId: 'u1',
    role: HouseholdRole.owner,
    displayName: 'Owner',
  ),
  HouseholdMember(
    householdId: _householdId,
    userId: 'u2',
    role: HouseholdRole.adult,
    displayName: 'Adult',
  ),
];

HouseholdInvite _invite() => HouseholdInvite(
  id: 'inv1',
  householdId: _householdId,
  code: '123456',
  createdBy: 'u1',
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(days: 1)),
);

/// The owner's path to Remove: the overflow on the other member's row, then
/// its one item.
Future<void> _openRemove(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text(sr.removeMemberMenuItem));
  await tester.pumpAndSettle();
}

/// The bottom destructive row sits below the fold on the default test
/// surface, so scroll it into view before tapping.
Future<void> _tapBottomRow(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// A destructive confirm is a text button in `KitchenColors.destructive`,
/// never a fill.
void _expectDestructiveTextButton(WidgetTester tester, String label) {
  final Finder button = find.widgetWithText(TextButton, label);
  expect(button, findsOneWidget);
  final BuildContext context = tester.element(button);
  final Color destructive = Theme.of(context)
      .extension<KitchenColors>()!
      .destructive;
  expect(
    tester
        .widget<TextButton>(button)
        .style
        ?.foregroundColor
        ?.resolve(<WidgetState>{}),
    destructive,
  );
  expect(find.widgetWithText(FilledButton, label), findsNothing);
}

void main() {
  testWidgets('the edit icon opens the rename dialog', (
    WidgetTester tester,
  ) async {
    const String name = 'Test Household';
    await _pump(tester, repo: _FakeRepo(), readName: () => name);

    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(sr.renameHouseholdDialogTitle), findsOneWidget);
  });

  testWidgets('Save writes the trimmed name, and the row shows it', (
    WidgetTester tester,
  ) async {
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

  testWidgets('an empty field is refused and writes nothing', (
    WidgetTester tester,
  ) async {
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
      'the owner sees the overflow on another member\'s row, nothing on '
      'their own, and no Leave row',
      (WidgetTester tester) async {
        final _FakeRepo repo = _FakeRepo()
          ..members = const <HouseholdMember>[
            HouseholdMember(
              householdId: _householdId,
              userId: 'u1',
              role: HouseholdRole.owner,
              displayName: 'Owner',
            ),
            HouseholdMember(
              householdId: _householdId,
              userId: 'u2',
              role: HouseholdRole.adult,
              displayName: 'Adult',
            ),
          ];
        await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
        expect(find.text(sr.leaveHouseholdButton), findsNothing);
      },
    );

    testWidgets('an adult sees the Leave row, no overflow and no Delete', (
      WidgetTester tester,
    ) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
            householdId: _householdId,
            userId: 'u1',
            role: HouseholdRole.owner,
            displayName: 'Owner',
          ),
          HouseholdMember(
            householdId: _householdId,
            userId: 'u2',
            role: HouseholdRole.adult,
            displayName: 'Adult',
          ),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u2');

      expect(find.text(sr.leaveHouseholdButton), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.text(sr.deleteHouseholdButton), findsNothing);
    });
  });

  group('remove member', () {
    testWidgets('confirming removes and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
            householdId: _householdId,
            userId: 'u1',
            role: HouseholdRole.owner,
            displayName: 'Owner',
          ),
          HouseholdMember(
            householdId: _householdId,
            userId: 'u2',
            role: HouseholdRole.adult,
            displayName: 'Adult',
          ),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

      await _openRemove(tester);
      expect(find.text(sr.removeMemberDialogTitle), findsOneWidget);

      _expectDestructiveTextButton(tester, sr.removeButton);
      await tester.tap(find.widgetWithText(TextButton, sr.removeButton));
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
            displayName: 'Owner',
          ),
          HouseholdMember(
            householdId: _householdId,
            userId: 'u2',
            role: HouseholdRole.adult,
            displayName: 'Adult',
          ),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

      await _openRemove(tester);
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
            displayName: 'Owner',
          ),
          HouseholdMember(
            householdId: _householdId,
            userId: 'u2',
            role: HouseholdRole.adult,
            displayName: 'Adult',
          ),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u2');

      await _tapBottomRow(tester, sr.leaveHouseholdButton);
      expect(find.text(sr.leaveHouseholdDialogTitle), findsOneWidget);

      _expectDestructiveTextButton(tester, sr.leaveButton);
      await tester.tap(find.widgetWithText(TextButton, sr.leaveButton));
      await tester.pumpAndSettle();

      expect(repo.leaveHouseholdCalls, 1);
    });

    testWidgets('cancelling leaves nothing called', (
      WidgetTester tester,
    ) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
            householdId: _householdId,
            userId: 'u1',
            role: HouseholdRole.owner,
            displayName: 'Owner',
          ),
          HouseholdMember(
            householdId: _householdId,
            userId: 'u2',
            role: HouseholdRole.adult,
            displayName: 'Adult',
          ),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u2');

      await _tapBottomRow(tester, sr.leaveHouseholdButton);
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
              displayName: 'Owner',
            ),
            HouseholdMember(
              householdId: _householdId,
              userId: 'u2',
              role: HouseholdRole.adult,
              displayName: 'Adult',
            ),
          ];
        await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

        expect(find.text(sr.deleteHouseholdButton), findsOneWidget);

        await _tapBottomRow(tester, sr.deleteHouseholdButton);
        expect(find.text(sr.deleteHouseholdDialogTitle), findsOneWidget);

        _expectDestructiveTextButton(tester, sr.deleteButton);
        await tester.tap(find.widgetWithText(TextButton, sr.deleteButton));
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
            displayName: 'Owner',
          ),
          HouseholdMember(
            householdId: _householdId,
            userId: 'u2',
            role: HouseholdRole.adult,
            displayName: 'Adult',
          ),
        ];
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

      await _tapBottomRow(tester, sr.deleteHouseholdButton);
      await tester.tap(find.widgetWithText(TextButton, sr.cancelButton));
      await tester.pumpAndSettle();

      expect(repo.deleteHouseholdCalls, 0);
    });

    testWidgets('an adult does not see the delete row at all', (
      WidgetTester tester,
    ) async {
      final _FakeRepo repo = _FakeRepo()
        ..members = const <HouseholdMember>[
          HouseholdMember(
            householdId: _householdId,
            userId: 'u1',
            role: HouseholdRole.owner,
            displayName: 'Owner',
          ),
          HouseholdMember(
            householdId: _householdId,
            userId: 'u2',
            role: HouseholdRole.adult,
            displayName: 'Adult',
          ),
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

        await tester.tap(find.text(sr.revokeInviteButton));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(repo.revokedInviteId, 'inv1');
        expect(find.text(sr.inviteRevokedSnackbar), findsOneWidget);
      },
    );
  });

  group('layout (phase7 part 8)', () {
    testWidgets(
      'at 360x780 in Serbian, the invite card\'s buttons fit and the name '
      'is headlineSmall',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const String name = 'Domaćinstvo porodice Stanković-Petrović';
        final _FakeRepo repo = _FakeRepo()
          ..members = _ownerAndAdult
          ..invites = <HouseholdInvite>[_invite()];
        await _pump(tester, repo: repo, readName: () => name, userId: 'u1');

        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text(sr.revokeInviteButton));
        await tester.pumpAndSettle();
        for (final Finder button in <Finder>[
          // `tonalIcon` builds a private FilledButton subclass, which
          // `widgetWithText`'s exact type match would miss.
          find.ancestor(
            of: find.text(sr.copyCodeButton),
            matching: find.byWidgetPredicate((Widget w) => w is FilledButton),
          ),
          find.widgetWithText(TextButton, sr.revokeInviteButton),
        ]) {
          final Rect r = tester.getRect(button);
          expect(
            r.left >= 0 && r.top >= 0 && r.right <= 360 && r.bottom <= 780,
            isTrue,
            reason: '$button at $r',
          );
        }

        await tester.scrollUntilVisible(
          find.text(name),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        final BuildContext context = tester.element(find.text(name));
        expect(
          tester.widget<Text>(find.text(name)).style,
          Theme.of(context).textTheme.headlineSmall,
        );
      },
    );

    testWidgets('the member count takes the few form: 2 člana', (
      WidgetTester tester,
    ) async {
      final _FakeRepo repo = _FakeRepo()..members = _ownerAndAdult;
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u1');

      expect(find.text('2 člana'), findsOneWidget);
    });

    testWidgets('the caller\'s own row says vi, and members are circles', (
      WidgetTester tester,
    ) async {
      final _FakeRepo repo = _FakeRepo()..members = _ownerAndAdult;
      await _pump(tester, repo: repo, readName: () => 'H', userId: 'u2');

      expect(
        find.text(sr.householdMemberYou(sr.householdRoleAdult)),
        findsOneWidget,
      );
      expect(find.text(sr.householdRoleOwner), findsOneWidget);
      expect(
        tester
            .widgetList<AppMonogramTile>(find.byType(AppMonogramTile))
            .map((AppMonogramTile t) => t.circular),
        everyElement(isTrue),
      );
    });
  });
}
