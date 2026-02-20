import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'package:hunting_calls_perfection/features/home/presentation/home_screen.dart';
import 'package:hunting_calls_perfection/features/auth/domain/repositories/auth_repository.dart';
import 'package:hunting_calls_perfection/features/profile/domain/repositories/profile_repository.dart';
import 'package:hunting_calls_perfection/features/profile/domain/entities/user_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;
  late SharedPreferences mockPrefs;

  setUp(() async {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();

    // Default mock behavior
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
          isLinux: false,
          useMocks: true,
          sharedPreferences: mockPrefs,
        )),
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: HomeScreen(userId: 'test_user'),
      ),
    );
  }

  testWidgets('Should display welcome message with user name', (tester) async {
    final profile = UserProfile(id: 'test_user', name: 'John Doe', joinedDate: DateTime.now());
    when(() => mockProfileRepository.getProfile('test_user')).thenAnswer((_) async => profile);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('WELCOME BACK,'), findsOneWidget);
    expect(find.text('JOHN DOE'), findsOneWidget);
    expect(find.text('OFF-GRID'), findsOneWidget);
  });

  testWidgets('Should display action cards', (tester) async {
    final profile = UserProfile(id: 'test_user', name: 'John Doe', joinedDate: DateTime.now());
    when(() => mockProfileRepository.getProfile('test_user')).thenAnswer((_) async => profile);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Quick'), findsOneWidget);
    expect(find.textContaining('Practice'), findsOneWidget);
    expect(find.textContaining('Daily'), findsOneWidget);
    expect(find.textContaining('Challenge'), findsOneWidget);
  });

  testWidgets('Should trigger sign out when logout button is tapped', (tester) async {
    final profile = UserProfile(id: 'test_user', name: 'John Doe', joinedDate: DateTime.now());
    when(() => mockProfileRepository.getProfile('test_user')).thenAnswer((_) async => profile);
    when(() => mockAuthRepository.signOut()).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle(); // Wait for dialog

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Sign Out?'), findsOneWidget);
    
    final signOutButton = find.widgetWithText(TextButton, 'SIGN OUT');
    expect(signOutButton, findsOneWidget);

    await tester.tap(signOutButton);
    // Use pump() instead of pumpAndSettle to avoid timeout from infinite loading animation
    await tester.pump(const Duration(milliseconds: 500)); 

    // HomeScreen now uses authControllerProvider.notifier.signOut()
    // which calls the signOut use case, which calls mockAuthRepository.signOut()
    verify(() => mockAuthRepository.signOut()).called(1);
  });
}
