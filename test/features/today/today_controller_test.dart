import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planner/data/app_exception.dart';
import 'package:planner/data/models/task.dart';
import 'package:planner/data/repositories/tasks_repository.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/today/providers/today_controller.dart';
import 'package:planner/features/today/providers/today_providers.dart';

class MockTasks extends Mock implements TasksRepository {}

final _today = DateTime(2026, 11, 2);

Task task(String id, {DateTime? day, bool done = false, int order = 0}) => Task(
  id: id,
  spaceId: 's1',
  userId: 'u1',
  title: 'Task $id',
  day: day ?? _today,
  done: done,
  createdAt: DateTime(2026, 11, 2, 8, order),
);

void main() {
  setUpAll(() => registerFallbackValue(task('fallback')));

  group('mergeTasks', () {
    test('keeps only the given day, oldest first', () {
      final merged = mergeTasks(
        [
          task('b', order: 2),
          task('a', order: 1),
          task('x', day: DateTime(2026, 11)),
        ],
        const TaskOverlay(),
        _today,
      );
      expect(merged.map((t) => t.id), ['a', 'b']);
    });

    test('applies pending add, done and delete', () {
      final merged = mergeTasks(
        [task('a'), task('b', order: 1)],
        TaskOverlay(
          added: {'c': task('c', order: 3)},
          done: const {'a': true},
          deleted: const {'b'},
        ),
        _today,
      );
      expect(merged.map((t) => t.id), ['a', 'c']);
      expect(merged.first.done, isTrue);
    });

    test('pending changes drop once the server agrees', () {
      final overlay = TaskOverlay(
        added: {'c': task('c')},
        done: const {'a': true},
        deleted: const {'b'},
      );
      final pruned = overlay.prunedBy([task('a', done: true), task('c')]);
      expect(pruned.added, isEmpty);
      expect(pruned.done, isEmpty);
      expect(pruned.deleted, isEmpty);
    });
  });

  group('TodayController', () {
    late MockTasks repo;
    late StreamController<List<Task>> server;
    late ProviderContainer container;

    setUp(() {
      repo = MockTasks();
      server = StreamController<List<Task>>.broadcast();
      container = ProviderContainer(
        overrides: [
          tasksRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
          myTasksProvider.overrideWith((ref) => server.stream),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 2, 9)),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(server.close);
      // Riverpod pauses providers nobody listens to; keep these active.
      container
        ..listen(currentUserIdProvider, (_, _) {})
        ..listen(todayTasksProvider, (_, _) {});
    });

    Future<void> serverSends(List<Task> tasks) async {
      server.add(tasks);
      await Future<void>.delayed(Duration.zero);
    }

    TodayController controller() =>
        container.read(todayControllerProvider.notifier);

    test(
      'a 4th task is blocked in the app, without asking the server',
      () async {
        await container.read(currentUserIdProvider.future);
        await serverSends([
          task('a'),
          task('b', order: 1),
          task('c', order: 2),
        ]);
        final error = await controller().add(title: 'Fourth', spaceId: 's1');
        expect(error?.kind, AppErrorKind.taskLimit);
        verifyNever(() => repo.add(any()));
      },
    );

    test(
      'the database limit rolls back and returns the same message',
      () async {
        when(() => repo.add(any()))
            .thenThrow(const AppException(AppErrorKind.taskLimit));
        await container.read(currentUserIdProvider.future);
        await serverSends([task('a')]);
        final error = await controller().add(title: 'Raced', spaceId: 's1');
        expect(error?.kind, AppErrorKind.taskLimit);
        expect(container.read(todayTasksProvider).value, hasLength(1));
      },
    );

    test('adding shows the task immediately', () async {
      final saved = Completer<void>();
      when(() => repo.add(any())).thenAnswer((_) => saved.future);
      await container.read(currentUserIdProvider.future);
      await serverSends([]);
      final pending = controller().add(title: 'New one', spaceId: 's1');
      expect(container.read(todayTasksProvider).value!.single.title, 'New one');
      saved.complete();
      expect(await pending, isNull);
    });

    test('a failed toggle rolls back', () async {
      when(() => repo.setDone(any(), done: any(named: 'done')))
          .thenThrow(const AppException(AppErrorKind.network));
      await serverSends([task('a')]);
      final error = await controller().toggle(task('a'));
      expect(error?.kind, AppErrorKind.network);
      expect(container.read(todayTasksProvider).value!.single.done, isFalse);
    });

    test('delete hides at once; undo brings it back', () async {
      when(() => repo.delete(any())).thenAnswer((_) async {});
      when(() => repo.restore(any())).thenAnswer((_) async {});
      await serverSends([task('a')]);
      await controller().delete(task('a'));
      expect(container.read(todayTasksProvider).value, isEmpty);
      await controller().restore(task('a'));
      expect(container.read(todayTasksProvider).value, hasLength(1));
    });
  });
}
