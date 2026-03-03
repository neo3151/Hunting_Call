import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/payment/domain/repositories/payment_repository.dart';
import 'package:outcall/core/services/revenuecat_service.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// ─── Provider ──────────────────────────────────────────────────────────────
/// Automatically selects RevenueCat on mobile, Mock on desktop.

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final isDesktop = !kIsWeb &&
      (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  if (isDesktop) {
    return MockPaymentRepository(ref.read(profileRepositoryProvider));
  }

  return RevenueCatPaymentRepository(
    rcService: ref.read(revenueCatServiceProvider),
    profileRepo: ref.read(profileRepositoryProvider),
  );
});

/// ─── RevenueCat Implementation ─────────────────────────────────────────────

class RevenueCatPaymentRepository implements PaymentRepository {
  final RevenueCatService _rcService;
  final ProfileRepository _profileRepo;

  RevenueCatPaymentRepository({
    required RevenueCatService rcService,
    required ProfileRepository profileRepo,
  })  : _rcService = rcService,
        _profileRepo = profileRepo;

  @override
  Future<bool> purchasePremium(String userId) async {
    try {
      AppLogger.d('🛒 RevenueCat: Fetching offerings...');
      final packages = await _rcService.getOfferings();

      if (packages.isEmpty) {
        AppLogger.d('🛒 RevenueCat: No offerings available');
        return false;
      }

      // Find monthly package first, fallback to first available
      final package = packages.firstWhere(
        (p) => p.identifier == '\$rc_monthly',
        orElse: () => packages.first,
      );

      AppLogger.d('🛒 RevenueCat: Purchasing ${package.identifier}...');
      final success = await _rcService.purchase(package);

      if (success) {
        await _profileRepo.setPremiumStatus(userId, true);
        AppLogger.d('✅ RevenueCat: User $userId is now PREMIUM');
      }

      return success;
    } catch (e) {
      AppLogger.d('❌ RevenueCat: Purchase failed: $e');
      return false;
    }
  }

  @override
  Future<bool> restorePurchases(String userId) async {
    try {
      AppLogger.d('🛒 RevenueCat: Restoring purchases...');
      final success = await _rcService.restore();

      if (success) {
        await _profileRepo.setPremiumStatus(userId, true);
        AppLogger.d('✅ RevenueCat: Restored premium for $userId');
      }

      return success;
    } catch (e) {
      AppLogger.d('❌ RevenueCat: Restore failed: $e');
      return false;
    }
  }
}

/// ─── Mock Implementation (Desktop) ─────────────────────────────────────────

class MockPaymentRepository implements PaymentRepository {
  final ProfileRepository _profileRepo;

  MockPaymentRepository(this._profileRepo);

  @override
  Future<bool> purchasePremium(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      AppLogger.d('🛒 MockPayment: Processing mock purchase for $userId...');

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
    return purchasePremium(userId);
  }
}
