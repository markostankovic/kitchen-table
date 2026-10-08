import 'package:flutter/material.dart';

import '../text/rich_text_editing.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import 'rich_text_editing_controller.dart';

/// The bar right above the keyboard while a formattable field has focus:
/// bold, italic, bulleted and numbered list, then hide-keyboard (D166).
///
/// It knows a [RichTextEditingController], never a recipe. The recipe
/// editor's description, step, note and end-note fields are the first
/// users; import review's step and notes fields are the next.
///
/// On `surfaceContainer`, the nav bar's colour, with `AppActionBar`'s 1dp
/// `outlineVariant` top hairline. The two can't merge here: the keyboard
/// covers the nav bar while the toolbar shows, and in the recipe editor the
/// toolbar takes the save bar's place until the keyboard goes. An
/// active toggle sits on a `secondaryContainer` pill, like a selected chip.
/// Bold is disabled inside italic and italic inside bold, because there is
/// no nesting (D165 #3).
///
/// Core widgets take their strings ready-made, so the five tooltips come in
/// localized. The caller wraps it in a `TextFieldTapRegion`, so a tap here
/// doesn't count as a tap outside the field.
class AppFormattingToolbar extends StatelessWidget {
  const AppFormattingToolbar({
    required this.controller,
    required this.onHideKeyboard,
    required this.boldTooltip,
    required this.italicTooltip,
    required this.bulletListTooltip,
    required this.numberedListTooltip,
    required this.hideKeyboardTooltip,
    super.key,
  });

  final RichTextEditingController controller;
  final VoidCallback onHideKeyboard;
  final String boldTooltip;
  final String italicTooltip;
  final String bulletListTooltip;
  final String numberedListTooltip;
  final String hideKeyboardTooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SizedBox(
        height: AppSizes.target,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: ListenableBuilder(
            listenable: controller,
            builder: (BuildContext context, _) {
              final RichFormatState state = controller.formatState;
              return Row(
                children: <Widget>[
                  _Toggle(
                    icon: Icons.format_bold,
                    tooltip: boldTooltip,
                    active: state.bold,
                    onPressed: state.boldEnabled ? controller.toggleBold : null,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _Toggle(
                    icon: Icons.format_italic,
                    tooltip: italicTooltip,
                    active: state.italic,
                    onPressed: state.italicEnabled
                        ? controller.toggleItalic
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _Toggle(
                    icon: Icons.format_list_bulleted,
                    tooltip: bulletListTooltip,
                    active: state.bullet,
                    onPressed: controller.toggleBullet,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _Toggle(
                    icon: Icons.format_list_numbered,
                    tooltip: numberedListTooltip,
                    active: state.numbered,
                    onPressed: controller.toggleNumbered,
                  ),
                  const Spacer(),
                  _Toggle(
                    icon: Icons.keyboard_hide,
                    tooltip: hideKeyboardTooltip,
                    active: false,
                    onPressed: onHideKeyboard,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One 48x48 button, on the pill when [active].
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onPressed;

  /// The active pill, centred in its 48 cell. The toolbar's own shape, not a
  /// chip's or a tag's height, so no token.
  static const double _pillWidth = 40;
  static const double _pillHeight = 32;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: AppSizes.target,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (active)
            SizedBox(
              width: _pillWidth,
              height: _pillHeight,
              child: DecoratedBox(
                key: const Key('formattingToolbarPill'),
                decoration: ShapeDecoration(
                  color: colors.secondaryContainer,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          IconButton(
            tooltip: tooltip,
            icon: Icon(icon),
            color: active ? colors.onSecondaryContainer : null,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
