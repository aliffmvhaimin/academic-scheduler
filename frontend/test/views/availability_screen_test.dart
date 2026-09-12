import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/free_slot.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';
import 'package:academic_scheduler/viewmodels/availability_view_model.dart';
import 'package:academic_scheduler/views/availability_screen.dart';
import 'package:academic_scheduler/widgets/empty_state.dart';
import 'package:academic_scheduler/widgets/slot_card.dart';

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
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildScreenWidget() {
    return MaterialApp(
      home: AvailabilityScreen(viewModel: viewModel),
    );
  }

  group('AvailabilityScreen - Empty State', () {
    testWidgets('renders BrutalistEmptyState when slots list is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      expect(find.byType(BrutalistEmptyState), findsOneWidget);
      expect(find.text('No Availability Set'), findsOneWidget);
      expect(find.text('ADD AVAILABILITY'), findsOneWidget);
      expect(find.byKey(const Key('add_slot_fab')), findsOneWidget);
    });
  });

  group('AvailabilityScreen - Populated State', () {
    testWidgets('renders summary banner, day sections, and slot cards',
        (WidgetTester tester) async {
      setTallViewport(tester);
      const s1 = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      const s2 = FreeSlot(date: '2026-09-14', start: '14:00', end: '17:00');
      const s3 = FreeSlot(date: '2026-09-15', start: '19:00', end: '22:00');

      await viewModel.addSlot(s1);
      await viewModel.addSlot(s2);
      await viewModel.addSlot(s3);

      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      // Empty state should NOT be visible
      expect(find.byType(BrutalistEmptyState), findsNothing);

      // Summary banner
      expect(find.text('DAYS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('TOTAL AVAIL'), findsOneWidget);
      expect(find.text('9.0h'), findsOneWidget);
      expect(find.text('BLOCKS'), findsOneWidget);
      expect(find.text('36'), findsOneWidget);

      // Slot cards
      expect(find.byType(SlotCard), findsNWidgets(3));
      expect(find.text('09:00 – 12:00'), findsOneWidget);
      expect(find.text('14:00 – 17:00'), findsOneWidget);
      expect(find.text('19:00 – 22:00'), findsOneWidget);
      expect(find.text('3.0h • 12 blocks'), findsNWidgets(3));
    });

    testWidgets('auto-fill 7 days button populates week schedule',
        (WidgetTester tester) async {
      setTallViewport(tester);
      // Start with 1 slot so we're in the populated view
      const s1 = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      await viewModel.addSlot(s1);

      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      final templateBtn = find.byKey(const Key('quick_week_template_button'));
      expect(templateBtn, findsOneWidget);
      await tester.ensureVisible(templateBtn);
      await tester.tap(templateBtn);
      await tester.pumpAndSettle();

      // Should have 7 unique dates and 21 slots (3 windows/day * 7)
      expect(viewModel.uniqueDates.length, 7);
      expect(viewModel.totalSlots, 21);
      expect(viewModel.totalAvailableHours, 63.0); // 7 * 9h
      expect(find.text('Applied study schedule to next 7 days'), findsOneWidget);
    });

    testWidgets('delete slot shows confirmation dialog and removes slot on confirm',
        (WidgetTester tester) async {
      setTallViewport(tester);
      const slot = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      await viewModel.addSlot(slot);

      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      expect(find.text('09:00 – 12:00'), findsOneWidget);

      // Tap delete icon on slot card
      final deleteIcon = find.byTooltip('Delete Slot');
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Delete Slot?'), findsOneWidget);
      expect(find.byKey(const Key('cancel_delete_slot_button')), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_slot_button')), findsOneWidget);

      // Cancel keeps slot
      await tester.tap(find.byKey(const Key('cancel_delete_slot_button')));
      await tester.pumpAndSettle();
      expect(find.text('09:00 – 12:00'), findsOneWidget);
      expect(viewModel.totalSlots, 1);

      // Tap delete again and confirm
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_slot_button')));
      await tester.pumpAndSettle();

      // Slot removed, returns to empty state
      expect(find.text('09:00 – 12:00'), findsNothing);
      expect(viewModel.totalSlots, 0);
      expect(find.byType(BrutalistEmptyState), findsOneWidget);
    });

    testWidgets('clear day button removes all slots for that date',
        (WidgetTester tester) async {
      setTallViewport(tester);
      const s1 = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      const s2 = FreeSlot(date: '2026-09-14', start: '14:00', end: '17:00');
      const s3 = FreeSlot(date: '2026-09-15', start: '09:00', end: '12:00');
      await viewModel.addSlot(s1);
      await viewModel.addSlot(s2);
      await viewModel.addSlot(s3);

      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      expect(viewModel.totalSlots, 3);

      // Tap Clear Day for 2026-09-14
      final clearDayButtons = find.byTooltip('Clear Day');
      expect(clearDayButtons, findsNWidgets(2));
      await tester.tap(clearDayButtons.first);
      await tester.pumpAndSettle();

      // Only 2026-09-15 should remain
      expect(viewModel.totalSlots, 1);
      expect(viewModel.slots.first.date, '2026-09-15');
      expect(find.text('09:00 – 12:00'), findsOneWidget);
      expect(find.text('14:00 – 17:00'), findsNothing);
    });
  });
}
