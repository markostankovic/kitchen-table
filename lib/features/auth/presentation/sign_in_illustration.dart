import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_sizes.dart';

/// The sign-in screen's flat recipe card: a tilted card on a green one, a
/// tomato and a sprig of herbs.
///
/// A painter in the theme's colour roles rather than the design bundle's
/// `recipe-card.png`: that PNG is a crop of a light-mode JPEG on a baked-in
/// cream ground, so in dark it would show as a cream box (D137).
class SignInIllustration extends StatelessWidget {
  const SignInIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(
        AppSizes.signInIllustration,
        AppSizes.signInIllustration *
            _RecipeCardPainter.height /
            _RecipeCardPainter.width,
      ),
      painter: _RecipeCardPainter(Theme.of(context).colorScheme),
    );
  }
}

/// Draws in a [width] x [height] unit box scaled to the canvas. The numbers
/// below are a drawing's coordinates, like the logo's VectorDrawables; the
/// colours all come from [scheme].
class _RecipeCardPainter extends CustomPainter {
  _RecipeCardPainter(this.scheme);

  final ColorScheme scheme;

  static const double width = 176;
  static const double height = 139;

  static const double _cardWidth = 146;
  static const double _cardHeight = 100;
  static const Radius _corner = Radius.circular(10);

  double _degrees(double d) => d * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / width, size.height / height);

    // 1. The back card, tilted the other way and up-right of the front one.
    canvas.save();
    canvas.translate(88, 60);
    canvas.rotate(_degrees(-4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: _cardWidth + 4,
          height: _cardHeight,
        ),
        _corner,
      ),
      Paint()..color = scheme.primaryContainer,
    );
    canvas.restore();

    // 2. The front card, and 3. its contents in its own rotated frame.
    canvas.save();
    canvas.translate(87, 64);
    canvas.rotate(_degrees(3));
    canvas.translate(-_cardWidth / 2, -_cardHeight / 2);
    final RRect card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, _cardWidth, _cardHeight),
      _corner,
    );
    canvas.drawRRect(card, Paint()..color = scheme.surfaceContainerLow);
    canvas.drawRRect(
      card,
      Paint()
        ..color = scheme.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(15, 11, 57, 7),
        const Radius.circular(3.5),
      ),
      Paint()..color = scheme.onSurfaceVariant,
    );
    final Paint rule = Paint()
      ..color = scheme.primary
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(15, 26), const Offset(132, 26), rule);
    final Paint line = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(15, 44), const Offset(132, 44), line);
    canvas.drawLine(const Offset(15, 60), const Offset(132, 60), line);
    canvas.drawLine(const Offset(15, 76), const Offset(89, 76), line);
    canvas.restore();

    // 4. The tomato over the bottom-left corner, with its stem.
    canvas.drawCircle(
      const Offset(19.5, 117.5),
      15.5,
      Paint()..color = scheme.tertiary,
    );
    canvas.drawPath(
      Path()
        ..moveTo(13, 102.5)
        ..quadraticBezierTo(19.5, 106.5, 26.5, 102.5),
      Paint()
        ..color = scheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // 5. The sprig: a stem up to the right edge, three leaves along it.
    final Paint leaf = Paint()..color = scheme.primary;
    canvas.drawPath(
      Path()
        ..moveTo(129.5, 133)
        ..quadraticBezierTo(140, 104, 170, 81),
      Paint()
        ..color = scheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    _leaf(canvas, leaf, const Offset(140, 112), const Offset(127, 91), 6.5);
    _leaf(canvas, leaf, const Offset(146, 105), const Offset(164, 121), 5.5);
    _leaf(canvas, leaf, const Offset(152, 97), const Offset(170, 83), 5.5);

    canvas.restore();
  }

  /// A lens-shaped leaf from [base] to [tip], [bulge] units wide each side.
  void _leaf(
    Canvas canvas,
    Paint paint,
    Offset base,
    Offset tip,
    double bulge,
  ) {
    final Offset along = tip - base;
    final Offset normal =
        Offset(-along.dy, along.dx) / along.distance * bulge * 1.6;
    final Offset middle = base + along / 2;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          (middle + normal).dx,
          (middle + normal).dy,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          (middle - normal).dx,
          (middle - normal).dy,
          base.dx,
          base.dy,
        )
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RecipeCardPainter oldDelegate) =>
      oldDelegate.scheme != scheme;
}
