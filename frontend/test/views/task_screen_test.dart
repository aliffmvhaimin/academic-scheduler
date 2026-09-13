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

    testWidgets('search field filters tasks by name in real-time',
        (WidgetTester tester) async {
      await viewModel.addTask(Task(
        id: 't-1',
        taskName: 'Data Structures',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 9, 20),
        studyDurationHours: 1.0,
      ));
      await viewModel.addTask(Task(
        id: 't-2',
        taskName: 'Operating Systems',
        creditWeight: 4,
        difficultyScore: 8,
        deadline: DateTime(2026, 9, 22),
        studyDurationHours: 2.0,
      ));

      await tester.pumpWidget(buildTestWidget(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('Operating Systems'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byKey(const Key('task_search_field')), 'Oper');
      await tester.pumpAndSettle();

      expect(find.text('Data Structures'), findsNothing);
      expect(find.text('Operating Systems'), findsOneWidget);

      // Clear search query
      await tester.enterText(find.byKey(const Key('task_search_field')), '');
      await tester.pumpAndSettle();

      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('Operating Systems'), findsOneWidget);
    });

    testWidgets('sort chips reorder tasks according to selected criterion',
        (WidgetTester tester) async {
      await viewModel.addTask(Task(
        id: 't-low',
        taskName: 'A Low Credit Task',
        creditWeight: 1,
        difficultyScore: 9,
        deadline: DateTime(2026, 9, 10),
        studyDurationHours: 1.0,
      ));
      await viewModel.addTask(Task(
        id: 't-high',
        taskName: 'B High Credit Task',
        creditWeight: 6,
        difficultyScore: 2,
        deadline: DateTime(2026, 9, 30),
        studyDurationHours: 1.0,
      ));

      await tester.pumpWidget(buildTestWidget(viewModel));
      await tester.pumpAndSettle();

      // Tap "Credits" sort chip
      await tester.tap(find.text('Credits'));
      await tester.pumpAndSettle();

      final cards = tester.widgetList<TaskCard>(find.byType(TaskCard)).toList();
      expect(cards.first.task.id, 't-high');

      // Tap "Difficulty" sort chip
      await tester.tap(find.text('Difficulty'));
      await tester.pumpAndSettle();

      final cardsDiff = tester.widgetList<TaskCard>(find.byType(TaskCard)).toList();
      expect(cardsDiff.first.task.id, 't-low');
    });
  });
}
