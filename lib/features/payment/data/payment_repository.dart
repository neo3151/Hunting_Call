import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/di_providers.dart';
import 'dart:async';
import 'package:outcall/features/payment/domain/repositories/payment_repository.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// ─── Provider ──────────────────────────────────────────────────────────────
/// Automatically selects RevenueCat on mobile, Mock on desktop.

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final isDesktop = !kIsWeb &&
      (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  if (isDesktop) {
    return MockPaymentRepository(ref.read(profileRepositoryProvider));
  }

  final repo = NativePaymentRepository(
    profileRepo: ref.read(profileRepositoryProvider),
  );
  repo.initialize();
  
  ref.onDispose(() {
    repo.dispose();
  });

  return repo;
});

/// ─── Native In-App Purchase Implementation ──────────────────────────────────

class NativePaymentRepository implements PaymentRepository {
  final ProfileRepository _profileRepo;
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // We are storing the current user ID attempting purchase
  // because the purchaseStream callback doesn't intrinsically know who bought it.
  String? _pendingUserId;

  NativePaymentRepository({
    required ProfileRepository profileRepo,
  }) : _profileRepo = profileRepo;

  void initialize() {
    AppLogger.d('🛒 IAP: Initializing payment stream listener...');
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      AppLogger.d('❌ IAP: Purchase stream error: $error');
    });
  }

  void dispose() {
    _subscription.cancel();
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        AppLogger.d('🛒 IAP: Purchase pending for ${purchaseDetails.productID}...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          AppLogger.d('❌ IAP: Purchase error for ${purchaseDetails.productID}: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          AppLogger.d('✅ IAP: Purchase successful for ${purchaseDetails.productID}');
          await handleSuccessfulPurchase(purchaseDetails.productID);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          AppLogger.d('🛒 IAP: Completing purchase for ${purchaseDetails.productID}...');
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  @override
  Future<bool> purchasePremium(String userId, {required String productId}) async {
    try {
      AppLogger.d('🛒 IAP: Preparing to purchase for $userId...');
      _pendingUserId = userId;

      final bool available = await _iap.isAvailable();
      if (!available) {
        AppLogger.d('❌ IAP: Store not available.');
        return false;
      }

      // Query the specific product ID requested by the UI
      final Set<String> kIds = <String>{productId};
      final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.d('⚠️ IAP: ID not found: ${response.notFoundIDs}');
      }

      if (response.productDetails.isEmpty) {
        AppLogger.d('❌ IAP: Product not available to purchase.');
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;

      AppLogger.d('🛒 IAP: Initiating purchase for ${productDetails.id}...');
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      // buyNonConsumable because it's a subscription or lifetime unlock
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      // Note: `buyNonConsumable` only returns true if the native UI was launched.
      // The actual success is handled by checking the purchaseStream in main_common.dart or similar.
      return success;
    } catch (e) {
      AppLogger.d('❌ IAP: Purchase failed: $e');
      return false;
    }
  }

  @override
  Future<bool> restorePurchases(String userId) async {
    try {
      AppLogger.d('🛒 IAP: Restoring purchases for $userId...');
      _pendingUserId = userId;
      await _iap.restorePurchases();
      // As with buy, true success is handled via the purchaseStream callback.
      return true;
    } catch (e) {
      AppLogger.d('❌ IAP: Restore failed: $e');
      return false;
    }
  }

  /// Called by the global stream listener when a purchase is verified.
  Future<void> handleSuccessfulPurchase(String productId) async {
    if (_pendingUserId != null) {
      AppLogger.d('✅ IAP: Verified purchase of $productId for $_pendingUserId');
      await _profileRepo.setPremiumStatus(_pendingUserId!, true);
      _pendingUserId = null;
    } else {
      AppLogger.d('⚠️ IAP: Purchase succeeded but _pendingUserId is null. User may need to restore.');
    }
  }
}

/// ─── Mock Implementation (Desktop) ─────────────────────────────────────────

class MockPaymentRepository implements PaymentRepository {
  final ProfileRepository _profileRepo;

  MockPaymentRepository(this._profileRepo);

  @override
  Future<bool> purchasePremium(String userId, {required String productId}) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      AppLogger.d('🛒 MockPayment: Processing mock purchase ($productId) for $userId...');

      // Update profile status
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
    return purchasePremium(userId, productId: 'outcall_premium_restored');
  }
}
