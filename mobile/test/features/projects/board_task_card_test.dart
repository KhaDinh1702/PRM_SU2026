import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/projects/utils/project_board_utils.dart';
import 'package:prm_app/features/projects/widgets/board/board_task_card.dart';
import 'package:prm_app/features/tasks/models/task_model.dart';

const _task = TaskModel(
  id: 'task-1',
  title: 'Test task',
  description: '',
  status: TaskStatus.pending,
  priority: TaskPriority.medium,
  source: TaskSource.project,
);

Widget _subject(VoidCallback onAdvance) {
  return MaterialApp(
    home: Scaffold(
      body: BoardTaskCard(
        task: _task,
        column: BoardColumn.todo,
        assigneeName: 'Tester',
        canSwipe: true,
        onTap: () {},
        onSwipeAdvance: onAdvance,
      ),
    ),
  );
}

void main() {
  testWidgets('swiping left advances the task once', (tester) async {
    var advances = 0;
    await tester.pumpWidget(_subject(() => advances++));

    await tester.drag(find.byType(Dismissible), const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(advances, 1);
  });

  testWidgets('swiping right does not complete or advance the task',
      (tester) async {
    var advances = 0;
    await tester.pumpWidget(_subject(() => advances++));

    await tester.drag(find.byType(Dismissible), const Offset(320, 0));
    await tester.pumpAndSettle();

    expect(advances, 0);
  });
}
