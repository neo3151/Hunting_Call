import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/payment/domain/repositories/payment_repository.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';

/// ─── Constants ─────────────────────────────────────────────────────────────
const kProductIds = <String>{
  'outcall_premium_yearly',
};

/// ─── Provider ──────────────────────────────────────────────────────────────
/// Selects NativePaymentRepository on mobile, MockPaymentRepository on desktop.

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final isDesktop = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  if (isDesktop) {
    return MockPaymentRepository(ref.read(profileRepositoryProvider));
  }

  final repo = NativePaymentRepository(
    profileRepo: ref.read(profileRepositoryProvider),
  );
  repo.initialize();

  // Dispose subscription when the provider is destroyed
  ref.onDispose(() => repo.dispose());

  return repo;
});

/// ─── Native In-App Purchase Implementation ─────────────────────────────────

class NativePaymentRepository implements PaymentRepository {
  final ProfileRepository _profileRepo;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  String? _pendingUserId;
  Completer<bool>? _purchaseCompleter;

  NativePaymentRepository({
    required ProfileRepository profileRepo,
  }) : _profileRepo = profileRepo;

  /// Start listening to the global purchase stream.
  void initialize() {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        AppLogger.d('❌ IAP stream error: $error');
        _completePurchase(false);
      },
    );
  }

  /// Clean up the purchase stream subscription.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Query products from the store — used by the paywall to show real prices.
  Future<List<ProductDetails>> queryProducts() async {
    if (!await _iap.isAvailable()) {
      AppLogger.d('⚠️ IAP: Store not available');
      return [];
    }

    final response = await _iap.queryProductDetails(kProductIds);
    if (response.error != null) {
      AppLogger.d('❌ IAP: queryProductDetails error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      AppLogger.d('⚠️ IAP: Products not found: ${response.notFoundIDs}');
    }
    return response.productDetails.toList();
  }

  @override
  Future<bool> purchasePremium(String userId, {String? packageId}) async {
    if (!await _iap.isAvailable()) {
      AppLogger.d('❌ IAP: Store not available');
      throw Exception('Store not available. Please check your connection and try again.');
    }

    final productId = packageId ?? 'outcall_premium_yearly';
    AppLogger.d('🛒 IAP: Starting purchase for $productId (user: $userId)');

    // Query the specific product
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      AppLogger.d('❌ IAP: Product $productId not found in store');
      throw Exception('Product not found in store. Please try again later.');
    }

    final product = response.productDetails.first;
    _pendingUserId = userId;
    _purchaseCompleter = Completer<bool>();

    // Initiate the purchase — Google Play billing dialog will appear
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);

    // Wait for the purchase stream to resolve
    return _purchaseCompleter!.future;
  }

  @override
  Future<bool> restorePurchases(String userId) async {
    AppLogger.d('🛒 IAP: Restoring purchases for $userId...');
    _pendingUserId = userId;
    _purchaseCompleter = Completer<bool>();

    await _iap.restorePurchases();

    // Give the stream a moment to deliver restore events, then resolve
    return _purchaseCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        AppLogger.d('⚠️ IAP: Restore timed out — no purchases found');
        _completePurchase(false);
        return false;
      },
    );
  }

  @override
  Future<bool> hasProEntitlement(String userId) async {
    // For native IAP, we rely on the local profile flag.
    // A "restore purchases" flow re-syncs from the store.
    return false;
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      AppLogger.d('🛒 IAP: Purchase update — ${purchase.productID} status=${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify and grant premium
          final userId = _pendingUserId;
          if (userId != null && userId.isNotEmpty) {
            AppLogger.d('✅ IAP: Purchase/restore successful for $userId');
            await _profileRepo.setPremiumStatus(userId, true);
            _completePurchase(true);
          } else {
            AppLogger.d('⚠️ IAP: Purchase succeeded but no pending userId — user should restore');
            _completePurchase(false);
          }

          // IMPORTANT: Complete/finalize the transaction with the store
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          AppLogger.d('❌ IAP: Purchase error: ${purchase.error?.message}');
          _completePurchase(false);

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          AppLogger.d('⚠️ IAP: Purchase cancelled by user');
          _completePurchase(false);
          break;

        case PurchaseStatus.pending:
          AppLogger.d('⏳ IAP: Purchase pending...');
          break;
      }
    }
  }

  void _completePurchase(bool success) {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete(success);
    }
    _pendingUserId = null;
  }
}

/// ─── Mock Implementation (Desktop) ─────────────────────────────────────────

class MockPaymentRepository implements PaymentRepository {
  final ProfileRepository _profileRepo;

  MockPaymentRepository(this._profileRepo);

  @override
  Future<bool> purchasePremium(String userId, {String? packageId}) async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      AppLogger.d('🛒 MockPayment: Processing mock purchase ($packageId) for $userId...');
      await _profileRepo.setPremiumStatus(userId, true);
      AppLogger.d('✅ MockPayment: User is now PREMIUM.');
      return true;
    } catch (e) {
      AppLogger.d('❌ MockPayment: Purchase failed: $e');
      return false;
    }
  }

  @override
  Future<bool> restorePurchases(String userId) async {
    AppLogger.d('🛒 MockPayment: Restoring purchases for $userId...');
    return purchasePremium(userId, packageId: 'outcall_premium_restored');
  }

  @override
  Future<bool> hasProEntitlement(String userId) async {
    return true;
  }
}
