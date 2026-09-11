// Phase 2 part 6a, D72 -- the Dart half of the shared-fixture pair. The
// Postgres half is supabase/tests/display_names_test.sql, generated from
// the same fixture by tool/gen_display_name_sql.dart (make test-sql).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/display_name_chain.dart';

void main() {
  final List<dynamic> cases = jsonDecode(
    File('test/fixtures/display_names.json').readAsStringSync(),
  ) as List<dynamic>;

  for (final dynamic entry in cases) {
    final Map<String, dynamic> c = entry as Map<String, dynamic>;
    test(c['description'] as String, () {
      final List<IngredientNameRow> names = (c['names'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> n) => IngredientNameRow(
              name: n['name'] as String,
              locale: n['locale'] as String,
              isDisplayName: n['is_display_name'] as bool,
              createdAt: DateTime.parse(n['created_at'] as String),
            ),
          )
          .toList();

      expect(
        DisplayNameChain.resolve(names, c['locale'] as String),
        c['expected'],
      );
    });
  }
}
