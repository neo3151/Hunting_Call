import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hunting_calls_perfection/features/profile/domain/repositories/profile_repository.dart';

void main() {
  testWidgets('App initializes dependency injection without crashing', (WidgetTester tester) async {
    // Setup Mock Dependencies
    SharedPreferences.setMockInitialValues({});
    await di.init(useMocks: true);

    // Verify DI completed without errors — check for a known registered type
    expect(di.sl.isRegistered<ProfileRepository>(), isTrue);
  });
}
