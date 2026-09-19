import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/di_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outcall/features/payment/data/purchase_verification_service.dart';
import 'package:outcall/features/payment/domain/repositories/payment_repository.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';

/// ─── Constants ─────────────────────────────────────────────────────────────
const kProductIds = <String>{
  'outcall_premium_yearly',
  'outcall_premium_monthly',
};

/// ─── Provider ──────────────────────────────────────────────────────────────
/// Selects NativePaymentRepository on mobile, MockPaymentRepository on desktop.

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final isDesktop =
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  if (isDesktop) {
    return MockPaymentRepository(ref.read(profileRepositoryProvider));
  }

  final repo = NativePaymentRepository(
    profileRepo: ref.read(profileRepositoryProvider),
    verificationService: FirebasePurchaseVerificationService(),
  );
  repo.initialize();

  // Dispose subscription when the provider is destroyed
  ref.onDispose(() => repo.dispose());

  return repo;
});

/// ─── Native In-App Purchase Implementation ─────────────────────────────────

class NativePaymentRepository implements PaymentRepository {
  final ProfileRepository _profileRepo;
  final PurchaseVerificationService _verificationService;
  final InAppPurchase _iap;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  String? _pendingUserId;
  Completer<bool>? _purchaseCompleter;
  Timer? _restoreResolutionTimer;
  bool _isRestoring = false;
  bool _restoreEntitled = false;
  int _pendingRestoreVerifications = 0;

  NativePaymentRepository({
    required ProfileRepository profileRepo,
    required PurchaseVerificationService verificationService,
    InAppPurchase? inAppPurchase,
  })  : _profileRepo = profileRepo,
        _verificationService = verificationService,
        _iap = inAppPurchase ?? InAppPurchase.instance;

  /// Start listening to the global purchase stream.
  void initialize() {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        AppLogger.d('❌ IAP stream error: $error');
        _resolvePurchase(false);
      },
    );
  }

  /// Clean up the purchase stream subscription.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _restoreResolutionTimer?.cancel();
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
      throw Exception(
          'Store not available. Please check your connection and try again.');
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
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      AppLogger.d(
          '⚠️ IAP: Purchase already in progress — ignoring duplicate tap');
      return _purchaseCompleter!.future;
    }

    _pendingUserId = userId;
    _purchaseCompleter = Completer<bool>();
    _isRestoring = false;
    _restoreEntitled = false;
    _pendingRestoreVerifications = 0;
    _restoreResolutionTimer?.cancel();

    // Initiate the purchase — Google Play billing dialog will appear
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);

    // Wait for the purchase stream to resolve
    return _purchaseCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        AppLogger.d('⚠️ IAP: Purchase timed out after 30s');
        _completePurchase(false);
        return false;
      },
    );
  }

  @override
  Future<bool> restorePurchases(String userId) async {
    AppLogger.d('🛒 IAP: Restoring purchases for $userId...');
    _pendingUserId = userId;
    _purchaseCompleter = Completer<bool>();
    _isRestoring = true;
    _restoreEntitled = false;
    _pendingRestoreVerifications = 0;
    _restoreResolutionTimer?.cancel();

    await _iap.restorePurchases();

    // Give the stream a moment to deliver restore events, then resolve
    return _purchaseCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        AppLogger.d('⚠️ IAP: Restore timed out — no purchases found');
        final result = _restoreEntitled;
        _completePurchase(result);
        return result;
      },
    );
  }

  @override
  Future<bool> hasProEntitlement(String userId) async {
    try {
      final profile = await _profileRepo.getProfile(userId);
      return profile.isPremium;
    } catch (_) {
      return false;
    }
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      AppLogger.d(
          '🛒 IAP: Purchase update — ${purchase.productID} status=${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          var userId = _pendingUserId;
          if (userId == null || userId.isEmpty) {
            final authUser = FirebaseAuth.instance.currentUser;
            if (authUser != null && authUser.uid.isNotEmpty) {
              userId = authUser.uid;
              AppLogger.d(
                  'ℹ️ IAP: Recovered user ID $userId from FirebaseAuth instance');
            }
          }

          final isRestoreVerification =
              _isRestoring && purchase.status == PurchaseStatus.restored;
          if (isRestoreVerification) {
            _pendingRestoreVerifications++;
            _restoreResolutionTimer?.cancel();
          }

          try {
            if (userId == null || userId.isEmpty) {
              AppLogger.d(
                  '⚠️ IAP: Purchase succeeded but no user ID could be determined');
              _resolvePurchase(false);
              break;
            }

            final purchaseToken =
                purchase.verificationData.serverVerificationData;
            final result = await _verificationService.verifyAndroidPurchase(
              productId: purchase.productID,
              purchaseToken: purchaseToken,
            );
            AppLogger.d(
                'IAP: Server verification status=${result.status} entitled=${result.entitled}');
            _resolvePurchase(result.entitled);
          } catch (e) {
            AppLogger.d('❌ IAP: Server verification failed: $e');
            _resolvePurchase(false);
          } finally {
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            if (isRestoreVerification) {
              _pendingRestoreVerifications--;
              _scheduleRestoreResolution();
            }
          }
          break;

        case PurchaseStatus.error:
          AppLogger.d('❌ IAP: Purchase error: ${purchase.error?.message}');
          _resolvePurchase(false);

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          AppLogger.d('⚠️ IAP: Purchase cancelled by user');
          _resolvePurchase(false);
          break;

        case PurchaseStatus.pending:
          AppLogger.d('⏳ IAP: Purchase pending...');
          break;
      }
    }
  }

  void _resolvePurchase(bool success) {
    if (success) {
      _restoreEntitled = true;
      _completePurchase(true);
      return;
    }
    if (_isRestoring) {
      _scheduleRestoreResolution();
      return;
    }
    _completePurchase(false);
  }

  void _scheduleRestoreResolution() {
    if (!_isRestoring || _pendingRestoreVerifications > 0) return;
    _restoreResolutionTimer?.cancel();
    _restoreResolutionTimer = Timer(const Duration(seconds: 2), () {
      if (_pendingRestoreVerifications == 0) {
        _completePurchase(_restoreEntitled);
      }
    });
  }

  void _completePurchase(bool success) {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete(success);
    }
    _restoreResolutionTimer?.cancel();
    _isRestoring = false;
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
      AppLogger.d(
          '🛒 MockPayment: Processing mock purchase ($packageId) for $userId...');
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
    try {
      final profile = await _profileRepo.getProfile(userId);
      return profile.isPremium;
    } catch (_) {
      return false;
    }
  }
}
