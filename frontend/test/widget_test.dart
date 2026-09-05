import 'package:flutter_test/flutter_test.dart';
import 'package:academic_scheduler/app.dart';

void main() {
  testWidgets('AcademicSchedulerApp launches with navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const AcademicSchedulerApp());

    // App should launch with the Tasks tab visible
    expect(find.text('Tasks'), findsWidgets);

    // Bottom navigation bar should show all 4 tabs
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Availability'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches screens', (WidgetTester tester) async {
    await tester.pumpWidget(const AcademicSchedulerApp());

    // Start on Tasks tab
    expect(find.text('No Tasks Yet'), findsOneWidget);

    // Tap Schedule tab
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('No Schedule Generated'), findsOneWidget);

    // Tap Availability tab
    await tester.tap(find.text('Availability'));
    await tester.pumpAndSettle();
    expect(find.text('No Availability Set'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Version 1.0.0'), findsOneWidget);
  });
}
