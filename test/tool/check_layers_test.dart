// Tests for tool/check_layers.dart.
//
// The layer check is the only thing standing between the architecture and
// session forty. A checker that silently passes everything is worse than no
// checker, because the failure is invisible until the boundary has already
// been breached -- so it gets planted violations of its own.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Builds a throwaway package tree and runs the checker against it.
/// Returns the process exit code; stderr is surfaced on unexpected results.
({int exitCode, String output}) runChecker(Map<String, String> files) {
  final Directory tmp = Directory.systemTemp.createTempSync('check_layers');
  addTearDown(() => tmp.deleteSync(recursive: true));

  File('${tmp.path}/pubspec.yaml').writeAsStringSync('name: kitchen_table\n');
  files.forEach((String path, String content) {
    final File f = File('${tmp.path}/$path');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  });

  final ProcessResult result = Process.runSync(
    'dart',
    <String>['run', 'tool/check_layers.dart', tmp.path],
    workingDirectory: Directory.current.path,
  );
  return (
    exitCode: result.exitCode,
    output: '${result.stdout}${result.stderr}',
  );
}

void main() {
  test('passes on a tree that respects the boundaries', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/domain/recipe.dart': "class Recipe {}\n",
      'lib/features/recipes/data/recipe_repository.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';\n",
      'lib/features/recipes/presentation/recipe_list_screen.dart':
          "import '../domain/recipe.dart';\n",
      'lib/features/meal_plan/application/meal_plan_providers.dart':
          "import '../../recipes/domain/recipe.dart';\n",
      'lib/core/supabase/supabase_client.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';\n",
    });
    expect(result.exitCode, 0, reason: result.output);
  });

  test('rejects presentation/ importing data/', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/data/recipe_repository.dart': "class R {}\n",
      'lib/features/recipes/presentation/recipe_list_screen.dart':
          "import '../data/recipe_repository.dart';\n",
    });
    expect(result.exitCode, 1);
    expect(result.output, contains('presentation/ must never import data/'));
  });

  test('rejects supabase_flutter outside data/ and core/supabase/', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/application/recipe_providers.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';\n",
    });
    expect(result.exitCode, 1);
    expect(result.output, contains('supabase_flutter'));
  });

  test('rejects Flutter imports in domain/ (rule 7)', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/domain/recipe.dart':
          "import 'package:flutter/material.dart';\n",
    });
    expect(result.exitCode, 1);
    expect(result.output, contains('pure Dart'));
  });

  test('rejects Map<String, dynamic> escaping data/', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/domain/recipe.dart':
          "class Recipe {\n  Map<String, dynamic>? raw;\n}\n",
    });
    expect(result.exitCode, 1);
    expect(result.output, contains('Map<String, dynamic>'));
  });

  test('rejects PostgrestException escaping data/', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/application/recipe_providers.dart':
          "void f(PostgrestException e) {}\n",
    });
    expect(result.exitCode, 1);
    expect(result.output, contains('PostgrestException'));
  });

  test('rejects AuthException escaping data/', () {
    final result = runChecker(<String, String>{
      'lib/features/auth/application/auth_providers.dart':
          "void f(AuthException e) {}\n",
    });
    expect(result.exitCode, 1);
    expect(result.output, contains('AuthException'));
  });

  test('rejects FunctionException escaping data/', () {
    final result = runChecker(<String, String>{
      'lib/features/households/application/household_providers.dart':
          "void f(FunctionException e) {}\n",
    });
    expect(result.exitCode, 1);
    expect(result.output, contains('FunctionException'));
  });

  test('rejects cross-feature imports that bypass domain/', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/data/recipe_repository.dart': "class R {}\n",
      'lib/features/meal_plan/application/meal_plan_providers.dart':
          "import '../../recipes/data/recipe_repository.dart';\n",
    });
    expect(result.exitCode, 1);
    expect(result.output, contains('cross-feature'));
  });

  test('ignores generated files', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/domain/recipe.freezed.dart':
          "Map<String, dynamic> json = {};\n",
      'lib/features/recipes/domain/recipe.g.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';\n",
    });
    expect(result.exitCode, 0, reason: result.output);
  });

  test('allows Map<String, dynamic> in a fromJson factory', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/domain/recipe.dart':
          "class Recipe {\n"
          "  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe();\n"
          "  Map<String, dynamic> toJson() => <String, dynamic>{};\n"
          "}\n",
    });
    expect(result.exitCode, 0, reason: result.output);
  });

  test('allows a banned type inside a comment', () {
    final result = runChecker(<String, String>{
      'lib/features/recipes/domain/recipe.dart':
          "// Never expose Map<String, dynamic> here.\nclass Recipe {}\n",
    });
    expect(result.exitCode, 0, reason: result.output);
  });
}
