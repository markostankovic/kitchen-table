import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/kitchen_colors.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_monogram_tile.dart';
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
    final TextEditingController controller = TextEditingController(
      text: h.name,
    );
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
            // No label: the dialog title is the prompt (the join screen's
            // precedent). The field's look is the theme's (D124).
            style: Theme.of(context).textTheme.bodyMedium,
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
  Future<void> _removeMember(
    HouseholdMember member,
    AppLocalizations l10n,
  ) async {
    final KitchenColors kitchen = Theme.of(context).extension<KitchenColors>()!;
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
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kitchen.destructive),
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
    final KitchenColors kitchen = Theme.of(context).extension<KitchenColors>()!;
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
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kitchen.destructive),
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
    final KitchenColors kitchen = Theme.of(context).extension<KitchenColors>()!;
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
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kitchen.destructive),
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
    final ThemeData theme = Theme.of(context);
    final AsyncValue<Household?> household = ref.watch(
      currentHouseholdProvider,
    );
    final List<HouseholdMember>? members = ref
        .watch(householdMembersProvider)
        .value;

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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                h.name,
                                style: theme.textTheme.headlineSmall,
                              ),
                              if (members != null) ...<Widget>[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.householdMemberCount(members.length),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.renameHouseholdTooltip,
                          onPressed: () => _rename(h, l10n),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: AppSectionHeading(text: l10n.membersSectionTitle),
                  ),
                  ..._members(l10n),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: AppSectionHeading(
                      text: l10n.inviteSomeoneSectionTitle,
                    ),
                  ),
                  ..._invites(l10n),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      // Outlined, not filled: nothing on this screen is its
                      // one action, so it has no filled button.
                      child: OutlinedButton.icon(
                        onPressed: _generating ? null : _createInvite,
                        icon: const Icon(Icons.add),
                        label: Text(
                          _generating
                              ? l10n.creatingEllipsis
                              : l10n.createInviteCodeButton,
                        ),
                      ),
                    ),
                  ),
                  if (_failure != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Text(
                        _failure!.localized(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ..._destructiveRow(h, l10n),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
      ),
    );
  }

  /// The caller's own role, looked up from the same members list `_members()`
  /// renders rather than a second provider, since the caller's own row is
  /// always in it. Null while the list loads, or if the caller is not in it --
  /// and a null role gates every affordance off (D115).
  HouseholdRole? _myRole() {
    final String? myUserId = ref.watch(currentUserIdProvider).value;
    final List<HouseholdMember> loadedMembers =
        ref.watch(householdMembersProvider).value ?? const <HouseholdMember>[];
    for (final HouseholdMember m in loadedMembers) {
      if (m.userId == myUserId) return m.role;
    }
    return null;
  }

  /// The one destructive slot at the bottom of the screen: Delete for the
  /// owner, Leave for an adult, nothing while the role is unknown. Only one
  /// ever renders; the other is absent, not disabled (D115).
  List<Widget> _destructiveRow(Household h, AppLocalizations l10n) {
    final HouseholdRole? role = _myRole();
    if (role == null) return const <Widget>[];
    final Color destructive = Theme.of(context)
        .extension<KitchenColors>()!
        .destructive;
    final (IconData icon, String label, VoidCallback onTap) = switch (role) {
      HouseholdRole.owner => (
        Icons.delete_forever_outlined,
        l10n.deleteHouseholdButton,
        () => _deleteHousehold(h, l10n),
      ),
      HouseholdRole.adult => (
        Icons.logout,
        l10n.leaveHouseholdButton,
        () => _leave(l10n),
      ),
    };
    return <Widget>[
      const SizedBox(height: AppSpacing.xl),
      const Divider(),
      ListTile(
        iconColor: destructive,
        textColor: destructive,
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      ),
    ];
  }

  List<Widget> _members(AppLocalizations l10n) {
    final String? myUserId = ref.watch(currentUserIdProvider).value;
    final bool iAmOwner = _myRole() == HouseholdRole.owner;

    return ref
        .watch(householdMembersProvider)
        .when(
          loading: () => <Widget>[_sectionLine(l10n.loadingEllipsis)],
          error: (Object e, _) => <Widget>[
            _sectionLine(localizedErrorMessage(e, l10n)),
          ],
          data: (List<HouseholdMember> members) => <Widget>[
            for (final HouseholdMember m in members) ...<Widget>[
              _memberRow(m, myUserId, iAmOwner, l10n),
              const Divider(),
            ],
          ],
        );
  }

  Widget _memberRow(
    HouseholdMember m,
    String? myUserId,
    bool iAmOwner,
    AppLocalizations l10n,
  ) {
    // A null display name means the co-member policy withheld the profile.
    // Show the gap rather than hide the person.
    final String name = m.displayName ?? l10n.unknownDisplayName;
    final String trimmed = name.trim();
    final String role = _roleLabel(m.role, l10n);
    return ListTile(
      leading: AppMonogramTile(
        letter: trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase(),
        size: AppSizes.avatar,
        circular: true,
      ),
      title: Text(name),
      subtitle: Text(
        m.userId == myUserId ? l10n.householdMemberYou(role) : role,
      ),
      trailing: _memberTrailing(m, myUserId, iAmOwner, l10n),
    );
  }

  /// - Another member's row, and I am the owner -> an overflow with Remove.
  /// - Otherwise -> nothing. The owner's own row has no affordance, absent
  ///   rather than disabled-with-a-tooltip (D115); an adult's Leave is the
  ///   bottom destructive row, not a row affordance.
  Widget? _memberTrailing(
    HouseholdMember m,
    String? myUserId,
    bool iAmOwner,
    AppLocalizations l10n,
  ) {
    if (m.userId == myUserId || !iAmOwner) return null;
    final Color destructive = Theme.of(context)
        .extension<KitchenColors>()!
        .destructive;
    return PopupMenuButton<void>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          onTap: () => _removeMember(m, l10n),
          child: Text(
            l10n.removeMemberMenuItem,
            style: TextStyle(color: destructive),
          ),
        ),
      ],
    );
  }

  /// No `default` arm, deliberately -- same rule as `failure_l10n.dart`'s own
  /// switch: a new `HouseholdRole` must not compile until it has a label.
  String _roleLabel(HouseholdRole role, AppLocalizations l10n) =>
      switch (role) {
        HouseholdRole.owner => l10n.householdRoleOwner,
        HouseholdRole.adult => l10n.householdRoleAdult,
      };

  /// One line of prose inside a section: the loading and error states, and
  /// the no-codes message. Too light for `AppEmptyState`.
  Widget _sectionLine(String text) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  List<Widget> _invites(AppLocalizations l10n) {
    return ref
        .watch(liveInvitesProvider)
        .when(
          loading: () => <Widget>[_sectionLine(l10n.loadingEllipsis)],
          error: (Object e, _) => <Widget>[
            _sectionLine(localizedErrorMessage(e, l10n)),
          ],
          data: (List<HouseholdInvite> invites) => invites.isEmpty
              ? <Widget>[_sectionLine(l10n.noActiveCodesMessage)]
              : <Widget>[
                  for (int n = 0; n < invites.length; n++) ...<Widget>[
                    if (n > 0) const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: _inviteCard(invites[n], l10n),
                    ),
                  ],
                ],
        );
  }

  Widget _inviteCard(HouseholdInvite invite, AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Styled exactly as the join screen's code field, so a code reads
            // the same where it is shown and where it is typed.
            Text(
              invite.code,
              style: theme.textTheme.titleLarge?.copyWith(
                letterSpacing: AppSpacing.sm,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _expiry(invite.expiresAt, l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // A Wrap, so a narrow card wraps by whole button rather than
            // clipping one.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => _copy(invite.code, l10n),
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.copyCodeButton),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: kitchen.destructive,
                  ),
                  onPressed: () => _revoke(invite, l10n),
                  child: Text(l10n.revokeInviteButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _expiry(DateTime expiresAt, AppLocalizations l10n) {
    final Duration left = expiresAt.difference(DateTime.now());
    if (left.inHours < 1) return l10n.inviteExpiresWithinHour;
    if (left.inHours < 24) return l10n.inviteExpiresInHours(left.inHours);
    return l10n.inviteExpiresInDays(left.inDays);
  }
}
