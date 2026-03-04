/// Abstract interface for payment operations.
/// Lives in the domain layer — implementations go in data/.
abstract class PaymentRepository {
  /// Initiates a purchase flow for the Premium entitlement.
  /// Returns true if successful, false otherwise.
  Future<bool> purchasePremium(String userId, {String? packageId});

  /// Restores purchases (checks store for existing entitlements).
  Future<bool> restorePurchases(String userId);
}
