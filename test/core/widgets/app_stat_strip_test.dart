import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_stat_strip.dart';

Future<void> _pump(WidgetTester tester, List<AppStatColumn> columns) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: AppStatStrip(columns: columns)),
      ),
    );

void main() {
  testWidgets('renders a label above each value, between two hairlines', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const <AppStatColumn>[
      AppStatColumn(label: 'Porcije', value: Text('8')),
      AppStatColumn(label: 'Priprema', value: Text('30 min')),
    ]);

    expect(find.text('Porcije'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
    expect(
      tester.getCenter(find.text('Porcije')).dy,
      lessThan(tester.getCenter(find.text('8')).dy),
    );
  });

  testWidgets('columns share the width equally', (WidgetTester tester) async {
    await _pump(tester, const <AppStatColumn>[
      AppStatColumn(label: 'Porcije', value: Text('8')),
      AppStatColumn(label: 'Priprema', value: Text('30 min')),
      AppStatColumn(label: 'Kuvanje', value: Text('45 min')),
    ]);

    // Equal columns are why this shape survives Serbian: a column is the
    // same width in both languages, where a joined sentence is not.
    final Set<double> widths = <double>{
      for (int i = 0; i < 3; i++)
        tester.getSize(find.byType(Expanded).at(i)).width,
    };
    expect(widths.length, 1);
  });

  // Phase 7 part 3's device walk: each column's value used to hang from its
  // own top edge, so a column of 16dp stars sat lower than a column of 26dp
  // text and the strip read as four things at four heights.
  testWidgets('values from different widgets share one optical line', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const <AppStatColumn>[
      AppStatColumn(label: 'Priprema', value: Text('30 min')),
      AppStatColumn(
        label: 'Ocena',
        value: Icon(Icons.star, size: 16),
      ),
    ]);

    expect(
      tester.getCenter(find.byIcon(Icons.star)).dy,
      moreOrLessEquals(tester.getCenter(find.text('30 min')).dy, epsilon: 1),
    );
  });

  testWidgets('a value can be any widget, not only text', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const <AppStatColumn>[
      AppStatColumn(
        label: 'Ocena',
        // One column on a recipe is five stars, and it is a control.
        value: Icon(Icons.star),
      ),
    ]);

    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
