import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/kitchen_colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_meta_row.dart';
import '../../widgets/app_monogram_tile.dart';
import '../../../features/recipes/domain/recipe.dart';

/// One recipe as a card: a 72dp square, the title, and a meta row.
///
/// It lives in `core/recipes/widgets/` rather than in the recipes feature
/// because two places list recipes -- the recipe list screen and
/// `recipe_picker_sheet.dart`, which the meal plan opens -- and a direct
/// cross-feature import is not allowed (D43, D53). It knows what a recipe is
/// and nothing else: no provider, no repository, no route. [onTap] is the
/// caller's, and the list opens a detail with it while the sheet returns a
/// pick.
///
/// The square is the photo when there is one and an [AppMonogramTile] when
/// there is not -- and also when the photo fails, since a signed URL can
/// outlive its TTL and a recipe missing its picture is not a broken recipe
/// (rule 3's spirit). Before this card, a photoless recipe showed nothing at
/// all there, which read as a thumbnail that had not loaded.
///
/// The meta row is an [AppMetaRow] and **not** a ` · `-joined string. That is
/// not a style preference: the joined run is what split `30 min` from
/// `priprema` across two lines in Serbian, and only a row of indivisible
/// items fixes it for every string rather than for the ones that happen to
/// fit.
///
/// The heart is display-only. There is still no in-place favouriting -- that
/// lives on the detail screen -- and this slice does not add one.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    required this.recipe,
    required this.l10n,
    required this.onTap,
    super.key,
  });

  final Recipe recipe;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    final TextStyle? titleStyle = theme.textTheme.titleMedium;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _leading(context),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppMetaRow(items: _meta(kitchen)),
                  ],
                ),
              ),
              if (recipe.isFavorite) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                // Sized to the title's first line rather than top-aligned, so
                // the heart sits *on* the title whether that title runs to
                // one line or two.
                SizedBox(
                  height: (titleStyle?.fontSize ?? 0) * (titleStyle?.height ?? 1),
                  child: Center(
                    child: Icon(
                      Icons.favorite,
                      size: AppSizes.iconInButton,
                      color: kitchen.favorite,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _leading(BuildContext context) {
    final String? url = recipe.imageUrl;
    if (url == null) return _monogram(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Image.network(
        url,
        width: AppSizes.thumb,
        height: AppSizes.thumb,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _monogram(context),
      ),
    );
  }

  /// The title's first letter. `substring(0, 1)` rather than
  /// `package:characters` (rule 8): every letter this app renders is Latin,
  /// and no Latin letter is a surrogate pair.
  Widget _monogram(BuildContext context) {
    final String trimmed = recipe.title.trim();
    return AppMonogramTile(
      letter: trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase(),
      size: AppSizes.thumb,
      // A 72dp tile carries `headlineSmall`; the tile's own default
      // `titleMedium` would leave the letter swimming in it.
      textStyle: Theme.of(context).textTheme.headlineSmall,
    );
  }

  /// A draft badge, then the facts the recipe actually has. No separators --
  /// see [AppMetaRow].
  List<Widget> _meta(KitchenColors kitchen) => <Widget>[
    if (recipe.status == RecipeStatus.draft) AppBadge(label: l10n.draftChipLabel),
    if (recipe.servings != null)
      AppMetaItem(
        icon: Icons.soup_kitchen_outlined,
        label: l10n.recipeServingsCount(recipe.servings!),
      ),
    if (recipe.prepMinutes != null)
      AppMetaItem(
        icon: Icons.schedule,
        label: l10n.recipePrepMinutes(recipe.prepMinutes!),
      ),
    if (recipe.cookMinutes != null)
      AppMetaItem(
        icon: Icons.local_fire_department_outlined,
        label: l10n.recipeCookMinutes(recipe.cookMinutes!),
      ),
    if (recipe.rating != null)
      AppMetaItem(
        icon: Icons.star,
        label: '${recipe.rating}',
        color: kitchen.rating,
      ),
  ];
}
