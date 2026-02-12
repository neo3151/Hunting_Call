import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hunting_calls_perfection/injection_container.dart';
import 'package:hunting_calls_perfection/features/auth/presentation/login_screen.dart';
import 'package:hunting_calls_perfection/features/auth/domain/repositories/auth_repository.dart';
import 'package:hunting_calls_perfection/features/auth/presentation/controllers/auth_controller.dart';
import 'package:hunting_calls_perfection/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();
    
    // Default mocks
    when(() => mockAuthRepository.authStateChanges).thenAnswer((_) => Stream.value(null));
    when(() => mockAuthRepository.currentUser).thenAnswer((_) async => null);
    when(() => mockAuthRepository.isMock).thenReturn(true);

    sl.reset();
    sl.allowReassignment = true;
    sl.registerSingleton<ProfileRepository>(mockProfileRepository);
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authRepositoryImplProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('Should display login title and description', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('HUNTING\nCALLS'), findsOneWidget);
    expect(find.text('MASTER THE WILD'), findsOneWidget);
  });

  testWidgets('Should show "NEW HUNTER PROFILE" button', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('NEW HUNTER PROFILE'), findsOneWidget);
  });
}
