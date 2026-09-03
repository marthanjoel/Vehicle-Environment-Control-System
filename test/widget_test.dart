import 'package:flutter_test/flutter_test.dart';
import 'package:vechilar/main.dart';

void main() {
  testWidgets('Vehicle Environment Control System loads',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VehicularEnvironmentApp());

    expect(
      find.text('ENVIRONMENT CONTROL SYSTEM'),
      findsOneWidget,
    );

    expect(
      find.text('CONNECT TO ARDUINO'),
      findsOneWidget,
    );
  });
}
