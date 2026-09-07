import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
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
  String? _error;

  Future<void> _createInvite() async {
    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      await ref.read(householdRepositoryProvider).createInvite();
      ref.invalidate(liveInvitesProvider);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
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
    final AsyncValue<Household?> household =
        ref.watch(currentHouseholdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Household')),
      body: household.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your household.\n\n$e',
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
                  ..._members(),
                  const Divider(),
                  _sectionHeader(context, 'Invite someone'),
                  ..._invites(),
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
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        _error!,
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

  List<Widget> _members() {
    return ref.watch(householdMembersProvider).when(
          loading: () => const <Widget>[
            ListTile(title: Text('Loading…')),
          ],
          error: (Object e, _) => <Widget>[
            ListTile(title: Text('Could not load members.\n\n$e')),
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

  List<Widget> _invites() {
    return ref.watch(liveInvitesProvider).when(
          loading: () => const <Widget>[
            ListTile(title: Text('Loading…')),
          ],
          error: (Object e, _) => <Widget>[
            ListTile(title: Text('Could not load invite codes.\n\n$e')),
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
