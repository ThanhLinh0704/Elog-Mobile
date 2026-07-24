import 'package:flutter_test/flutter_test.dart';
import 'package:elog_driver/main.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(const ELogDriverApp());
  });
}
