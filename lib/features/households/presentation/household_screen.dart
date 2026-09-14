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

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Code copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Household?> household =
        ref.watch(currentHouseholdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Household')),
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
            ? const Center(child: Text('No household yet.'))
            : ListView(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(h.name),
                    subtitle: const Text('Household name'),
                  ),
                  const Divider(),
                  _sectionHeader(context, 'Members'),
                  ..._members(l10n),
                  const Divider(),
                  _sectionHeader(context, 'Invite someone'),
                  ..._invites(l10n),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _generating ? null : _createInvite,
                      icon: const Icon(Icons.add),
                      label: Text(_generating
                          ? 'Creating…'
                          : 'Create invite code'),
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
          loading: () => const <Widget>[
            ListTile(title: Text('Loading…')),
          ],
          error: (Object e, _) => <Widget>[
            ListTile(title: Text(localizedErrorMessage(e, l10n))),
          ],
          data: (List<HouseholdMember> members) => members
              .map((HouseholdMember m) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    // A null display name means the co-member policy withheld
                    // the profile. Show the gap rather than hide the person.
                    title: Text(m.displayName ?? 'Unknown'),
                    subtitle: Text(m.role.name),
                  ))
              .toList(),
        );
  }

  List<Widget> _invites(AppLocalizations l10n) {
    return ref.watch(liveInvitesProvider).when(
          loading: () => const <Widget>[
            ListTile(title: Text('Loading…')),
          ],
          error: (Object e, _) => <Widget>[
            ListTile(title: Text(localizedErrorMessage(e, l10n))),
          ],
          data: (List<HouseholdInvite> invites) => invites.isEmpty
              ? const <Widget>[
                  ListTile(
                    subtitle: Text(
                        'No active codes. Create one and read it out to '
                        'whoever is joining.'),
                  ),
                ]
              : invites
                  .map((HouseholdInvite i) => ListTile(
                        title: Text(
                          i.code,
                          style: const TextStyle(
                              fontSize: 22, letterSpacing: 6),
                        ),
                        subtitle: Text(_expiry(i.expiresAt)),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy code',
                          onPressed: () => _copy(i.code),
                        ),
                      ))
                  .toList(),
        );
  }

  String _expiry(DateTime expiresAt) {
    final Duration left = expiresAt.difference(DateTime.now());
    if (left.inHours < 1) return 'Expires within the hour';
    if (left.inHours < 24) return 'Expires in ${left.inHours} h';
    return 'Expires in ${left.inDays} d';
  }
}
