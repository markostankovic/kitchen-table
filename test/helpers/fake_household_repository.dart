import 'package:kitchen_table/features/households/data/household_repository.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_member.dart';
import 'package:kitchen_table/features/households/domain/household_membership.dart';
import 'package:kitchen_table/features/households/domain/invite_redemption.dart';

/// An in-memory [HouseholdRepository] that answers the multi-household reads
/// the way the real one does (D169): [fetchCurrent] is the [select]ed
/// household if [userId] is still in it, else the oldest in [households].
///
/// [create] and [redeemInvite] append a household and return it, so a
/// test can see onboarding end on the NEW household. `implements`, the house
/// style: every unstubbed member throws by omission.
class FakeHouseholdRepository implements HouseholdRepository {
  FakeHouseholdRepository([List<Household>? households])
      : households = households ?? <Household>[];

  /// Oldest first, as `fetchMineRows` orders them.
  final List<Household> households;

  /// The selection per user, as `DevicePreferences` would hold it.
  final Map<String, String> selected = <String, String>{};

  /// Every `select` call, in order.
  final List<String> selectCalls = <String>[];

  @override
  Future<List<Household>> fetchMine() async =>
      List<Household>.of(households);

  /// In [households]' order, which doubles as join order here: [create] and
  /// [redeemInvite] append. Owner of what [userId] created, adult otherwise.
  @override
  Future<List<HouseholdMembership>> fetchMemberships({
    required String userId,
  }) async => <HouseholdMembership>[
    for (final Household h in households)
      HouseholdMembership(
        household: h,
        role: h.createdBy == userId ? HouseholdRole.owner : HouseholdRole.adult,
        memberCount: 1,
      ),
  ];

  @override
  Future<Household?> fetchCurrent({
    required String userId,
    void Function()? onReachable,
    void Function()? onUnreachable,
  }) async {
    if (households.isEmpty) return null;
    return households.firstWhere(
      (Household h) => h.id == selected[userId],
      orElse: () => households.first,
    );
  }

  @override
  Future<void> select({
    required String userId,
    required String householdId,
  }) async {
    selectCalls.add(householdId);
    selected[userId] = householdId;
  }

  @override
  Future<String> create(String name) async {
    final String id = 'created-${households.length + 1}';
    households.add(Household(id: id, name: name, createdBy: 'u1'));
    return id;
  }

  /// Codes for households already in [households]: redeeming one answers
  /// `alreadyMember: true`, as `redeem-invite` does, and adds nothing.
  final Map<String, String> memberCodes = <String, String>{};

  @override
  Future<InviteRedemption> redeemInvite(String code) async {
    final String? existing = memberCodes[code];
    if (existing != null) {
      final Household h = households.firstWhere(
        (Household h) => h.id == existing,
      );
      return InviteRedemption(
        householdId: h.id,
        householdName: h.name,
        alreadyMember: true,
      );
    }
    final String id = 'joined-$code';
    households.add(Household(id: id, name: 'Joined', createdBy: 'other'));
    return InviteRedemption(
      householdId: id,
      householdName: 'Joined',
      alreadyMember: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
