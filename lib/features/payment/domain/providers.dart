import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/payment/data/payment_repository.dart';
import 'package:hunting_calls_perfection/features/payment/domain/usecases/purchase_premium.dart';

/// Use case providers for the payment domain layer.
final purchasePremiumUseCaseProvider = Provider<PurchasePremium>((ref) {
  return PurchasePremium(repository: ref.watch(paymentRepositoryProvider));
});

final restorePurchasesUseCaseProvider = Provider<RestorePurchases>((ref) {
  return RestorePurchases(repository: ref.watch(paymentRepositoryProvider));
});
