import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_section_heading.dart';
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

  /// Opens the rename dialog, then writes the new name if it differs.
  ///
  /// A failure goes to a `SnackBar`, not [_failure] -- that field belongs to
  /// the invite button and renders under it, not under this row.
  Future<void> _rename(Household h, AppLocalizations l10n) async {
    final TextEditingController controller =
        TextEditingController(text: h.name);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.renameHouseholdDialogTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.householdNameFieldLabel,
              border: const OutlineInputBorder(),
            ),
            validator: (String? value) => (value ?? '').trim().isEmpty
                ? l10n.householdNameEmptyError
                : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(controller.text);
              }
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(controller.text);
              }
            },
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );

    if (name == null) return;
    final String trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == h.name) return;

    try {
      await ref.read(householdRepositoryProvider).rename(h.id, trimmed);
      ref.invalidate(currentHouseholdProvider);
      await ref.read(currentHouseholdProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.householdRenamedSnackbar)));
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  /// Confirms, then removes [member] from the household. Owner-only -- the
  /// affordance that calls this does not exist on any other row, so the RPC's
  /// own guard is a backstop for a stale list, not something this dialog
  /// expects to hit.
  Future<void> _removeMember(HouseholdMember member, AppLocalizations l10n) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.removeMemberDialogTitle),
        content: Text(l10n.removeMemberConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.removeButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(householdRepositoryProvider).removeMember(member.userId);
      ref.invalidate(householdMembersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.memberRemovedSnackbar)));
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  /// Confirms, then has the caller leave the household. Only reachable by an
  /// adult -- the owner never sees this affordance.
  Future<void> _leave(AppLocalizations l10n) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.leaveHouseholdDialogTitle),
        content: Text(l10n.leaveHouseholdConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.leaveButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(householdRepositoryProvider).leaveHousehold();
      ref.invalidate(currentHouseholdProvider);
      // Resolves to null; app_router.dart's ref.listen bumps the refresh
      // notifier and the redirect sends us to CreateHouseholdRoute. No new
      // routing here. This screen is being torn down underneath the await,
      // hence the mounted guard before touching context.
      await ref.read(currentHouseholdProvider.future);
      if (!mounted) return;
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  /// Confirms, then deletes the household entirely. Owner-only -- the row
  /// that calls this is rendered only for the owner, so the RPC's own guard
  /// is a backstop for a stale screen, not something this dialog expects to
  /// hit (D115: absent, not disabled with a tooltip).
  Future<void> _deleteHousehold(Household h, AppLocalizations l10n) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.deleteHouseholdDialogTitle),
        content: Text(l10n.deleteHouseholdConfirmBody(h.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(householdRepositoryProvider).deleteHousehold();
      ref.invalidate(currentHouseholdProvider);
      // Resolves to null; app_router.dart's ref.listen bumps the refresh
      // notifier and the redirect sends us to CreateHouseholdRoute. No new
      // routing here. This screen is being torn down underneath the await,
      // hence the mounted guard before touching context, and no SnackBar on
      // success -- same as _leave.
      await ref.read(currentHouseholdProvider.future);
      if (!mounted) return;
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  /// Revokes [invite]. No confirm dialog -- cheap, and undone by minting
  /// another code (settled during planning).
  Future<void> _revoke(HouseholdInvite invite, AppLocalizations l10n) async {
    try {
      await ref.read(householdRepositoryProvider).revokeInvite(invite.id);
      ref.invalidate(liveInvitesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.inviteRevokedSnackbar)));
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Household?> household =
        ref.watch(currentHouseholdProvider);
    final bool iAmOwner = _iAmOwner();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.householdScreenTitle)),
      body: household.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) =>
            AppErrorView(message: localizedErrorMessage(e, l10n)),
        data: (Household? h) => h == null
            ? Center(child: Text(l10n.noHouseholdYet))
            : ListView(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(h.name),
                    subtitle: Text(l10n.householdNameFieldLabel),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.renameHouseholdTooltip,
                      onPressed: () => _rename(h, l10n),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppSectionHeading(text: l10n.membersSectionTitle),
                  ),
                  ..._members(l10n),
                  const Divider(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child:
                        AppSectionHeading(text: l10n.inviteSomeoneSectionTitle),
                  ),
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
                  // Owner-only, destructive, at the bottom -- rename lives on
                  // the household-name row above and delete does not belong
                  // next to it. Absent for an adult, not disabled (D115).
                  if (iAmOwner) ...<Widget>[
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.delete_forever_outlined,
                          color: Theme.of(context).colorScheme.error),
                      title: Text(
                        l10n.deleteHouseholdButton,
                        style:
                            TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      onTap: () => _deleteHousehold(h, l10n),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// Whether the signed-in caller is themselves the owner -- looked up from
  /// the same members list `_members()` renders, rather than a second
  /// provider, since the caller's own row is always in it. Shared by
  /// [build] (the delete row) and [_members] (the leave/remove trailing
  /// icons) so both read one definition instead of duplicating the loop.
  bool _iAmOwner() {
    final String? myUserId = ref.watch(currentUserIdProvider).value;
    final List<HouseholdMember> loadedMembers =
        ref.watch(householdMembersProvider).value ?? const <HouseholdMember>[];
    for (final HouseholdMember m in loadedMembers) {
      if (m.userId == myUserId) return m.role == HouseholdRole.owner;
    }
    return false;
  }

  List<Widget> _members(AppLocalizations l10n) {
    final String? myUserId = ref.watch(currentUserIdProvider).value;
    final bool iAmOwner = _iAmOwner();

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
                    trailing: _memberTrailing(m, myUserId, iAmOwner, l10n),
                  ))
              .toList(),
        );
  }

  /// - My own row, and I am an adult -> leave.
  /// - My own row, and I am the owner -> nothing. The affordance is absent,
  ///   not disabled-with-a-tooltip -- the refusal copy does not exist
  ///   (the-refusal-copy-decision, phase6-part3b).
  /// - Another member's row, and I am the owner -> remove.
  /// - Otherwise -> nothing.
  Widget? _memberTrailing(
    HouseholdMember m,
    String? myUserId,
    bool iAmOwner,
    AppLocalizations l10n,
  ) {
    final bool isMe = m.userId == myUserId;
    if (isMe) {
      if (iAmOwner) return null;
      return IconButton(
        icon: const Icon(Icons.logout),
        tooltip: l10n.leaveHouseholdTooltip,
        onPressed: () => _leave(l10n),
      );
    }
    if (iAmOwner) {
      return IconButton(
        icon: const Icon(Icons.person_remove_outlined),
        tooltip: l10n.removeMemberTooltip,
        onPressed: () => _removeMember(m, l10n),
      );
    }
    return null;
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: l10n.copyCodeTooltip,
                              onPressed: () => _copy(i.code, l10n),
                            ),
                            IconButton(
                              icon: const Icon(Icons.link_off),
                              tooltip: l10n.revokeInviteTooltip,
                              onPressed: () => _revoke(i, l10n),
                            ),
                          ],
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
