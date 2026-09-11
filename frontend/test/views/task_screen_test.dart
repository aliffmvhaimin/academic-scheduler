import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/task.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';
import 'package:academic_scheduler/viewmodels/task_view_model.dart';
import 'package:academic_scheduler/views/task_screen.dart';
import 'package:academic_scheduler/widgets/empty_state.dart';
import 'package:academic_scheduler/widgets/task_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageRepository repository;
  late TaskViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalStorageRepository();
    viewModel = TaskViewModel(repository: repository);
  });

  Widget buildTestWidget(TaskViewModel vm) {
    return MaterialApp(
      home: TaskScreen(viewModel: vm),
    );
  }

  group('TaskScreen - Empty State', () {
    testWidgets('renders BrutalistEmptyState when tasks list is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(viewModel));
      await tester.pumpAndSettle();

      expect(find.byType(BrutalistEmptyState), findsOneWidget);
      expect(find.text('No Tasks Yet'), findsOneWidget);
      expect(find.text('ADD TASK'), findsOneWidget);
      expect(find.byKey(const Key('add_task_fab')), findsOneWidget);
    });
  });

  group('TaskScreen - Populated Task List', () {
    testWidgets('renders summary banner and task cards',
        (WidgetTester tester) async {
      final task = Task(
        id: 'task-1',
        taskName: 'Algorithm Analysis',
        creditWeight: 4,
        difficultyScore: 8,
        deadline: DateTime(2026, 9, 15, 18, 0),
        studyDurationHours: 3.0,
      );
      await viewModel.addTask(task);

      await tester.pumpWidget(buildTestWidget(viewModel));
      await tester.pumpAndSettle();

      // Empty state should NOT be visible
      expect(find.byType(BrutalistEmptyState), findsNothing);

      // Summary banner metrics
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3.0h'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // 3h * 4 blocks = 12

      // TaskCard details
      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Algorithm Analysis'), findsOneWidget);
      expect(find.text('4 CREDITS'), findsOneWidget);
      expect(find.text('DIFF: 8/10'), findsOneWidget);
      expect(find.text('3.0h (12 blks)'), findsOneWidget);
    });

    testWidgets('delete task shows dialog, cancel keeps task, confirm deletes task',
        (WidgetTester tester) async {
      final task = Task(
        id: 'del-1',
        taskName: 'Task to Delete',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 9, 20),
        studyDurationHours: 1.0,
      );
      await viewModel.addTask(task);

      await tester.pumpWidget(buildTestWidget(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Task to Delete'), findsOneWidget);

      // Tap delete icon on the card
      final deleteIcon = find.byTooltip('Delete Task');
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Confirmation dialog should be shown
      expect(find.text('Delete Task?'), findsOneWidget);
      expect(find.byKey(const Key('cancel_delete_button')), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_button')), findsOneWidget);

      // Cancel deletion
      await tester.tap(find.byKey(const Key('cancel_delete_button')));
      await tester.pumpAndSettle();
      expect(find.text('Task to Delete'), findsOneWidget);
      expect(viewModel.taskCount, 1);

      // Tap delete again and confirm
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_button')));
      await tester.pumpAndSettle();

      // Task should be removed and empty state shown
      expect(find.text('Task to Delete'), findsNothing);
      expect(viewModel.taskCount, 0);
      expect(find.byType(BrutalistEmptyState), findsOneWidget);
    });
  });
}
