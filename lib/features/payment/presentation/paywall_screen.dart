import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/payment/presentation/controllers/payment_controller.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/core/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// ─── Paywall Screen ────────────────────────────────────────────────────────
/// Luxury upgrade screen shown when a user tries to access premium content.
/// Matches the gold/charcoal aesthetic of the app.

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  /// Show as a modal bottom sheet (preferred for in-app upsells).
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallScreen(),
    );
  }

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  List<Package> _packages = [];
  Package? _selectedPackage;
  bool _isLoadingOfferings = true;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final rcService = ref.read(revenueCatServiceProvider);
    final packages = await rcService.getOfferings();
    
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoadingOfferings = false;
        if (packages.isNotEmpty) {
          // Try to select yearly by default if available, otherwise first package
          _selectedPackage = packages.firstWhere(
            (p) => p.packageType == PackageType.annual,
            orElse: () => packages.first,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);
    final colors = AppColors.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Drag Handle ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  // ─── Header ─────────────────────────────────
                  _buildHeader(colors),
                  const SizedBox(height: 24),

                  // ─── Feature List ───────────────────────────
                  _buildFeatureList(colors),
                  const SizedBox(height: 28),

                  // ─── Pricing Toggle ─────────────────────────
                  if (_isLoadingOfferings)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    )
                  else if (_packages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No subscription plans available.'),
                    )
                  else
                    _buildPricingToggle(colors),
                  const SizedBox(height: 20),

                  // ─── Purchase Button ────────────────────────
                  if (_selectedPackage != null)
                    _buildPurchaseButton(paymentState, colors),
                  const SizedBox(height: 12),

                  // ─── Restore ────────────────────────────────
                  _buildRestoreButton(paymentState, colors),
                  const SizedBox(height: 16),

                  // ─── Legal ──────────────────────────────────
                  _buildLegal(colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorPalette colors) {
    return Column(
      children: [
        // Gold crown icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentGoldDark, AppColors.accentGold, AppColors.accentGoldLight],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'UNLOCK OUTCALL PRO',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Master every species with unlimited access',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureList(AppColorPalette colors) {
    final features = [
      ('135+ Pro Calls', 'Every species, every sound', Icons.library_music_rounded),
      ('AI Audio Analysis', 'Detailed pitch & rhythm scoring', Icons.insights_rounded),
      ('Progress Map', 'Track your mastery journey', Icons.map_rounded),
      ('Daily Challenges', 'Fresh challenges with XP & rewards', Icons.bolt_rounded),
      ('Global Leaderboard', 'Compete with hunters worldwide', Icons.leaderboard_rounded),
      ('Weather Intel', 'Real-time hunting conditions', Icons.cloud_rounded),
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(f.$3, size: 20, color: AppColors.accentGold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.$1,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    f.$2,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, size: 20, color: AppColors.success),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPricingToggle(AppColorPalette colors) {
    if (_packages.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _packages.map((package) {
          final isSelected = _selectedPackage?.identifier == package.identifier;
          
          String title = package.storeProduct.title;
          // Clean up standard store titles (e.g. "Pro Yearly (Hunting Call)")
          if (title.contains('(')) title = title.split('(').first.trim();
          
          String price = package.storeProduct.priceString;
          String? badge;

          if (package.packageType == PackageType.annual) {
            title = 'Yearly';
            badge = 'Save 50%'; // You could calculate this dynamically if desired
          } else if (package.packageType == PackageType.monthly) {
            title = 'Monthly';
          }

          return _pricingOption(
            title,
            price,
            badge,
            isSelected,
            colors,
            () => setState(() => _selectedPackage = package),
          );
        }).toList(),
      ),
    );
  }

  Widget _pricingOption(
    String title,
    String price,
    String? badge,
    bool selected,
    AppColorPalette colors,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AppColors.accentGold.withValues(alpha: 0.5))
                : null,
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)]
                : null,
          ),
          child: Column(
            children: [
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.textPrimary : colors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.accentGold : colors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(PaymentState paymentState, AppColorPalette colors) {
    final profile = ref.watch(profileNotifierProvider).profile;
    final isProcessing = paymentState.isProcessing;

    String buttonText = 'Upgrade';
    if (_selectedPackage != null) {
      final period = _selectedPackage!.packageType == PackageType.annual ? 'year' : 'month';
      final price = _selectedPackage!.storeProduct.priceString;
      buttonText = 'Upgrade — $price/$period';
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  AppColors.accentGoldDark,
                  AppColors.accentGold,
                  AppColors.accentGoldLight,
                  AppColors.accentGold,
                  AppColors.accentGoldDark,
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                begin: Alignment(-1.0 + 2.0 * _shimmerController.value, 0),
                end: Alignment(1.0 + 2.0 * _shimmerController.value, 0),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isProcessing || _selectedPackage == null
                    ? null
                    : () async {
                        final userId = profile?.id ?? '';
                        if (userId.isEmpty) return;
                        final success = await ref
                            .read(paymentNotifierProvider.notifier)
                            .purchasePremium(userId, packageId: _selectedPackage!.identifier);
                        if (success && context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestoreButton(PaymentState paymentState, AppColorPalette colors) {
    final profile = ref.watch(profileNotifierProvider).profile;

    return TextButton(
      onPressed: paymentState.isProcessing
          ? null
          : () async {
              final userId = profile?.id ?? '';
              if (userId.isEmpty) return;
              final success = await ref
                  .read(paymentNotifierProvider.notifier)
                  .restorePurchases(userId);
              if (success && mounted) {
                Navigator.of(context).pop(true);
              }
            },
      child: Text(
        'Restore Purchases',
        style: TextStyle(
          fontSize: 13,
          color: colors.textTertiary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildLegal(AppColorPalette colors) {
    return Text(
      'Payment will be charged to your Google Play or Apple ID account. '
      'Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.',
      style: TextStyle(
        fontSize: 10,
        color: colors.textSubtle,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}
