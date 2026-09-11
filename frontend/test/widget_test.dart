import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AcademicSchedulerApp launches with navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const AcademicSchedulerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // App should launch with the Tasks tab visible
    expect(find.text('Tasks'), findsWidgets);

    // Bottom navigation bar should show all 4 tabs
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Availability'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches screens', (WidgetTester tester) async {
    await tester.pumpWidget(const AcademicSchedulerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Start on Tasks tab
    expect(find.text('No Tasks Yet'), findsOneWidget);

    // Tap Schedule tab
    await tester.tap(find.text('Schedule'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No Schedule Generated'), findsOneWidget);

    // Tap Availability tab
    await tester.tap(find.text('Availability'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No Availability Set'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Version 1.0.0'), findsOneWidget);
  });
}
