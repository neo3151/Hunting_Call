import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hunting_calls_perfection/injection_container.dart';
import 'package:hunting_calls_perfection/features/home/presentation/home_screen.dart';
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
    return const ProviderScope(
      child: MaterialApp(
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
  });

  testWidgets('Should display action cards', (tester) async {
    final profile = UserProfile(id: 'test_user', name: 'John Doe', joinedDate: DateTime.now());
    when(() => mockProfileRepository.getProfile('test_user')).thenAnswer((_) async => profile);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('PRACTICE\nCALL'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('LIBRARY'), findsOneWidget);
  });

  testWidgets('Should trigger sign out when logout button is tapped', (tester) async {
    final profile = UserProfile(id: 'test_user', name: 'John Doe', joinedDate: DateTime.now());
    when(() => mockProfileRepository.getProfile('test_user')).thenAnswer((_) async => profile);
    when(() => mockAuthRepository.signOut()).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    verify(() => mockAuthRepository.signOut()).called(1);
  });
}
