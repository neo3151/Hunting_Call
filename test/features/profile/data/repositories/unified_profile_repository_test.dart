import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outcall/core/services/api_gateway.dart';
import 'package:outcall/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:outcall/features/profile/data/repositories/unified_profile_repository.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';

class MockApiGateway extends Mock implements ApiGateway {}

class MockProfileDataSource extends Mock implements ProfileDataSource {}

Map<String, dynamic> profileJson({required bool isPremium}) => {
      'id': 'user1',
      'name': 'Hunter',
      'joinedDate': DateTime(2025, 1, 1).toIso8601String(),
      'isPremium': isPremium,
    };

void main() {
  late MockApiGateway gateway;
  late UnifiedProfileRepository repository;

  setUp(() {
    gateway = MockApiGateway();
    repository = UnifiedProfileRepository(gateway);
  });

  test('getProfile uses the cloud profile entitlement', () async {
    when(() => gateway.getDocument('profiles', 'user1'))
        .thenAnswer((_) async => profileJson(isPremium: true));

    final profile = await repository.getProfile('user1');

    expect(profile.id, 'user1');
    expect(profile.isPremium, true);
  });

  test('watchProfile emits live premium changes', () async {
    final controller = StreamController<Map<String, dynamic>?>();
    when(() => gateway.streamDocument('profiles', 'user1'))
        .thenAnswer((_) => controller.stream);

    final values = <bool>[];
    final subscription = repository.watchProfile('user1').listen(
          (profile) => values.add(profile!.isPremium),
        );
    controller.add(profileJson(isPremium: false));
    controller.add(profileJson(isPremium: true));
    await Future<void>.delayed(Duration.zero);

    expect(values, [false, true]);
    await subscription.cancel();
    await controller.close();
  });

  test('offline fallback preserves legacy premium without an expiry', () async {
    final localDataSource = MockProfileDataSource();
    final offlineRepository = UnifiedProfileRepository(
      gateway,
      localDataSource: localDataSource,
    );
    when(() => gateway.getDocument('profiles', 'user1'))
        .thenThrow(StateError('offline'));
    when(() => localDataSource.getProfile('user1')).thenAnswer(
      (_) async => UserProfile(
        id: 'user1',
        name: 'Hunter',
        joinedDate: DateTime(2025, 1, 1),
        isPremium: true,
      ),
    );

    final profile = await offlineRepository.getProfile('user1');

    expect(profile.isPremium, true);
  });

  test('offline fallback rejects cached premium after verified expiry',
      () async {
    final localDataSource = MockProfileDataSource();
    final offlineRepository = UnifiedProfileRepository(
      gateway,
      localDataSource: localDataSource,
    );
    when(() => gateway.getDocument('profiles', 'user1'))
        .thenThrow(StateError('offline'));
    when(() => localDataSource.getProfile('user1')).thenAnswer(
      (_) async => UserProfile(
        id: 'user1',
        name: 'Hunter',
        joinedDate: DateTime(2025, 1, 1),
        isPremium: true,
        premiumExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );

    final profile = await offlineRepository.getProfile('user1');

    expect(profile.isPremium, false);
  });

  test('offline fallback honors cached premium before verified expiry',
      () async {
    final localDataSource = MockProfileDataSource();
    final offlineRepository = UnifiedProfileRepository(
      gateway,
      localDataSource: localDataSource,
    );
    when(() => gateway.getDocument('profiles', 'user1'))
        .thenThrow(StateError('offline'));
    when(() => localDataSource.getProfile('user1')).thenAnswer(
      (_) async => UserProfile(
        id: 'user1',
        name: 'Hunter',
        joinedDate: DateTime(2025, 1, 1),
        isPremium: true,
        premiumExpiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    final profile = await offlineRepository.getProfile('user1');

    expect(profile.isPremium, true);
  });
}
