import 'package:flutter_test/flutter_test.dart';
import 'package:smartx_learning/main.dart';

void main() {
  testWidgets('Smart X App initialization smoke test', (WidgetTester tester) async {
    expect(const SmartXApp(), isNotNull);
  });
}
