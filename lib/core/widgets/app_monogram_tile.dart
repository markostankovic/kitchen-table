import 'package:flutter/material.dart';

import '../theme/app_radii.dart';

/// A single letter centred on a tonal square -- what stands in for a photo
/// when there is no photo.
///
/// Most recipes in this app will never have a picture: they come out of a
/// notebook, not a food blog. A row with an empty space where a thumbnail
/// would be reads as a row that failed to load one, so a recipe without a
/// photo gets a tile rather than nothing, and the list keeps one alignment
/// down its left edge either way.
///
/// `secondaryContainer` rather than `primaryContainer`: the mustard is the
/// app's quiet highlight, and a column of tiles in `primary`'s green would
/// make a list of recipes read as a list of actions.
///
/// [textStyle] is passed in rather than derived from [size]. A 72dp tile
/// wants `headlineSmall` and a 40dp one wants `titleMedium`, and picking that
/// from a number inside here would be guessing at type from geometry -- the
/// call site knows which row of § Type it is in.
class AppMonogramTile extends StatelessWidget {
  const AppMonogramTile({
    required this.letter,
    required this.size,
    this.textStyle,
    super.key,
  });

  final String letter;
  final double size;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        letter,
        style: (textStyle ?? theme.textTheme.titleMedium)?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
