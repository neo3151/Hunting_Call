import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart' hide PurchaseStatus;
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/payment/data/payment_repository.dart';
import 'package:outcall/features/payment/presentation/controllers/payment_controller.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/l10n/app_localizations.dart';

/// Luxury upgrade screen — fetches real prices from Google Play on mobile,
/// falls back to static prices on desktop or if the store is unavailable.

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

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

class _PaywallScreenState extends ConsumerState<PaywallScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  List<ProductDetails> _storeProducts = [];
  bool _isLoadingProducts = true;

  static const _staticPlans = [
    _PlanOption(id: 'outcall_premium_yearly', title: 'Yearly', price: '\$25.00', period: '/yr'),
  ];

  String _selectedProductId = 'outcall_premium_yearly';

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!_isMobile) {
      if (mounted) setState(() => _isLoadingProducts = false);
      return;
    }
    try {
      final repo = ref.read(paymentRepositoryProvider);
      if (repo is NativePaymentRepository) {
        final products = await repo.queryProducts();
        if (mounted) {
          setState(() {
            _storeProducts = products;
            _isLoadingProducts = false;
            if (_storeProducts.isNotEmpty) {
              final hasYearly = _storeProducts.any((p) => p.id == 'outcall_premium_yearly');
              _selectedProductId = hasYearly ? 'outcall_premium_yearly' : _storeProducts.first.id;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingProducts = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  List<_PlanOption> get _plans {
    if (_storeProducts.isNotEmpty) {
      // Only show yearly plan
      final yearlyProducts = _storeProducts.where((p) => p.id.contains('yearly')).toList();
      final products = yearlyProducts.isNotEmpty ? yearlyProducts : _storeProducts;
      return products.map((p) {
        final cleanPrice = _stripBillingPeriod(p.price);
        return _PlanOption(
          id: p.id,
          title: 'Yearly',
          price: cleanPrice,
          period: '/yr',
        );
      }).toList();
    }
    return _staticPlans;
  }

  /// Strips billing period text from store price strings.
  /// e.g., "$24.99/30 min" → "$24.99", "$14.99 / year" → "$14.99",
  /// "US$149.99 / 5 minutes" → "US$149.99"
  String _stripBillingPeriod(String price) {
    // Strip anything after "/" or " per " that comes after a price amount
    final slashMatch = RegExp(r'^(.*?\d[\d.,]*)\s*/.*$').firstMatch(price);
    if (slashMatch != null) return slashMatch.group(1)!.trim();

    final perMatch = RegExp(r'^(.*?\d[\d.,]*)\s+per\s+.*$', caseSensitive: false).firstMatch(price);
    if (perMatch != null) return perMatch.group(1)!.trim();

    return price;
  }

  _PlanOption get _selectedPlan => _plans.firstWhere(
        (p) => p.id == _selectedProductId,
        orElse: () => _plans.first,
      );

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);
    final colors = AppColors.of(context);

    // Show error feedback when a purchase fails
    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      if (next.status == PurchaseStatus.failed && context.mounted) {
        final errorMsg = next.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg != null && errorMsg.contains('not found')
                ? 'Product not available yet. Please try again later.'
                : 'Purchase failed. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(paymentNotifierProvider.notifier).reset();
      }
    });

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
                  _buildHeader(colors),
                  const SizedBox(height: 24),
                  _buildComparisonMatrix(colors),
                  const SizedBox(height: 28),
                  if (_isLoadingProducts)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    )
                  else
                    _buildPricingToggle(colors),
                  const SizedBox(height: 20),
                  if (!_isLoadingProducts) _buildPurchaseButton(paymentState, colors),
                  const SizedBox(height: 12),
                  _buildRestoreButton(paymentState, colors),
                  const SizedBox(height: 16),
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
                  spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(S.of(context).unlockOutcallPro,
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: colors.textPrimary,
            )),
        const SizedBox(height: 8),
        Text(
          'Master every species with unlimited access',
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildComparisonMatrix(AppColorPalette colors) {
    final features = [
      ('Call Library', 'Limited', 'All 135+ Calls'),
      ('Audio Analysis', 'Basic Info', 'Detailed Scoring'),
      ('Daily Challenge', 'Free Calls Only', 'Unlimited Access'),
      ('Global Rankings', '❌', '✔️'),
      ('Offline Mode', '❌', '✔️'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.cardOverlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(
                  flex: 2,
                  child: Text(S.of(context).featureColumn, style: _matrixHeaderStyle(colors))),
              Expanded(
                  flex: 1,
                  child: Text(S.of(context).freeColumn,
                      textAlign: TextAlign.center, style: _matrixHeaderStyle(colors))),
              Expanded(
                  flex: 1,
                  child: Text(S.of(context).proColumn,
                      textAlign: TextAlign.center,
                      style: _matrixHeaderStyle(colors).copyWith(color: AppColors.accentGold))),
            ]),
          ),
          Divider(color: colors.border, height: 1),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Expanded(
                      flex: 2,
                      child: Text(f.$1,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                  Expanded(
                      flex: 1,
                      child: Text(f.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                  Expanded(
                      flex: 1,
                      child: Text(f.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600))),
                ]),
              )),
        ],
      ),
    );
  }

  TextStyle _matrixHeaderStyle(AppColorPalette colors) {
    return TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: colors.textTertiary);
  }

  Widget _buildPricingToggle(AppColorPalette colors) {
    final plan = _plans.first;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _pricingOption(plan.title, plan.price, true, colors, () {}),
        ],
      ),
    );
  }

  Widget _pricingOption(
      String title, String price, bool selected, AppColorPalette colors, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border:
                selected ? Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)) : null,
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)]
                : null,
          ),
          child: Column(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? colors.textPrimary : colors.textTertiary)),
            const SizedBox(height: 2),
            Text(price,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.accentGold : colors.textSubtle)),
          ]),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(PaymentState paymentState, AppColorPalette colors) {
    final profile = ref.watch(profileNotifierProvider).profile;
    final isProcessing = paymentState.isProcessing;
    final plan = _selectedPlan;
    final buttonText = 'Upgrade — ${plan.price}${plan.period}';

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
                  AppColors.accentGoldDark
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
                    offset: const Offset(0, 4))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isProcessing
                    ? null
                    : () async {
                        final userId = profile?.id ?? '';
                        if (userId.isEmpty) return;
                        final success = await ref
                            .read(paymentNotifierProvider.notifier)
                            .purchasePremium(userId, packageId: _selectedProductId);
                        if (context.mounted) {
                          if (success) {
                            Navigator.of(context).pop(true);
                          }
                          // Error feedback is handled by the ref.listen above
                        }
                      },
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(buttonText,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5)),
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
              final success =
                  await ref.read(paymentNotifierProvider.notifier).restorePurchases(userId);
              if (success && mounted) Navigator.of(context).pop(true);
            },
      child: Text('Restore Purchases',
          style: TextStyle(
              fontSize: 13, color: colors.textTertiary, decoration: TextDecoration.underline)),
    );
  }

  Widget _buildLegal(AppColorPalette colors) {
    return Text(
      'Payment will be charged to your Google Play or Apple ID account. '
      'Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.',
      style: TextStyle(fontSize: 10, color: colors.textSubtle, height: 1.5),
      textAlign: TextAlign.center,
    );
  }
}

class _PlanOption {
  final String id;
  final String title;
  final String price;
  final String period;
  const _PlanOption(
      {required this.id, required this.title, required this.price, required this.period});
}
