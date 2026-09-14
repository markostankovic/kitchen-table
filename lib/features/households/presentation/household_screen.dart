import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../application/household_providers.dart';
import '../domain/household.dart';
import '../domain/household_invite.dart';
import '../domain/household_member.dart';

/// Household management: who is in it, and how to let someone else in.
class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  bool _generating = false;
  AppFailure? _failure;

  Future<void> _createInvite() async {
    setState(() {
      _generating = true;
      _failure = null;
    });

    try {
      await ref.read(householdRepositoryProvider).createInvite();
      ref.invalidate(liveInvitesProvider);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copy(String code, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.codeCopiedSnackbar)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Household?> household =
        ref.watch(currentHouseholdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.householdScreenTitle)),
      body: household.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(localizedErrorMessage(e, l10n),
                textAlign: TextAlign.center),
          ),
        ),
        data: (Household? h) => h == null
            ? Center(child: Text(l10n.noHouseholdYet))
            : ListView(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(h.name),
                    subtitle: Text(l10n.householdNameFieldLabel),
                  ),
                  const Divider(),
                  _sectionHeader(context, l10n.membersSectionTitle),
                  ..._members(l10n),
                  const Divider(),
                  _sectionHeader(context, l10n.inviteSomeoneSectionTitle),
                  ..._invites(l10n),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _generating ? null : _createInvite,
                      icon: const Icon(Icons.add),
                      label: Text(_generating
                          ? l10n.creatingEllipsis
                          : l10n.createInviteCodeButton),
                    ),
                  ),
                  if (_failure != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        _failure!.localized(l10n),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );

  List<Widget> _members(AppLocalizations l10n) {
    return ref.watch(householdMembersProvider).when(
          loading: () => <Widget>[
            ListTile(title: Text(l10n.loadingEllipsis)),
          ],
          error: (Object e, _) => <Widget>[
            ListTile(title: Text(localizedErrorMessage(e, l10n))),
          ],
          data: (List<HouseholdMember> members) => members
              .map((HouseholdMember m) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    // A null display name means the co-member policy withheld
                    // the profile. Show the gap rather than hide the person.
                    title: Text(m.displayName ?? l10n.unknownDisplayName),
                    subtitle: Text(_roleLabel(m.role, l10n)),
                  ))
              .toList(),
        );
  }

  /// No `default` arm, deliberately -- same rule as `failure_l10n.dart`'s own
  /// switch: a new `HouseholdRole` must not compile until it has a label.
  String _roleLabel(HouseholdRole role, AppLocalizations l10n) =>
      switch (role) {
        HouseholdRole.owner => l10n.householdRoleOwner,
        HouseholdRole.adult => l10n.householdRoleAdult,
      };

  List<Widget> _invites(AppLocalizations l10n) {
    return ref.watch(liveInvitesProvider).when(
          loading: () => <Widget>[
            ListTile(title: Text(l10n.loadingEllipsis)),
          ],
          error: (Object e, _) => <Widget>[
            ListTile(title: Text(localizedErrorMessage(e, l10n))),
          ],
          data: (List<HouseholdInvite> invites) => invites.isEmpty
              ? <Widget>[
                  ListTile(subtitle: Text(l10n.noActiveCodesMessage)),
                ]
              : invites
                  .map((HouseholdInvite i) => ListTile(
                        title: Text(
                          i.code,
                          style: const TextStyle(
                              fontSize: 22, letterSpacing: 6),
                        ),
                        subtitle: Text(_expiry(i.expiresAt, l10n)),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: l10n.copyCodeTooltip,
                          onPressed: () => _copy(i.code, l10n),
                        ),
                      ))
                  .toList(),
        );
  }

  String _expiry(DateTime expiresAt, AppLocalizations l10n) {
    final Duration left = expiresAt.difference(DateTime.now());
    if (left.inHours < 1) return l10n.inviteExpiresWithinHour;
    if (left.inHours < 24) return l10n.inviteExpiresInHours(left.inHours);
    return l10n.inviteExpiresInDays(left.inDays);
  }
}
