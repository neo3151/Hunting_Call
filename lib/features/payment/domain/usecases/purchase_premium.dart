import 'package:outcall/features/payment/domain/repositories/payment_repository.dart';

/// Use case: Process a premium purchase for a user.
class PurchasePremium {
  final PaymentRepository repository;

  PurchasePremium({required this.repository});

  /// Returns true if the purchase was successful.
  /// Returns true if the purchase was successful.
  Future<bool> call(String userId, {required String productId}) async {
    return repository.purchasePremium(userId, productId: productId);
  }
}

/// Use case: Restore previous purchases for a user.
class RestorePurchases {
  final PaymentRepository repository;

  RestorePurchases({required this.repository});

  /// Returns true if restoration was successful.
  Future<bool> call(String userId) async {
    return repository.restorePurchases(userId);
  }
}
