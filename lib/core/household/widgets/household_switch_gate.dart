import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../current_household.dart';

/// Whether a tab is between a household switch and its data
/// (phase9-household-switch-loading) -- what Recipes, Plan and List wrap
/// their whole `Scaffold` in, so the app-bar actions see it too.
///
/// [builder]'s `awaiting` turns true the moment a switch starts and false
/// once the switch is no longer pending AND [dataLoading] -- the tab's own
/// provider's `isLoading` -- is false. Both halves are needed: a cached
/// emission can beat `switchTo`'s own return, and a failed switch may never
/// reload the data at all.
///
/// A switch is a Riverpod reload, which keeps the previous household's
/// value; this is what stops a tab showing it. Only a switch does this:
/// every other load keeps the tab's own look.
class HouseholdSwitchGate extends ConsumerStatefulWidget {
  const HouseholdSwitchGate({
    required this.dataLoading,
    required this.builder,
    super.key,
  });

  final bool dataLoading;
  final Widget Function(BuildContext context, bool awaiting) builder;

  @override
  ConsumerState<HouseholdSwitchGate> createState() =>
      _HouseholdSwitchGateState();
}

class _HouseholdSwitchGateState extends ConsumerState<HouseholdSwitchGate> {
  /// A tab first built mid-switch starts out awaiting: whatever its provider
  /// has is not yet known to be the new household's.
  late bool _awaiting = ref.read(householdSwitchPendingProvider);

  void _settle() {
    if (_awaiting &&
        !widget.dataLoading &&
        !ref.read(householdSwitchPendingProvider)) {
      _awaiting = false;
    }
  }

  @override
  void didUpdateWidget(HouseholdSwitchGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    _settle();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(householdSwitchPendingProvider, (bool? _, bool pending) {
      setState(() {
        if (pending) {
          _awaiting = true;
        } else {
          _settle();
        }
      });
    });
    return widget.builder(context, _awaiting);
  }
}
