import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// ─── Configuration ─────────────────────────────────────────────────────────
/// Replace with your actual RevenueCat API keys from app.revenuecat.com
const _rcAndroidKey = 'test_qwuGdkFTOufuQuBYOarmALWocLU';
const _rcIosKey     = 'test_qwuGdkFTOufuQuBYOarmALWocLU';

/// Entitlement ID configured in RevenueCat dashboard
const rcEntitlementId = 'pro';

/// Product IDs configured in Play Console / App Store Connect
const rcMonthlyProductId = 'outcall_pro_monthly';
const rcYearlyProductId  = 'outcall_pro_yearly';

/// ─── Service ───────────────────────────────────────────────────────────────

class RevenueCatService {
  bool _initialized = false;

  /// Whether RevenueCat is available on this platform.
  bool get isAvailable => !_isDesktop;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  /// Initialize RevenueCat SDK. Call once at app boot (mobile only).
  Future<void> init({String? userId}) async {
    if (_isDesktop) {
      AppLogger.d('💳 RevenueCat: Skipped — desktop platform');
      return;
    }

    if (_initialized) return;

    try {
      final apiKey = Platform.isIOS ? _rcIosKey : _rcAndroidKey;

      final config = PurchasesConfiguration(apiKey);
      if (userId != null) {
        config.appUserID = userId;
      }

      await Purchases.configure(config);
      _initialized = true;

      AppLogger.d('💳 RevenueCat: Initialized successfully');
    } catch (e) {
      AppLogger.d('💳 RevenueCat: Init failed: $e');
    }
  }

  /// Log in the user to RevenueCat (syncs entitlements to their account).
  Future<void> login(String userId) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
      AppLogger.d('💳 RevenueCat: Logged in user $userId');
    } catch (e) {
      AppLogger.d('💳 RevenueCat: Login failed: $e');
    }
  }

  /// Check if the user currently has the "pro" entitlement.
  Future<bool> checkPremiumStatus() async {
    if (!_initialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = customerInfo.entitlements.all[rcEntitlementId]?.isActive ?? false;
      AppLogger.d('💳 RevenueCat: Premium status = $isPro');
      return isPro;
    } catch (e) {
      AppLogger.d('💳 RevenueCat: Status check failed: $e');
      return false;
    }
  }

  /// Get available packages (monthly, yearly, etc.).
  Future<List<Package>> getOfferings() async {
    if (!_initialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages;
    } catch (e) {
      AppLogger.d('💳 RevenueCat: Failed to get offerings: $e');
      return [];
    }
  }

  /// Purchase a specific package.
  Future<bool> purchase(Package package) async {
    if (!_initialized) return false;
    try {
      final result = await Purchases.purchasePackage(package);
      final isPro = result.entitlements.all[rcEntitlementId]?.isActive ?? false;
      AppLogger.d('💳 RevenueCat: Purchase complete, pro=$isPro');
      return isPro;
    } catch (e) {
      // User cancelled or error
      AppLogger.d('💳 RevenueCat: Purchase failed/cancelled: $e');
      return false;
    }
  }

  /// Restore previous purchases.
  Future<bool> restore() async {
    if (!_initialized) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.all[rcEntitlementId]?.isActive ?? false;
      AppLogger.d('💳 RevenueCat: Restore complete, pro=$isPro');
      return isPro;
    } catch (e) {
      AppLogger.d('💳 RevenueCat: Restore failed: $e');
      return false;
    }
  }
}

/// ─── Provider ──────────────────────────────────────────────────────────────

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});
