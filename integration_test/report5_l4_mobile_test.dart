import 'package:elog_driver/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('L4-MOB-AUTH-01 - assigned driver signs in to My Trips', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'driver01');
    await tester.enterText(fields.at(1), 'Dev@2025');
    await tester.tap(find.text('\u0110\u0103ng nh\u1eadp'));
    await tester.pumpAndSettle(const Duration(seconds: 15));

    expect(find.textContaining('Chuy\u1ebfn h\u00e0ng c\u1ee7a t\u00f4i'), findsOneWidget);
  });
}
