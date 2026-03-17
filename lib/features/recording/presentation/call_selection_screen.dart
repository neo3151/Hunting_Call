import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/payment/presentation/paywall_screen.dart';
import 'package:outcall/l10n/app_localizations.dart';

class CallSelectionScreen extends ConsumerStatefulWidget {
  const CallSelectionScreen({super.key});

  @override
  ConsumerState<CallSelectionScreen> createState() => _CallSelectionScreenState();
}

class _CallSelectionScreenState extends ConsumerState<CallSelectionScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.of(context).textPrimary),
            onPressed: () {
              if (_selectedCategory != null) {
                setState(() => _selectedCategory = null);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _selectedCategory == null ? S.of(context).selectCategory : S.of(context).selectCall,
            style: GoogleFonts.oswald(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _selectedCategory == null 
              ? _buildCategoryList() 
              : _buildCallList(_selectedCategory!),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final groups = <String>{};
    for (final call in ReferenceDatabase.calls) {
      groups.add(call.category);
    }
    final sortedCategories = groups.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final category = sortedCategories[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  label: category,
                  child: InkWell(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.of(context).border,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            _getCategoryIcon(category), 
                            color: Theme.of(context).primaryColor, 
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          category.toUpperCase(),
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.of(context).textPrimary,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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

  Widget _buildCallList(String category) {
    final calls = ReferenceDatabase.calls.where((c) => c.category == category).toList();
    final isPremium = ref.watch(profileNotifierProvider).profile?.isPremium ?? false;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        final isLocked = ReferenceDatabase.isLocked(call.id, isPremium);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Semantics(
                label: '${call.animalName}, ${call.callType}, ${call.difficulty}${isLocked ? ", locked" : ""}',
                child: Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: isLocked 
                      ? () => PaywallScreen.show(context) 
                      : () => Navigator.pop(context, call.id),
                  tileColor: AppColors.of(context).cardOverlay,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.of(context).border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          call.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 48,
                            height: 48,
                            color: AppColors.of(context).divider,
                            child: Icon(Icons.image, color: AppColors.of(context).textTertiary),
                          ),
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black87,
                            ),
                            child: const Icon(Icons.lock, size: 12, color: Colors.orangeAccent),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    call.animalName,
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.white54 : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    call.callType,
                    style: GoogleFonts.lato(
                      color: isLocked ? Colors.white38 : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  trailing: _buildDifficultyBadge(call.difficulty),
                  enabled: true, // Always enabled so onTap fires, locking handled inside onTap
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy': color = Theme.of(context).primaryColor; break;
      case 'intermediate': color = const Color(0xFFFFB74D); break;
      case 'pro': color = const Color(0xFFE57373); break;
      default: color = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ducks': return Icons.water;
      case 'geese': return Icons.water;
      case 'diving': return Icons.waves;
      case 'waterfowl': return Icons.water;
      case 'big game': return Icons.landscape;
      case 'predators': return Icons.security;
      case 'big cats': return Icons.cruelty_free;
      case 'land birds': return Icons.forest;
      default: return Icons.category;
    }
  }
}
