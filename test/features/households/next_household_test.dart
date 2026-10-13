// D174 -- the pure pick behind "You'll switch to Y." when leaving the
// current household.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_member.dart';
import 'package:kitchen_table/features/households/domain/household_membership.dart';
import 'package:kitchen_table/features/households/domain/next_household.dart';

HouseholdMembership _m(String id) => HouseholdMembership(
  household: Household(id: id, name: 'Household $id', createdBy: 'u1'),
  role: HouseholdRole.adult,
  memberCount: 1,
);

void main() {
  // Join order: a (oldest), b, c.
  final List<HouseholdMembership> mine = <HouseholdMembership>[
    _m('a'),
    _m('b'),
    _m('c'),
  ];

  test('recent order wins over join order', () {
    expect(
      nextHouseholdAfter('a', mine, <String>['c', 'b'])?.household.id,
      'c',
    );
  });

  test('a stale recent id is skipped', () {
    expect(
      nextHouseholdAfter('a', mine, <String>['gone', 'b'])?.household.id,
      'b',
    );
  });

  test('the leaving id is skipped even when it is the most recent', () {
    expect(
      nextHouseholdAfter('c', mine, <String>['c', 'b', 'a'])?.household.id,
      'b',
    );
  });

  test('an empty recent list falls back to join order', () {
    expect(nextHouseholdAfter('a', mine, const <String>[])?.household.id, 'b');
  });

  test('a single membership gives null', () {
    expect(
      nextHouseholdAfter('a', <HouseholdMembership>[_m('a')], <String>['a']),
      isNull,
    );
  });
}
