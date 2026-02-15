import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_repository.dart';
import 'usecases/purchase_premium.dart';

/// Use case providers for the payment domain layer.
final purchasePremiumUseCaseProvider = Provider<PurchasePremium>((ref) {
  return PurchasePremium(repository: ref.watch(paymentRepositoryProvider));
});

final restorePurchasesUseCaseProvider = Provider<RestorePurchases>((ref) {
  return RestorePurchases(repository: ref.watch(paymentRepositoryProvider));
});
