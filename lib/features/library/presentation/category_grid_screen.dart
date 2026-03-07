import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/presentation/animal_calls_screen.dart';
import 'package:outcall/features/library/presentation/animal_grid_screen.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/l10n/app_localizations.dart';

/// Top-level category grid — the entry point for the Library tab.
/// Shows large premium buttons for each category with semi-transparent images.
class CategoryGridScreen extends ConsumerWidget {
  final String? userId;
  final bool selectionMode;
  const CategoryGridScreen({super.key, this.userId, this.selectionMode = false});

  /// Map of category names to representative animal images and gradient colors.
  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      name: 'Waterfowl',
      icon: Icons.water,
      imagePath: 'assets/images/animals/mallard.jpg',
      gradientColors: [Color(0xFF0D4F4F), Color(0xFF1A6B5A)],
    ),
    _CategoryItem(
      name: 'Big Game',
      icon: Icons.terrain,
      imagePath: 'assets/images/animals/elk.jpg',
      gradientColors: [Color(0xFF4A2C17), Color(0xFF6B3E1F)],
    ),
    _CategoryItem(
      name: 'Predators',
      icon: Icons.pets,
      imagePath: 'assets/images/animals/coyote.jpg',
      gradientColors: [Color(0xFF2C3E50), Color(0xFF34495E)],
    ),
    _CategoryItem(
      name: 'Big Cats',
      icon: Icons.cruelty_free,
      imagePath: 'assets/images/animals/bobcat.jpg',
      gradientColors: [Color(0xFF5D3A1A), Color(0xFF8B5E3C)],
    ),
    _CategoryItem(
      name: 'Land Birds',
      icon: Icons.flutter_dash,
      imagePath: 'assets/images/animals/turkey.jpg',
      gradientColors: [Color(0xFF2E4A1E), Color(0xFF4A6B2E)],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);

    // Compute call counts per category from loaded database
    final allCalls = ReferenceDatabase.calls;
    final Map<String, int> categoryCounts = {};
    for (final call in allCalls) {
      categoryCounts[call.category] = (categoryCounts[call.category] ?? 0) + 1;
    }

    // Favorites count
    final profileState = ref.watch(profileNotifierProvider);
    final favorites = profileState.profile?.favoriteCallIds ?? [];
    final favCount = allCalls.where((c) => favorites.contains(c.id)).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          selectionMode ? 'SELECT CALL' : S.of(context).callLibrary,
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: palette.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: selectionMode
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: selectionMode,
      ),
      body: BackgroundWrapper(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
              children: [
                // ─── Special buttons (hidden in selection mode) ──
                if (!selectionMode) ...[
                  // ─── Special: Favorites ─────────────────
                  _buildSpecialButton(
                    context: context,
                    label: 'Favorites',
                    icon: Icons.favorite_rounded,
                    count: favCount,
                    gradientColors: const [Color(0xFF8B1A1A), Color(0xFFC0392B)],
                    onTap: () => _navigateToFavorites(context),
                  ),
                  // ─── Special: All ───────────────────────
                  _buildSpecialButton(
                    context: context,
                    label: 'All Calls',
                    icon: Icons.library_music_rounded,
                    count: allCalls.length,
                    gradientColors: const [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    onTap: () => _navigateToAll(context),
                  ),
                ],
                // ─── Category buttons ───────────────────
                ..._categories.map((cat) => _buildCategoryButton(
                      context: context,
                      item: cat,
                      callCount: categoryCounts[cat.name] ?? 0,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required BuildContext context,
    required _CategoryItem item,
    required int callCount,
  }) {
    return Semantics(
      button: true,
      label: '${item.name} category, $callCount calls',
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => AnimalGridScreen(
                category: item.name,
                userId: userId,
                selectionMode: selectionMode,
              ),
            ),
          );
          if (selectionMode && result != null && context.mounted) {
            Navigator.of(context).pop(result);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─── Background image ──────────────────
              Opacity(
                opacity: 0.35,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              // ─── Gradient overlay ──────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.gradientColors[0].withValues(alpha: 0.85),
                      item.gradientColors[1].withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              // ─── Blur effect ──────────────────────
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: const SizedBox.expand(),
              ),
              // ─── Content ──────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      item.icon,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 28,
                    ),
                    const Spacer(),
                    Text(
                      item.name.toUpperCase(),
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$callCount calls',
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // ─── Shine highlight ──────────────────
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int count,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$label, $count calls',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─── Gradient background ───────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColors[0].withValues(alpha: 0.9),
                      gradientColors[1].withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              // ─── Large faded icon background ───────
              Positioned(
                top: 10,
                right: -10,
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              // ─── Content ──────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 28),
                    const Spacer(),
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count calls',
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFavorites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalCallsScreen(
          userId: userId,
          filterMode: CallFilterMode.favorites,
          title: 'Favorites',
        ),
      ),
    );
  }

  void _navigateToAll(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalGridScreen(
          category: 'All',
          userId: userId,
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String name;
  final IconData icon;
  final String imagePath;
  final List<Color> gradientColors;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.imagePath,
    required this.gradientColors,
  });
}
