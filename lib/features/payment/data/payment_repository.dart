
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../../../providers/profile_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return MockPaymentRepository(ref.read(profileRepositoryProvider));
});

abstract class PaymentRepository {
  /// Initiates a purchase flow for the Premium entitlement.
  /// Returns true if successful, false otherwise.
  Future<bool> purchasePremium(String userId);

  /// Restores purchases (checks store for existing entitlements).
  Future<bool> restorePurchases(String userId);
}

class MockPaymentRepository implements PaymentRepository {
  final ProfileRepository _profileRepo;

  MockPaymentRepository(this._profileRepo);

  @override
  Future<bool> purchasePremium(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      debugPrint("🛒 PaymentRepository: Processing mock purchase for $userId...");
      
      // Update profile status
      await _profileRepo.setPremiumStatus(userId, true);
      
      debugPrint("✅ PaymentRepository: User is now PREMIUM.");
      return true;
    } catch (e) {
      debugPrint("❌ PaymentRepository: Purchase failed: $e");
      return false;
    }
  }

  @override
  Future<bool> restorePurchases(String userId) async {
    debugPrint("🛒 PaymentRepository: Restoring purchases for $userId...");
    // For mock, we just say "Yes, restore it" if they click it, or maybe checking logic?
    // For this milestone, let's treat restore as "Give me premium".
    return purchasePremium(userId); 
  }
}
