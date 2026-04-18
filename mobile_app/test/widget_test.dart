import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/app/app.dart';

void main() {
  testWidgets('login screen is shown by default', (WidgetTester tester) async {
    await tester.pumpWidget(const DietitianDemoApp());

    expect(find.text('Giris yap'), findsOneWidget);
    expect(find.text('Saglikli rutinin burada basliyor.'), findsOneWidget);
  });
}
