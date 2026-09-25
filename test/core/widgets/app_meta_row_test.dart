import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_meta_row.dart';

/// The Serbian strings that produced the defect this widget exists for, at
/// roughly the lengths the real ARB file carries.
const List<(IconData, String)> _serbianMeta = <(IconData, String)>[
  (Icons.soup_kitchen_outlined, '8 porcija'),
  (Icons.schedule, '30 min priprema'),
  (Icons.local_fire_department_outlined, '45 min kuvanja'),
  (Icons.star, '4'),
];

Future<void> _pumpAt(WidgetTester tester, double width) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: AppMetaRow(
            items: <Widget>[
              for (final (IconData icon, String label) in _serbianMeta)
                AppMetaItem(icon: icon, label: label),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders every item', (WidgetTester tester) async {
    await _pumpAt(tester, 600);

    for (final (IconData icon, String label) in _serbianMeta) {
      expect(find.byIcon(icon), findsOneWidget);
      expect(find.text(label), findsOneWidget);
    }
  });

  // The regression guard for the Serbian meta-line defect, and the reason
  // AppMetaRow is a widget rather than a `Text` with separators in it.
  testWidgets('an item never splits: it wraps whole, icon with its own text', (
    WidgetTester tester,
  ) async {
    // Narrow enough that the four items cannot fit on one line -- which is
    // the whole point: the row has to break somewhere, and where it breaks
    // is what is being asserted.
    await _pumpAt(tester, 200);

    final Set<double> lines = <double>{};
    for (final (IconData icon, String label) in _serbianMeta) {
      final Offset iconCentre = tester.getCenter(find.byIcon(icon));
      final Offset textCentre = tester.getCenter(find.text(label));
      // Same line: an item's icon and its text are one indivisible unit, so
      // a wrap can never land between them.
      expect(
        iconCentre.dy,
        moreOrLessEquals(textCentre.dy, epsilon: 1),
        reason: '"$label" was split from its own icon',
      );
      lines.add(iconCentre.dy.roundToDouble());
    }

    // And the row really did wrap, so the assertion above was not satisfied
    // by everything happening to fit on one line.
    expect(lines.length, greaterThan(1));
  });

  testWidgets('no separators between items', (WidgetTester tester) async {
    await _pumpAt(tester, 600);

    // The dot-joined run is what broke mid-item. Nothing reintroduces it.
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('a colour tints both halves of an item', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppMetaItem(
            icon: Icons.star,
            label: '4',
            color: Color(0xFFAC3F25),
          ),
        ),
      ),
    );

    expect(
      tester.widget<Icon>(find.byIcon(Icons.star)).color,
      const Color(0xFFAC3F25),
    );
    expect(
      tester.widget<Text>(find.text('4')).style?.color,
      const Color(0xFFAC3F25),
    );
  });
}
