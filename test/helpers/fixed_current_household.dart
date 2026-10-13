import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';

/// Stands in for [CurrentHousehold] in a `currentHouseholdProvider`
/// override: `build()` answers with [_read], which runs on every rebuild, so
/// a test can change what it returns between an invalidate and a re-read.
///
/// `currentHouseholdProvider` became a notifier class in multi-household-b
/// (for `switchTo`), so a plain `(Ref ref) async => ...` override no longer
/// fits it.
class FixedCurrentHousehold extends CurrentHousehold {
  FixedCurrentHousehold(this._read);

  final Future<Household?> Function() _read;

  @override
  Future<Household?> build() => _read();
}
