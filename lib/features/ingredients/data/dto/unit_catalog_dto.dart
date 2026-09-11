/// The wire shape of `units` + `unit_names`, and the cache's own encoding of
/// it (D65, Phase 2 part 5).
///
/// [UnitCatalog] is a plain class with no `fromJson`: its lookup maps
/// (`_byAlias`, `_displayNames`) are private with no getters, so a BUILT
/// catalog cannot be re-serialized without widening its API for a reason
/// that has nothing to do with what the catalog is for. This file caches the
/// raw rows the server sent instead, and rebuilds the catalog from them
/// every time -- network read or cache read alike -- which also keeps
/// `to_base` as the exact string PostgREST sent rather than round-tripping
/// it through a `double`, the whole of D60's guarantee.
library;

import '../../domain/unit.dart';
import '../../domain/unit_catalog.dart';

/// What the two `select()`s in `IngredientRepository.fetchUnitCatalog`
/// return, kept together as one thing to fetch, cache and decode.
typedef UnitCatalogRows = ({
  List<Map<String, dynamic>> unitRows,
  List<Map<String, dynamic>> nameRows,
});

UnitCatalog unitCatalogFromRows(UnitCatalogRows rows) => UnitCatalog(
  units: rows.unitRows.map(_toUnit).toList(growable: false),
  aliases: <String, String>{
    for (final Map<String, dynamic> row in rows.nameRows)
      row['name'] as String: row['unit_code'] as String,
  },
  // The is_display_name rows, keyed by code and locale.
  displayNames: <String, String>{
    for (final Map<String, dynamic> row in rows.nameRows)
      if (row['is_display_name'] as bool? ?? false)
        '${row['unit_code']}|${row['locale']}': row['name'] as String,
  },
);

/// What the local cache stores for [UnitCatalogRows] -- the two row arrays,
/// untouched, so [unitCatalogFromRows] reads a cache hit and a network
/// response identically.
Map<String, dynamic> unitCatalogRowsToWire(UnitCatalogRows rows) =>
    <String, dynamic>{'units': rows.unitRows, 'unit_names': rows.nameRows};

UnitCatalogRows unitCatalogRowsFromWire(Map<String, dynamic> json) => (
  unitRows: (json['units'] as List<dynamic>).cast<Map<String, dynamic>>(),
  nameRows: (json['unit_names'] as List<dynamic>).cast<Map<String, dynamic>>(),
);

Unit _toUnit(Map<String, dynamic> row) => Unit(
  code: row['code'] as String,
  family: UnitFamily.values.byName(row['family'] as String),
  // numeric arrives as num or String depending on the value's precision, so
  // it is normalised here rather than trusted.
  toBase: _toDouble(row['to_base']),
  // The same value, untouched -- see Unit.toBaseExact.
  toBaseExact: row['to_base']?.toString(),
  isMetric: row['is_metric'] as bool? ?? false,
);

/// A local copy of `IngredientRepository._toDouble`, not a shared import:
/// that one also serves `_toMatch`, which has nothing to do with the cache,
/// and this file should not have to know it exists to change a unit's
/// decoding. A plain [FormatException] rather than an [AppFailure] -- this
/// function runs inside both `runGuarded` (network) and `cacheOrElse`
/// (cache), and each already turns an unrecognised exception into the right
/// thing for its own context.
double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.parse(s),
  _ => throw const FormatException('Unexpected numeric wire value'),
};
