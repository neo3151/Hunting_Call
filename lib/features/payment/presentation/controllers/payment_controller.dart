import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/payment/domain/providers.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

// ──────────────────────────────────────────────────────────
//  STATE
// ──────────────────────────────────────────────────────────

enum PurchaseStatus { idle, processing, success, failed }

class PaymentState {
  final PurchaseStatus status;
  final bool? purchaseResult;
  final String? error;

  const PaymentState({
    this.status = PurchaseStatus.idle,
    this.purchaseResult,
    this.error,
  });

  bool get isProcessing => status == PurchaseStatus.processing;

  PaymentState copyWith({
    PurchaseStatus? status,
    bool? purchaseResult,
    String? error,
    bool clearError = false,
  }) {
    return PaymentState(
      status: status ?? this.status,
      purchaseResult: purchaseResult ?? this.purchaseResult,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  CONTROLLER
// ──────────────────────────────────────────────────────────

class PaymentNotifier extends Notifier<PaymentState> {
  @override
  PaymentState build() {
    return const PaymentState();
  }

  /// Initiate a premium purchase via the domain use case.
  Future<bool> purchasePremium(String userId) async {
    if (state.isProcessing) return false;
    state = state.copyWith(status: PurchaseStatus.processing, clearError: true);
    try {
      final useCase = ref.read(purchasePremiumUseCaseProvider);
      final result = await useCase(userId);
      state = state.copyWith(
        status: result ? PurchaseStatus.success : PurchaseStatus.failed,
        purchaseResult: result,
      );
      return result;
    } catch (e) {
      AppLogger.d('PaymentNotifier: Purchase failed: $e');
      state = state.copyWith(
        status: PurchaseStatus.failed,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Restore previous purchases via the domain use case.
  Future<bool> restorePurchases(String userId) async {
    if (state.isProcessing) return false;
    state = state.copyWith(status: PurchaseStatus.processing, clearError: true);
    try {
      final useCase = ref.read(restorePurchasesUseCaseProvider);
      final result = await useCase(userId);
      state = state.copyWith(
        status: result ? PurchaseStatus.success : PurchaseStatus.failed,
        purchaseResult: result,
      );
      return result;
    } catch (e) {
      AppLogger.d('PaymentNotifier: Restore failed: $e');
      state = state.copyWith(
        status: PurchaseStatus.failed,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Reset state back to idle.
  void reset() {
    state = const PaymentState();
  }
}

final paymentNotifierProvider =
    NotifierProvider<PaymentNotifier, PaymentState>(() {
  return PaymentNotifier();
});
