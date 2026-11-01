import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/team.dart';
import '../../../data/models/team_member.dart';
import '../../../data/repositories/team_repository.dart';
import '../../auth/providers/auth_providers.dart';

enum TeamStatus { loading, none, member, error }

/// The signed-in user's team, or null when they have none yet.
final currentTeamProvider = FutureProvider<Team?>((ref) async {
  final userId = ref.watch(currentUserIdProvider).value;
  if (userId == null) return null;
  return ref.watch(teamRepositoryProvider).fetchMyTeam(userId);
});

/// Members of the current team, oldest first.
final teamMembersProvider = FutureProvider<List<TeamMember>>((ref) async {
  final team = await ref.watch(currentTeamProvider.future);
  if (team == null) return const [];
  return ref.watch(teamRepositoryProvider).fetchMembers(team.id);
});

/// Team state for routing.
///
/// While the provider reloads because the user changed (`isReloading`), the
/// previous user's team must not be trusted, so that counts as loading. A
/// plain refresh keeps showing the known team.
final teamStatusProvider = Provider<TeamStatus>((ref) {
  final team = ref.watch(currentTeamProvider);
  if (team.isReloading) return TeamStatus.loading;
  if (team.hasValue) {
    return team.value == null ? TeamStatus.none : TeamStatus.member;
  }
  if (team.hasError) return TeamStatus.error;
  return TeamStatus.loading;
});
