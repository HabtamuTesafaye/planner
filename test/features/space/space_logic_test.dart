import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/data/repositories/space_repository.dart';
import 'package:planner/features/space/providers/space_providers.dart';

Space _space(String id, String name, SpaceKind kind) => Space(
  id: id,
  name: name,
  kind: kind,
  joinCode: kind == SpaceKind.team ? 'ABCDEFGH' : null,
  createdAt: DateTime.utc(2026, 11),
);

void main() {
  final personal = _space('p', 'Personal', SpaceKind.personal);
  final zeta = _space('z', 'zeta studio', SpaceKind.team);
  final alpha = _space('a', 'Alpha', SpaceKind.team);

  test('Personal comes first, then teams by name (any case)', () {
    expect(sortSpaces([zeta, alpha, personal]), [personal, alpha, zeta]);
  });

  test('pickSpace: the wanted space when the user is in it', () {
    expect(pickSpace([personal, alpha], 'a'), alpha);
  });

  test('pickSpace: falls back to Personal for unknown or left spaces', () {
    expect(pickSpace([personal, alpha], 'gone'), personal);
    expect(pickSpace([personal, alpha], null), personal);
  });

  test('pickSpace: first space if Personal is somehow missing', () {
    expect(pickSpace([alpha, zeta], null), alpha);
  });
}
