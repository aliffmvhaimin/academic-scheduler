import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/free_slot.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';
import 'package:academic_scheduler/viewmodels/availability_view_model.dart';
import 'package:academic_scheduler/views/slot_form_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageRepository repository;
  late AvailabilityViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalStorageRepository();
    viewModel = AvailabilityViewModel(repository: repository);
  });

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildDialogTestWidget({
    FreeSlot? initialSlot,
    String? defaultDate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                SlotFormDialog.show(
                  context,
                  initialSlot: initialSlot,
                  defaultDate: defaultDate,
                  viewModel: viewModel,
                );
              },
              child: const Text('OPEN DIALOG'),
            ),
          ),
        ),
      ),
    );
  }

  group('SlotFormDialog - Initialization & Display', () {
    testWidgets('renders add slot dialog with defaults', (WidgetTester tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(buildDialogTestWidget(defaultDate: '2026-09-20'));
      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      expect(find.text('Add Time Slot'), findsOneWidget);
      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('START TIME'), findsOneWidget);
      expect(find.text('END TIME'), findsOneWidget);
      expect(find.text('QUICK PRESETS'), findsOneWidget);
      expect(find.text('ADD SLOT'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      // Default 09:00 - 12:00 = 3.0 hours (12 study blocks)
      expect(find.textContaining('3.0 hours (12 study blocks)'), findsOneWidget);
    });

    testWidgets('renders edit slot dialog with pre-populated values', (WidgetTester tester) async {
      setTallViewport(tester);
      const initial = FreeSlot(date: '2026-09-22', start: '14:00', end: '16:30');
      await viewModel.addSlot(initial);

      await tester.pumpWidget(buildDialogTestWidget(initialSlot: initial));
      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Time Slot'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('16:30'), findsOneWidget);
      expect(find.textContaining('2.5 hours (10 study blocks)'), findsOneWidget);
    });
  });

  group('SlotFormDialog - Presets and Submissions', () {
    testWidgets('tapping preset chip updates time and duration', (WidgetTester tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(buildDialogTestWidget(defaultDate: '2026-09-20'));
      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Tap Evening preset (19–22)
      final eveningChip = find.text('Evening (19–22)');
      expect(eveningChip, findsOneWidget);
      await tester.tap(eveningChip);
      await tester.pumpAndSettle();

      expect(find.text('19:00'), findsOneWidget);
      expect(find.text('22:00'), findsOneWidget);

      // Tap Night preset (20–23)
      final nightChip = find.text('Night (20–23)');
      expect(nightChip, findsOneWidget);
      await tester.tap(nightChip);
      await tester.pumpAndSettle();

      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('23:00'), findsOneWidget);
    });

    testWidgets('successfully creates slot when tapping ADD SLOT', (WidgetTester tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(buildDialogTestWidget(defaultDate: '2026-09-20'));
      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Tap Afternoon preset
      await tester.tap(find.text('Afternoon (14–17)'));
      await tester.pumpAndSettle();

      // Submit
      final addBtn = find.byKey(const Key('save_slot_button'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Add Time Slot'), findsNothing);
      expect(viewModel.slots.length, 1);
      expect(viewModel.slots.first.date, '2026-09-20');
      expect(viewModel.slots.first.start, '14:00');
      expect(viewModel.slots.first.end, '17:00');
    });

    testWidgets('shows error banner when trying to add overlapping slot', (WidgetTester tester) async {
      setTallViewport(tester);
      // Existing slot: 2026-09-20 09:00-12:00
      await viewModel.addSlot(const FreeSlot(date: '2026-09-20', start: '09:00', end: '12:00'));

      await tester.pumpWidget(buildDialogTestWidget(defaultDate: '2026-09-20'));
      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Default slot is also 09:00-12:00 on 2026-09-20
      final addBtn = find.byKey(const Key('save_slot_button'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Should show overlap error and keep dialog open
      expect(find.text('Add Time Slot'), findsOneWidget);
      expect(find.textContaining('Overlaps with existing slot'), findsOneWidget);
      expect(viewModel.slots.length, 1);
    });

    testWidgets('cancel button dismisses dialog without adding slot', (WidgetTester tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(buildDialogTestWidget(defaultDate: '2026-09-20'));
      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      final cancelBtn = find.byKey(const Key('cancel_slot_button'));
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(find.text('Add Time Slot'), findsNothing);
      expect(viewModel.slots, isEmpty);
    });
  });
}
