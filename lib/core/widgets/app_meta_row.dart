import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// A row of small icon-plus-text facts that wraps **by whole items**.
///
/// This widget exists for one defect. Before it, a recipe card's meta line was
/// a single `Text` of strings joined with ` · ` -- `8 porcija · 30 min
/// priprema · 45 min kuvanja`. In English that fits; in Serbian it does not,
/// and a joined run has no choice but to break wherever the line happens to
/// run out, so `30 min` ended one line and `priprema` began the next. The two
/// halves of one fact stopped reading as one fact.
///
/// The fix is structural, not a matter of finding a shorter string: each fact
/// is its own [AppMetaItem], each item is a `Row(mainAxisSize: min)` that the
/// `Wrap` treats as indivisible, and there are **no separators** -- the gaps
/// do the separating. A fact that does not fit moves to the next line whole.
/// That holds for any string in any language, which is what "by luck" did
/// not.
///
/// [items] takes arbitrary widgets rather than a list of icon/label pairs, so
/// that an `AppBadge` can sit in the same wrapping run as the facts instead of
/// needing a row of its own above them.
class AppMetaRow extends StatelessWidget {
  const AppMetaRow({required this.items, super.key});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: items,
  );
}

/// One fact in an [AppMetaRow]: a 16dp icon, a small gap, its text.
///
/// The text is `Flexible` with a single line and an ellipsis so that an
/// absurdly long label degrades by truncating *itself* rather than by
/// overflowing the row -- but it is the item that wraps first, and truncation
/// is the last resort rather than the normal case.
///
/// [color] tints both halves; it is what a rating item passes to get its star
/// and its number in `KitchenColors.rating`. Left null, the icon is `outline`
/// and the text is `onSurfaceVariant` -- `outline` is a line colour and never
/// body text.
class AppMetaItem extends StatelessWidget {
  const AppMetaItem({
    required this.icon,
    required this.label,
    this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: AppSizes.iconInMeta,
          color: color ?? theme.colorScheme.outline,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
