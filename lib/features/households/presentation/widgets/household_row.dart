import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';

/// One household in a list: a radio marking the current one, the name, and
/// a meta line, with an optional gear behind a hairline that manages it.
///
/// Feature-private while the Households screen is its one consumer. The
/// switcher sheet (phase9-household-switcher) is the second, from other
/// features, and promotes it to `core/household/widgets/` -- hence the
/// [onManage]-less mode now, so that promotion is a move, not a rewrite.
///
/// The name wraps and is never cut off: no `maxLines`, no ellipsis.
class HouseholdRow extends StatelessWidget {
  const HouseholdRow({
    required this.name,
    required this.meta,
    required this.isCurrent,
    required this.onTap,
    this.onManage,
    this.manageTooltip,
    super.key,
  }) : assert(onManage == null || manageTooltip != null);

  final String name;

  /// The line under the name, already formatted.
  final String meta;

  /// Fills the radio, in `primary`.
  final bool isCurrent;

  /// Null leaves the row inert -- the current row, or while a switch is in
  /// flight.
  final VoidCallback? onTap;

  /// Null drops the hairline and the gear.
  final VoidCallback? onManage;

  /// The gear's tooltip. Required when [onManage] is set.
  final String? manageTooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Semantics(
            selected: isCurrent,
            inMutuallyExclusiveGroup: true,
            button: true,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      isCurrent
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: AppSizes.icon,
                      color: isCurrent
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            meta,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onManage != null) ...<Widget>[
          const SizedBox(
            height: AppSizes.splitDivider,
            child: VerticalDivider(width: 1, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                size: AppSizes.icon,
                color: colors.onSurfaceVariant,
              ),
              tooltip: manageTooltip,
              onPressed: onManage,
            ),
          ),
        ],
      ],
    );
  }
}
