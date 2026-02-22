import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/profile/domain/repositories/profile_repository.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'package:hunting_calls_perfection/features/payment/domain/repositories/payment_repository.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return MockPaymentRepository(ref.read(profileRepositoryProvider));
});

class MockPaymentRepository implements PaymentRepository {
  final ProfileRepository _profileRepo;

  MockPaymentRepository(this._profileRepo);

  @override
  Future<bool> purchasePremium(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      AppLogger.d('🛒 PaymentRepository: Processing mock purchase for $userId...');
      
      // Update profile status
      await _profileRepo.setPremiumStatus(userId, true);
      
      AppLogger.d('✅ PaymentRepository: User is now PREMIUM.');
      return true;
    } catch (e) {
      AppLogger.d('❌ PaymentRepository: Purchase failed: $e');
      return false;
    }
  }

  @override
  Future<bool> restorePurchases(String userId) async {
    AppLogger.d('🛒 PaymentRepository: Restoring purchases for $userId...');
    // For mock, we just say "Yes, restore it" if they click it, or maybe checking logic?
    // For this milestone, let's treat restore as "Give me premium".
    return purchasePremium(userId); 
  }
}
