import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/library/presentation/animal_calls_screen.dart';

/// Second-tier screen: shows a grid of animals within a category.
/// Each animal is rendered as a large premium button with its photo.
class AnimalGridScreen extends ConsumerWidget {
  final String category;
  final String? userId;
  final bool selectionMode;

  const AnimalGridScreen({
    super.key,
    required this.category,
    this.userId,
    this.selectionMode = false,
  });

  /// Maps animal names to their image path.
  /// Falls back to a generic icon if no image is found.
  static const Map<String, String> _animalImages = {
    'Mallard Duck': 'assets/images/animals/mallard.png',
    'Wood Duck': 'assets/images/animals/wood_duck.png',
    'Canada Goose': 'assets/images/animals/canada_goose.png',
    'Blue-Winged Teal': 'assets/images/animals/blue_winged_teal.png',
    'Specklebelly Goose': 'assets/images/animals/specklebelly_goose.png',
    'Pintail Duck': 'assets/images/animals/pintail.png',
    'Canvasback Duck': 'assets/images/animals/canvasback.png',
    'Rocky Mountain Elk': 'assets/images/animals/elk.png',
    'Whitetail Deer': 'assets/images/animals/whitetail_buck.png',
    'Fallow Deer': 'assets/images/animals/fallow_deer.png',
    'Mule Deer': 'assets/images/animals/mule_deer.png',
    'Wild Hog': 'assets/images/animals/wild_hog.png',
    'Black Bear': 'assets/images/animals/black_bear.png',
    'Coyote': 'assets/images/animals/coyote.png',
    'Red Fox': 'assets/images/animals/red_fox.png',
    'Arctic Fox': 'assets/images/animals/arctic_fox.png',
    'Cottontail Rabbit': 'assets/images/animals/cottontail_rabbit.png',
    'Raccoon': 'assets/images/animals/raccoon.png',
    'American Badger': 'assets/images/animals/badger.png',
    'Gray Wolf': 'assets/images/animals/gray_wolf.png',
    'Bobcat': 'assets/images/animals/bobcat.png',
    'Puma': 'assets/images/animals/puma.png',
    'Wild Turkey': 'assets/images/animals/turkey.png',
    'Barred Owl': 'assets/images/animals/barred_owl.png',
    'Bobwhite Quail': 'assets/images/animals/quail.png',
    'Ring-Necked Pheasant': 'assets/images/animals/pheasant.png',
    'American Woodcock': 'assets/images/animals/woodcock.png',
    'Mourning Dove': 'assets/images/animals/mourning_dove.png',
    'Great Horned Owl': 'assets/images/animals/great_horned_owl.png',
    'American Crow': 'assets/images/animals/crow.png',
    // New animals (March 2026)
    'Fulvous Whistling-Duck': 'assets/images/animals/fulvous_whistling_duck.png',
    'Muscovy Duck': 'assets/images/animals/muscovy_duck.png',
    'Cinnamon Teal': 'assets/images/animals/cinnamon_teal.png',
    'Egyptian Goose': 'assets/images/animals/egyptian_goose.png',
    'Snow Goose': 'assets/images/animals/snow_goose.png',
    'Emperor Goose': 'assets/images/animals/emperor_goose.png',
    'Greater White-fronted Goose': 'assets/images/animals/white_fronted_goose.png',
    'Trumpeter Swan': 'assets/images/animals/trumpeter_swan.png',
    'Tundra Swan': 'assets/images/animals/tundra_swan.png',
    'Moose': 'assets/images/animals/moose.png',
    'American Beaver': 'assets/images/animals/beaver.png',
    'American Wigeon': 'assets/images/animals/american_wigeon.png',
    'Bufflehead': 'assets/images/animals/bufflehead.png',
    'Gadwall': 'assets/images/animals/gadwall.png',
    'Green-Winged Teal': 'assets/images/animals/green_winged_teal.png',
    'Northern Shoveler': 'assets/images/animals/northern_shoveler.png',
  };

  /// Gradient color pairs per category for visual consistency.
  static const Map<String, List<Color>> _categoryGradients = {
    'Ducks': [Color(0xFF0D4F4F), Color(0xFF1A6B5A)],
    'Geese': [Color(0xFF0A3D4F), Color(0xFF126B6B)],
    'Diving': [Color(0xFF0A2A4F), Color(0xFF1A4B7A)],
    'Big Game': [Color(0xFF4A2C17), Color(0xFF6B3E1F)],
    'Predators': [Color(0xFF2C3E50), Color(0xFF34495E)],
    'Big Cats': [Color(0xFF5D3A1A), Color(0xFF8B5E3C)],
    'Land Birds': [Color(0xFF2E4A1E), Color(0xFF4A6B2E)],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final allCalls = ReferenceDatabase.calls;

    // Filter calls by category (or show all)
    final categoryCalls =
        category == 'All' ? allCalls : allCalls.where((c) => c.category == category).toList();

    // Group by animal name and get unique animals with their call counts
    final Map<String, List<ReferenceCall>> animalGroups = {};
    for (final call in categoryCalls) {
      animalGroups.putIfAbsent(call.animalName, () => []).add(call);
    }

    final animals = animalGroups.keys.toList()..sort();

    // Determine gradient for this category
    final gradientColors =
        _categoryGradients[category] ?? const [Color(0xFF1A1A2E), Color(0xFF16213E)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          category == 'All' ? 'ALL ANIMALS' : category.toUpperCase(),
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: palette.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWrapper(
        child: SafeArea(
          top: false,
          child: animals.isEmpty
              ? Center(
                  child: Text(
                    'No animals found',
                    style: TextStyle(color: palette.textTertiary),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animalName = animals[index];
                      final calls = animalGroups[animalName]!;
                      final imagePath = _animalImages[animalName];
                      // Use the animal's own category gradient (for "All" view)
                      final animalCategory = calls.first.category;
                      final colors = _categoryGradients[animalCategory] ?? gradientColors;

                      return _buildAnimalButton(
                        context: context,
                        animalName: animalName,
                        callCount: calls.length,
                        imagePath: imagePath,
                        gradientColors: colors,
                        scientificName: calls.first.scientificName,
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAnimalButton({
    required BuildContext context,
    required String animalName,
    required int callCount,
    String? imagePath,
    required List<Color> gradientColors,
    String scientificName = '',
  }) {
    return Semantics(
      button: true,
      label: '$animalName, $callCount calls',
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => AnimalCallsScreen(
                animalName: animalName,
                category: category,
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
              if (imagePath != null)
                Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: gradientColors[0],
                    ),
                  ),
                ),
              // ─── Gradient overlay ──────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      gradientColors[0].withValues(alpha: 0.5),
                      gradientColors[1].withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              // ─── Subtle blur ──────────────────────
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
                child: const SizedBox.expand(),
              ),
              // ─── Content ──────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Text(
                      animalName.toUpperCase(),
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (scientificName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        scientificName,
                        style: GoogleFonts.lato(
                          color: Colors.white54,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$callCount ${callCount == 1 ? 'call' : 'calls'}',
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ─── Shine highlight ──────────────────
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
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
}
