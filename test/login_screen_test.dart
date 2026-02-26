import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/auth/presentation/login_screen.dart';
import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;
  late SharedPreferences mockPrefs;

  setUp(() async {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();
    
    // Default mocks
    when(() => mockAuthRepository.authStateChanges).thenAnswer((_) => Stream.value(null));
    when(() => mockAuthRepository.currentUser).thenAnswer((_) async => null);
    when(() => mockAuthRepository.isMock).thenReturn(true);

    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        platformEnvironmentProvider.overrideWithValue(PlatformEnvironment(
          isFirebaseEnabled: false,
          isDesktop: false,
          useMocks: true,
          sharedPreferences: mockPrefs,
        )),
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('Should display login title and description', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('OUTCALL'), findsOneWidget);
    expect(find.text('MASTER YOUR CALLS'), findsOneWidget);
  });

  testWidgets('Should show "NEW HUNTER PROFILE" button', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('NEW HUNTER PROFILE'), findsOneWidget);
  });
}
