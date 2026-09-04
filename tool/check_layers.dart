// Import-boundary enforcement for the layering rules in CLAUDE.md and
// docs/ARCHITECTURE.md.
//
// Conventions in a document get ignored around session forty (ARCHITECTURE.md,
// "Enforcement"). This script is what actually holds the `data/` boundary, and
// that boundary is what makes the Phase 2 offline decision (D12) a one-file
// change per feature instead of a rewrite.
//
// Usage: dart run tool/check_layers.dart [rootDir]
// Exits 0 when clean, 1 with a file:line list otherwise.

import 'dart:io';

/// A single boundary violation, rendered as `path:line - message`.
class Violation {
  Violation(this.path, this.line, this.message);

  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line - $message';
}

/// Matches `import '...'` / `export '...'`, single or double quoted.
final RegExp _importRe =
    RegExp('''^\\s*(?:import|export)\\s+['"]([^'"]+)['"]''', multiLine: false);

/// Types that must not cross out of `data/` (CLAUDE.md rule 1).
const Map<String, String> _bannedTypes = <String, String>{
  'Map<String, dynamic>':
      'raw maps must be converted to a domain model inside data/',
  'PostgrestException':
      'Supabase errors must be translated to an AppFailure inside data/',
};

void main(List<String> args) {
  final String root = args.isEmpty ? '.' : args.first;
  final Directory libDir = Directory('$root/lib');

  if (!libDir.existsSync()) {
    stderr.writeln('check_layers: no lib/ directory under "$root"');
    exit(2);
  }

  final String packageName = _readPackageName(root);
  final List<Violation> violations = <Violation>[];

  for (final FileSystemEntity entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    // Generated code is committed (CLAUDE.md) but is not hand-written, so it is
    // not the author's boundary to defend.
    if (entity.path.endsWith('.g.dart') ||
        entity.path.endsWith('.freezed.dart')) {
      continue;
    }

    final String relPath = _relative(entity.path, root);
    final List<String> lines = entity.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final int lineNo = i + 1;

      final RegExpMatch? match = _importRe.firstMatch(line);
      if (match != null) {
        _checkImport(
          violations: violations,
          fromPath: relPath,
          uri: match.group(1)!,
          lineNo: lineNo,
          packageName: packageName,
        );
      }

      _checkBannedTypes(violations, relPath, line, lineNo);
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('check_layers: OK');
    exit(0);
  }

  stderr.writeln('check_layers: ${violations.length} violation(s)\n');
  for (final Violation v in violations) {
    stderr.writeln('  $v');
  }
  stderr.writeln('\nSee CLAUDE.md "Hard rules" and docs/ARCHITECTURE.md.');
  exit(1);
}

void _checkImport({
  required List<Violation> violations,
  required String fromPath,
  required String uri,
  required int lineNo,
  required String packageName,
}) {
  final String? layer = _layerOf(fromPath);
  final String? feature = _featureOf(fromPath);

  // --- Rules on the imported package itself -------------------------------

  if (uri.startsWith('package:supabase_flutter')) {
    final bool allowed =
        layer == 'data' || fromPath.startsWith('lib/core/supabase/');
    if (!allowed) {
      violations.add(Violation(fromPath, lineNo,
          'supabase_flutter may only be imported in data/ or core/supabase/'));
    }
  }

  if (uri.startsWith('package:drift')) {
    if (layer != 'data') {
      violations.add(Violation(
          fromPath, lineNo, 'drift may only be imported in data/'));
    }
  }

  if (layer == 'domain' && uri.startsWith('package:flutter/')) {
    violations.add(Violation(fromPath, lineNo,
        'domain models are pure Dart -- no Flutter imports (rule 7)'));
  }

  // --- Rules on the resolved target path ----------------------------------

  final String? target = _resolveTarget(uri, fromPath, packageName);
  if (target == null) return;

  final String? targetLayer = _layerOf(target);
  final String? targetFeature = _featureOf(target);

  if (layer == 'presentation' && targetLayer == 'data') {
    violations.add(Violation(
        fromPath, lineNo, 'presentation/ must never import data/'));
  }

  if (layer == 'domain' && targetLayer != null && targetLayer != 'domain') {
    violations.add(Violation(fromPath, lineNo,
        'domain/ may not import $targetLayer/ -- domain depends on nothing'));
  }

  final bool crossFeature = feature != null &&
      targetFeature != null &&
      feature != targetFeature;
  if (crossFeature && targetLayer != 'domain') {
    violations.add(Violation(
        fromPath,
        lineNo,
        'cross-feature imports go through domain/ only: '
        '$feature -> $targetFeature/$targetLayer'));
  }
}

void _checkBannedTypes(
    List<Violation> violations, String path, String line, int lineNo) {
  final String? layer = _layerOf(path);
  if (layer == null || layer == 'data') return;

  // Cheap comment skip; a banned type inside prose is not a boundary breach.
  final String trimmed = line.trimLeft();
  if (trimmed.startsWith('//') || trimmed.startsWith('///')) return;

  // Serialization entry points are exempt. CLAUDE.md mandates
  // `freezed` + `json_serializable` for all models, and a generated
  // `fromJson` necessarily takes a raw map -- so a literal reading of rule 1
  // would ban the very pattern the stack requires. What rule 1 is actually
  // protecting against is untyped maps used as the currency *between* layers,
  // not the one constructor that converts a map into a typed model.
  if (line.contains('fromJson') || line.contains('toJson')) return;

  for (final MapEntry<String, String> entry in _bannedTypes.entries) {
    if (line.contains(entry.key)) {
      violations.add(Violation(
          path, lineNo, '${entry.key} must not appear in $layer/ -- ${entry.value}'));
    }
  }
}

/// `lib/features/<name>/<layer>/...` -> layer, or null outside a feature.
String? _layerOf(String path) {
  final RegExpMatch? m = RegExp(
          r'^lib/features/[^/]+/(data|domain|application|presentation)(/|$)')
      .firstMatch(path);
  return m?.group(1);
}

/// `lib/features/<name>/...` -> name, or null outside a feature.
String? _featureOf(String path) {
  final RegExpMatch? m = RegExp(r'^lib/features/([^/]+)/').firstMatch(path);
  return m?.group(1);
}

/// Resolves an import URI to a repo-relative `lib/...` path, or null if the
/// import points outside this package (dart:, other packages).
String? _resolveTarget(String uri, String fromPath, String packageName) {
  if (uri.startsWith('dart:')) return null;

  if (uri.startsWith('package:$packageName/')) {
    return 'lib/${uri.substring('package:$packageName/'.length)}';
  }
  if (uri.startsWith('package:')) return null;

  // Relative import: resolve against the importing file's directory.
  final List<String> segments = fromPath.split('/')..removeLast();
  for (final String part in uri.split('/')) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else {
      segments.add(part);
    }
  }
  return segments.join('/');
}

String _relative(String path, String root) {
  final String normRoot = root.endsWith('/') ? root : '$root/';
  String p = path;
  if (p.startsWith(normRoot)) p = p.substring(normRoot.length);
  if (p.startsWith('./')) p = p.substring(2);
  return p;
}

String _readPackageName(String root) {
  final File pubspec = File('$root/pubspec.yaml');
  if (!pubspec.existsSync()) return 'kitchen_table';
  for (final String line in pubspec.readAsLinesSync()) {
    final RegExpMatch? m = RegExp(r'^name:\s*(\S+)').firstMatch(line);
    if (m != null) return m.group(1)!;
  }
  return 'kitchen_table';
}
