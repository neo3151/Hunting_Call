import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outcall/core/services/simple_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:outcall/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:outcall/features/profile/data/datasources/secure_profile_data_source.dart';
import 'package:outcall/features/profile/data/datasources/migrating_profile_data_source.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockSimpleStorage extends Mock implements ISimpleStorage {}

void main() {
  late LocalProfileDataSource localDataSource;
  late SecureProfileDataSource secureDataSource;
  late MigratingProfileDataSource migratingDataSource;
  late MockSecureStorage mockSecureStorage;
  late MockSimpleStorage mockStorage;

  const userId = 'test_user_123';
  final testProfile = UserProfile(
    id: userId,
    name: 'Legacy Hunter',
    joinedDate: DateTime(2023, 1, 1),
    isPremium: true,
    totalCalls: 1,
    averageScore: 85.0,
    history: [
      HistoryItem(
        animalId: 'duck',
        timestamp: DateTime(2023, 1, 2),
        result: RatingResult(
          score: 85.0,
          feedback: 'Good pitch',
          pitchHz: 500.0,
          metrics: {'pitch': 0.8, 'duration': 0.9},
        ),
      ),
    ],
  );

  setUp(() async {
    mockStorage = MockSimpleStorage();
    mockSecureStorage = MockSecureStorage();
    
    localDataSource = LocalProfileDataSource(storage: mockStorage);
    secureDataSource = SecureProfileDataSource(secureStorage: mockSecureStorage);
    migratingDataSource = MigratingProfileDataSource(
      localDataSource: localDataSource,
      secureDataSource: secureDataSource,
    );
    
    // Register fallback for String if needed for mocktail any()
    registerFallbackValue('');
    registerFallbackValue(testProfile);
  });

  group('MigratingProfileDataSource', () {
    test('returns secure profile if it already has history or premium', () async {
      // Arrange
      // Create a profile that is "secure" enough to not need migration
      final secureProfile = UserProfile(
        id: userId,
        name: 'Secure Hunter',
        joinedDate: DateTime(2023, 1, 1),
        isPremium: true,
      );
      when(() => mockSecureStorage.read(key: 'user_profile_$userId'))
          .thenAnswer((_) async => json.encode(secureProfile.toJson()));

      // Act
      final result = await migratingDataSource.getProfile(userId);

      // Assert
      expect(result.name, 'Secure Hunter');
      verify(() => mockSecureStorage.read(key: 'user_profile_$userId')).called(1);
      // Should NOT have checked local storage history since secure was sufficient
    });

    test('migrates from local to secure if secure is empty but local has data', () async {
      // Arrange
      // 1. Secure storage returns default profile (no history, not premium)
      final defaultProfile = UserProfile(
        id: userId,
        name: 'New Hunter',
        joinedDate: DateTime.now(),
      );
      when(() => mockSecureStorage.read(key: 'user_profile_$userId'))
          .thenAnswer((_) async => json.encode(defaultProfile.toJson()));
      
      // 2. Local storage has the real data
      when(() => mockStorage.getString('user_profile_$userId'))
          .thenAnswer((_) async => json.encode(testProfile.toJson()));
      
      // 3. Mock save to secure
      when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      // Act
      final result = await migratingDataSource.getProfile(userId);

      // Assert
      expect(result.id, userId);
      expect(result.isPremium, true);
      expect(result.history.length, 1);
      expect(result.name, 'Legacy Hunter');
      
      // Verify migration happened
      verify(() => mockSecureStorage.write(
        key: 'user_profile_$userId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('saveProfile always writes to secure storage only', () async {
      // Arrange
      when(() => mockSecureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await migratingDataSource.saveProfile(testProfile);

      // Assert
      verify(() => mockSecureStorage.write(
        key: 'user_profile_$userId',
        value: any(named: 'value'),
      )).called(1);
      
      // Verify NOT written to local storage
      verifyNever(() => mockStorage.setString('user_profile_$userId', any()));
    });
  });
}
