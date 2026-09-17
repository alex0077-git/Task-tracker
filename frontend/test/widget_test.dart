import 'package:flutter_test/flutter_test.dart';

import 'package:task_tracker_frontend/main.dart';

void main() {
  testWidgets('Login screen shows title and form', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskTrackerApp());

    expect(find.text('Task Manager'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
