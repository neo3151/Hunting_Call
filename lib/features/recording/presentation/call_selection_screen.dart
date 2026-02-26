import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';

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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_selectedCategory != null) {
                setState(() => _selectedCategory = null);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _selectedCategory == null ? 'SELECT CATEGORY' : 'SELECT CALL',
            style: GoogleFonts.oswald(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
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
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
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
                            color: Colors.white,
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
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: isLocked ? null : () => Navigator.pop(context, call.id),
                  tileColor: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
                            color: Colors.white10,
                            child: const Icon(Icons.image, color: Colors.white54),
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
                  enabled: !isLocked,
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
      case 'waterfowl': return Icons.water;
      case 'big game': return Icons.landscape;
      case 'predators': return Icons.security;
      case 'land birds': return Icons.forest;
      default: return Icons.category;
    }
  }
}
