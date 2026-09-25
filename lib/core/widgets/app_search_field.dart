import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';

/// The app's search box: a stadium on `surfaceContainerHighest`, a magnifier
/// in front, a clear button once there is something to clear.
///
/// Two screens hold one of these -- the recipe list and the recipe picker
/// sheet -- and before this widget they held two hand-written copies that had
/// each drifted (one had a clear button, the other did not; both had a
/// rectangular `OutlineInputBorder` the design does not use anywhere). One
/// widget is what keeps them from drifting again.
///
/// It also fixes the part-2 walk's defect: a `TextField` with no `style` falls
/// through to `bodyLarge`, and `bodyLarge` is Literata. **A search box is UI
/// furniture, not something a person reads**, so both the typed text and the
/// hint are `bodyMedium` sans. The hint half is settled in
/// `app_theme.dart`'s `inputDecorationTheme`; the typed half cannot be
/// themed, so it is set here.
///
/// The stadium is this app's one exception to `AppRadii`. A stadium is a
/// shape, not a radius -- but `InputBorder` takes only a `BorderRadius`, so
/// inside the decoration it is spelled as half the field's height, which is
/// the same curve.
///
/// **It does not own the debounce.** The list and the sheet key different
/// providers and each keeps its own `Timer`; what a keystroke should cost is
/// the screen's business, not this widget's.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  @override
  void initState() {
    super.initState();
    // Listening to the controller rather than rebuilding from `onChanged`:
    // the callers debounce, so the clear button would otherwise appear a
    // quarter of a second after the first letter.
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    // The controller itself belongs to the caller, which disposes it.
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius stadium = BorderRadius.circular(AppSizes.field / 2);
    final OutlineInputBorder resting = OutlineInputBorder(
      borderRadius: stadium,
      borderSide: BorderSide.none,
    );
    // The resting field carries no border -- the fill is what makes it a
    // field. Focus still draws § Inputs' 2dp `primary` ring, because "no
    // border" is about the resting state, not about hiding where the caret
    // is.
    final OutlineInputBorder focused = OutlineInputBorder(
      borderRadius: stadium,
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
    );

    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(
          Icons.search,
          size: AppSizes.icon,
          color: theme.colorScheme.outline,
        ),
        border: resting,
        enabledBorder: resting,
        focusedBorder: focused,
        suffixIcon: widget.controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
              ),
      ),
    );
  }
}
