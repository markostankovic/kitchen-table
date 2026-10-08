import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_formatting_toolbar.dart';
import 'rich_text_editing_controller.dart';

/// A text field that shows the D165 markup styled in place and takes the
/// formatting toolbar while it has focus (D166).
///
/// A formattable field owns its [RichTextEditingController] and
/// [FocusNode]; in a list, key it by the row's id and the row's key carries
/// both across a reorder and disposes them with the row, so the caller keeps
/// no list bookkeeping. Focus points [activeFormatting] at the controller --
/// the screen hands that notifier to its [AppFormattingToolbar] -- and
/// losing focus drops any still-empty bold or italic pair and lets go.
///
/// The toolbar's edits are programmatic, and `TextFormField.onChanged` never
/// fires for those, so the text is reported from a controller listener
/// instead -- every change exactly once, typed or tapped.
class AppFormattableField extends StatefulWidget {
  const AppFormattableField({
    required this.initialValue,
    required this.onChanged,
    required this.activeFormatting,
    required this.style,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.decoration = const InputDecoration(),
    super.key,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final ValueNotifier<RichTextEditingController?> activeFormatting;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final InputDecoration decoration;

  @override
  State<AppFormattableField> createState() => _AppFormattableFieldState();
}

class _AppFormattableFieldState extends State<AppFormattableField> {
  late final RichTextEditingController _controller =
      RichTextEditingController(text: widget.initialValue);
  final FocusNode _focusNode = FocusNode();
  late String _reported = widget.initialValue;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_report);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.removeListener(_report);
    final RichTextEditingController controller = _controller;
    final ValueNotifier<RichTextEditingController?> active =
        widget.activeFormatting;
    if (active.value == controller) {
      // The tree is locked while it is torn down, so the toolbar lets go of
      // this controller after the frame, and only then is it disposed. The
      // screen's own dispose clears the notifier first if it goes too.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (active.value == controller) active.value = null;
        controller.dispose();
      });
    } else {
      controller.dispose();
    }
    super.dispose();
  }

  void _report() {
    final String text = _controller.text;
    if (text == _reported) return;
    _reported = text;
    widget.onChanged(text);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.activeFormatting.value = _controller;
    } else {
      _controller.dropPendingPair();
      if (widget.activeFormatting.value == _controller) {
        widget.activeFormatting.value = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      inputFormatters: <TextInputFormatter>[RichListFormatter()],
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      textCapitalization: TextCapitalization.sentences,
      style: widget.style,
      decoration: widget.decoration,
    );
  }
}
