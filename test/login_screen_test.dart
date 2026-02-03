import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hunting_calls_perfection/injection_container.dart';
import 'package:hunting_calls_perfection/features/auth/presentation/login_screen.dart';
import 'package:hunting_calls_perfection/features/auth/domain/auth_repository.dart';
import 'package:hunting_calls_perfection/features/profile/data/profile_repository.dart';
import 'package:hunting_calls_perfection/features/profile/domain/profile_model.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();

    sl.reset();
    sl.allowReassignment = true;
    sl.registerSingleton<ProfileRepository>(mockProfileRepository);
    sl.registerSingleton<AuthRepository>(mockAuthRepository);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }

  testWidgets('Should display login title and description', (tester) async {
    when(() => mockProfileRepository.getAllProfiles()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('HUNTING\nCALLS'), findsOneWidget);
    expect(find.text('MASTER THE WILD'), findsOneWidget);
  });

  testWidgets('Should display profiles when they exist', (tester) async {
    final profiles = [
      UserProfile(id: '1', name: 'John Doe', joinedDate: DateTime.now(), totalCalls: 10, averageScore: 85),
      UserProfile(id: '2', name: 'Jane Smith', joinedDate: DateTime.now(), totalCalls: 5, averageScore: 90),
    ];

    when(() => mockProfileRepository.getAllProfiles()).thenAnswer((_) async => profiles);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('10 calls • 85% avg'), findsOneWidget);
  });

  testWidgets('Should trigger sign in when a profile is tapped', (tester) async {
    final profile = UserProfile(id: '1', name: 'John Doe', joinedDate: DateTime.now());
    when(() => mockProfileRepository.getAllProfiles()).thenAnswer((_) async => [profile]);
    when(() => mockAuthRepository.signIn(any())).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('John Doe'));
    await tester.pump();

    verify(() => mockAuthRepository.signIn('1')).called(1);
  });

  testWidgets('Should show "NEW HUNTER PROFILE" button', (tester) async {
    when(() => mockProfileRepository.getAllProfiles()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('NEW HUNTER PROFILE'), findsOneWidget);
  });
}
