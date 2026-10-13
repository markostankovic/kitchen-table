// phase9-household-list -- membershipFromWire, the decoder for one row of
// RemoteHouseholdDataSource.fetchMembershipRows: the caller's own
// household_members row, its household embedded, that household's member
// ids nested under it.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/households/data/dto/household_dto.dart';
import 'package:kitchen_table/features/households/domain/household_member.dart';
import 'package:kitchen_table/features/households/domain/household_membership.dart';

Map<String, dynamic> _row({
  String role = 'adult',
  String? deletedAt,
  List<String> memberIds = const <String>['u1', 'u2'],
}) => <String, dynamic>{
  'role': role,
  'created_at': '2026-10-13T09:17:00.314409+00:00',
  'households': <String, dynamic>{
    'id': 'h1',
    'name': 'Kod Mire',
    'created_by': 'u2',
    'deleted_at': deletedAt,
    'household_members': <Map<String, dynamic>>[
      for (final String id in memberIds) <String, dynamic>{'user_id': id},
    ],
  },
};

void main() {
  test('decodes the household, the role and the member count', () {
    final HouseholdMembership m = membershipFromWire(_row());

    expect(m.household.id, 'h1');
    expect(m.household.name, 'Kod Mire');
    expect(m.household.createdBy, 'u2');
    expect(m.household.deletedAt, isNull);
    expect(m.role, HouseholdRole.adult);
    expect(m.memberCount, 2);
  });

  test('maps owner the same way member rows do', () {
    expect(membershipFromWire(_row(role: 'owner')).role, HouseholdRole.owner);
  });

  test('a lone member counts as one', () {
    expect(
      membershipFromWire(_row(memberIds: const <String>['u1'])).memberCount,
      1,
    );
  });

  test('a nested deleted_at survives the decode', () {
    final HouseholdMembership m = membershipFromWire(
      _row(deletedAt: '2026-01-01T00:00:00Z'),
    );
    expect(m.household.deletedAt, DateTime.parse('2026-01-01T00:00:00Z'));
  });
}
