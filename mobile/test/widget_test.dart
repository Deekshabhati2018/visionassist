import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_mobile/main.dart';

void main() {
  testWidgets('user can enter assistance and start a session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VisionAssistApp());

    expect(find.text('VisionAssist'), findsOneWidget);
    expect(find.text('Safety notice'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Assistance is off'), findsOneWidget);
    expect(find.text('Start Assistance'), findsOneWidget);

    await tester.tap(find.text('Start Assistance'));
    await tester.pumpAndSettle();

    expect(find.text('Assistance is active'), findsOneWidget);
    expect(find.text('Stop Assistance'), findsOneWidget);
  });
}