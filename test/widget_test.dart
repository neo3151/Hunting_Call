import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outcall/injection_container.dart' as di;

void main() {
  testWidgets('App initializes platform services without crashing', (WidgetTester tester) async {
    // Setup Mock Dependencies
    SharedPreferences.setMockInitialValues({});
    await di.init(useMocks: true);

    // Verify init completed without errors
    expect(di.isFirebaseEnabled, isFalse); // No Firebase in test env
  });
}
