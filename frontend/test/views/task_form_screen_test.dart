import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/task.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';
import 'package:academic_scheduler/viewmodels/task_view_model.dart';
import 'package:academic_scheduler/views/task_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageRepository repository;
  late TaskViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalStorageRepository();
    viewModel = TaskViewModel(repository: repository);
  });

  Widget buildFormWidget({Task? initialTask}) {
    return MaterialApp(
      home: TaskFormScreen(
        initialTask: initialTask,
        viewModel: viewModel,
      ),
    );
  }

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('TaskFormScreen - Validation', () {
    testWidgets('shows validation errors when submitting with empty fields',
        (WidgetTester tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(buildFormWidget());
      await tester.pumpAndSettle();

      // Clear the default duration field to test empty duration validation
      await tester.enterText(find.byKey(const Key('study_duration_input')), '');

      // Tap CREATE TASK button
      final saveBtn = find.byKey(const Key('save_task_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Should show validation error messages
      expect(find.text('Task name is required'), findsOneWidget);
      expect(find.text('Study duration is required'), findsOneWidget);
      expect(viewModel.taskCount, 0);
    });

    testWidgets('shows error for zero or negative study duration',
        (WidgetTester tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(buildFormWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('task_name_input')), 'Valid Name');
      await tester.enterText(
          find.byKey(const Key('study_duration_input')), '0');

      final saveBtn = find.byKey(const Key('save_task_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Duration must be greater than 0 hours'), findsOneWidget);
      expect(viewModel.taskCount, 0);
    });
  });

  group('TaskFormScreen - Creation Flow', () {
    testWidgets('successfully creates new task with user inputs',
        (WidgetTester tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(buildFormWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Task'), findsOneWidget);
      expect(find.text('CREATE TASK'), findsOneWidget);

      // Enter Task Name
      await tester.enterText(
          find.byKey(const Key('task_name_input')), 'Discrete Mathematics');

      // Select Credit Weight 4
      await tester.tap(find.byKey(const Key('credit_weight_4')));
      await tester.pumpAndSettle();
      expect(find.text('4 Credits'), findsOneWidget);

      // Enter Duration 3.5
      final durationInput = find.byKey(const Key('study_duration_input'));
      await tester.ensureVisible(durationInput);
      await tester.enterText(durationInput, '3.5');
      await tester.pumpAndSettle();
      expect(find.text('14 study blocks of 15 min each'), findsOneWidget);

      // Submit
      final saveBtn = find.byKey(const Key('save_task_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify task was added to viewModel
      expect(viewModel.taskCount, 1);
      final created = viewModel.tasks.first;
      expect(created.taskName, 'Discrete Mathematics');
      expect(created.creditWeight, 4);
      expect(created.studyDurationHours, 3.5);
      expect(created.requiredBlocks, 14);
    });

    testWidgets('quick adjustment buttons adjust duration correctly',
        (WidgetTester tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(buildFormWidget());
      await tester.pumpAndSettle();

      // Initial duration is 2.0
      expect(find.text('2.0'), findsOneWidget);

      // Tap +1.0h
      final plusOne = find.text('+1.0h');
      await tester.ensureVisible(plusOne);
      await tester.tap(plusOne);
      await tester.pumpAndSettle();
      expect(find.text('3.0'), findsOneWidget);

      // Tap -0.5h
      final minusHalf = find.text('-0.5h');
      await tester.ensureVisible(minusHalf);
      await tester.tap(minusHalf);
      await tester.pumpAndSettle();
      expect(find.text('2.5'), findsOneWidget);
    });
  });

  group('TaskFormScreen - Edit Flow', () {
    testWidgets('pre-populates fields and updates existing task',
        (WidgetTester tester) async {
      setTallViewport(tester);
      final existingTask = Task(
        id: 'edit-123',
        taskName: 'Original Title',
        creditWeight: 2,
        difficultyScore: 4,
        deadline: DateTime(2026, 9, 30, 23, 59),
        studyDurationHours: 1.5,
      );
      await viewModel.addTask(existingTask);

      await tester.pumpWidget(buildFormWidget(initialTask: existingTask));
      await tester.pumpAndSettle();

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('UPDATE TASK'), findsOneWidget);
      expect(find.text('Original Title'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);
      expect(find.text('2 Credits'), findsOneWidget);

      // Edit title and credit weight
      await tester.enterText(
          find.byKey(const Key('task_name_input')), 'Updated Title');
      await tester.tap(find.byKey(const Key('credit_weight_5')));
      await tester.pumpAndSettle();

      // Submit
      final saveBtn = find.byKey(const Key('save_task_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify updated in viewModel
      expect(viewModel.taskCount, 1);
      final updated = viewModel.tasks.first;
      expect(updated.id, 'edit-123'); // ID preserved
      expect(updated.taskName, 'Updated Title');
      expect(updated.creditWeight, 5);
    });
  });
}
