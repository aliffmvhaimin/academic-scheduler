import 'package:flutter_test/flutter_test.dart';
import 'package:academic_scheduler/app.dart';

void main() {
  testWidgets('AcademicSchedulerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AcademicSchedulerApp());
    expect(find.text('Academic Scheduler'), findsOneWidget);
  });
}
