import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outcall/features/payment/data/payment_repository.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';


class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockPaymentRepository paymentRepo;
  late MockProfileRepository mockProfileRepo;

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    paymentRepo = MockPaymentRepository(mockProfileRepo);
  });

  group('MockPaymentRepository', () {
    test('purchasePremium returns true and updates profile', () async {
      // Arrange
      when(() => mockProfileRepo.setPremiumStatus('user1', true))
          .thenAnswer((_) async {});

      // Act
      final result = await paymentRepo.purchasePremium('user1');

      // Assert
      expect(result, true);
      verify(() => mockProfileRepo.setPremiumStatus('user1', true)).called(1);
    });

    test('purchasePremium returns false when profile update fails', () async {
      // Arrange
      when(() => mockProfileRepo.setPremiumStatus('user1', true))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await paymentRepo.purchasePremium('user1');

      // Assert
      expect(result, false);
    });

    test('restorePurchases delegates to purchasePremium', () async {
      // Arrange
      when(() => mockProfileRepo.setPremiumStatus('user1', true))
          .thenAnswer((_) async {});

      // Act
      final result = await paymentRepo.restorePurchases('user1');

      // Assert
      expect(result, true);
      verify(() => mockProfileRepo.setPremiumStatus('user1', true)).called(1);
    });
  });
}
