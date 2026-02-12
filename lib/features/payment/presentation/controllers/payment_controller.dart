import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/payment_repository.dart';
import '../../domain/repositories/payment_repository.dart';

/// State for payment operations
class PaymentState {
  final bool isProcessing;
  final bool? purchaseResult;
  final String? error;

  const PaymentState({
    this.isProcessing = false,
    this.purchaseResult,
    this.error,
  });

  PaymentState copyWith({
    bool? isProcessing,
    bool? purchaseResult,
    String? error,
    bool clearError = false,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      purchaseResult: purchaseResult ?? this.purchaseResult,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for payment operations
class PaymentNotifier extends Notifier<PaymentState> {
  @override
  PaymentState build() {
    return const PaymentState();
  }

  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);

  /// Initiate a premium purchase
  Future<bool> purchasePremium(String userId) async {
    if (state.isProcessing) return false;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final result = await _repo.purchasePremium(userId);
      state = state.copyWith(isProcessing: false, purchaseResult: result);
      return result;
    } catch (e) {
      debugPrint("PaymentNotifier: Purchase failed: $e");
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases(String userId) async {
    if (state.isProcessing) return false;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final result = await _repo.restorePurchases(userId);
      state = state.copyWith(isProcessing: false, purchaseResult: result);
      return result;
    } catch (e) {
      debugPrint("PaymentNotifier: Restore failed: $e");
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const PaymentState();
  }
}

final paymentNotifierProvider = NotifierProvider<PaymentNotifier, PaymentState>(() {
  return PaymentNotifier();
});
