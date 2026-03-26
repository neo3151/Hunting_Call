import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/library/domain/providers.dart';
import 'package:outcall/core/widgets/upgrade_prompter.dart';
import 'package:outcall/core/services/audio_service.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/library/presentation/call_detail_screen.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/l10n/app_localizations.dart';
import 'package:outcall/main_common.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final String? userId;
  const LibraryScreen({super.key, this.userId});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with RouteAware {
  String _searchQuery = '';
  final List<String> _categories = [
    'All',
    'Favorites',
    'Ducks',
    'Geese',
    'Diving',
    'Big Game',
    'Predators',
    'Land Birds',
  ];
  AudioService? _audioService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioService = ref.read(audioServiceProvider);
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _audioService?.stop();
    super.dispose();
  }

  @override
  void didPushNext() {
    _audioService?.stop();
  }

  Future<void> _togglePlayback(ReferenceCall call) async {
    final profile = ref.read(profileNotifierProvider).profile;
    final isPremium = profile?.isPremium ?? false;
    final checkLockUseCase = ref.read(checkCallLockStatusUseCaseProvider);

    final lockResult = checkLockUseCase.execute(
      callId: call.id,
      isUserPremium: isPremium,
    );

    final isLocked = lockResult.fold(
      (failure) => true, // Default to locked on error
      (locked) => locked,
    );

    if (isLocked) {
      if (mounted) {
        UpgradePrompter.show(context, featureName: 'This Call');
      }
      return;
    }

    final audioService = ref.read(audioServiceProvider);

    try {
      await audioService.play(call.id, call.audioAssetPath);
      if (mounted) setState(() {}); // Trigger rebuild
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not play audio: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToDetail(ReferenceCall call) {
    final profile = ref.read(profileNotifierProvider).profile;
    final isPremium = profile?.isPremium ?? false;
    final checkLockUseCase = ref.read(checkCallLockStatusUseCaseProvider);

    final lockResult = checkLockUseCase.execute(
      callId: call.id,
      isUserPremium: isPremium,
    );

    final isLocked = lockResult.fold(
      (failure) => true, // Default to locked on error
      (locked) => locked,
    );

    if (isLocked) {
      UpgradePrompter.show(context, featureName: 'This Call');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CallDetailScreen(call: call, userId: widget.userId ?? 'anonymous'),
      ),
    );
  }

  List<ReferenceCall> _getFilteredCalls(String category) {
    final filterUseCase = ref.read(filterCallsUseCaseProvider);

    final result = filterUseCase.execute(
      category: category == 'Favorites' ? 'All' : category,
      searchQuery: _searchQuery,
    );

    return result.fold(
      (failure) {
        // Log the error but return empty list to avoid breaking UI
        AppLogger.d('Library filter error: ${failure.message}');
        return <ReferenceCall>[];
      },
      (calls) {
        if (category == 'Favorites') {
          final profile = ref.read(profileNotifierProvider).profile;
          final favorites = profile?.favoriteCallIds ?? [];
          return calls.where((c) => favorites.contains(c.id)).toList();
        }
        return calls;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    final currentlyPlayingId = audioService.currentlyPlayingId;
    final profileState = ref.watch(profileNotifierProvider);
    final isPremium = profileState.profile?.isPremium ?? false;

    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(S.of(context).callLibrary,
                style: GoogleFonts.oswald(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.of(context).textPrimary,
                )),
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                          color: AppColors.of(context).textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search calls...',
                        hintStyle: TextStyle(
                            color: AppColors.of(context).textTertiary),
                        prefixIcon: Icon(Icons.search,
                            color: AppColors.of(context).textTertiary),
                        filled: true,
                        fillColor: AppColors.of(context).cardOverlay,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  // Tabs
                  TabBar(
                    isScrollable: true,
                    indicatorColor: Theme.of(context).primaryColor,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: AppColors.of(context).textTertiary,
                    labelStyle: GoogleFonts.oswald(fontWeight: FontWeight.bold),
                    tabs: _categories
                        .map((cat) => Tab(text: cat.toUpperCase()))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          body: BackgroundWrapper(
            child: SafeArea(
              top: false,
              child: TabBarView(
                children: _categories.map((category) {
                  final filtered = _getFilteredCalls(category);
                  final palette = AppColors.of(context);
                  if (filtered.isEmpty) {
                    return Center(
                        child: Text('No calls found',
                            style: TextStyle(
                                color: palette.textTertiary)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 220, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final call = filtered[index];
                      final isPlaying = currentlyPlayingId == call.id;

                      final checkLockUseCase =
                          ref.read(checkCallLockStatusUseCaseProvider);
                      final lockResult = checkLockUseCase.execute(
                        callId: call.id,
                        isUserPremium: isPremium,
                      );
                      final isLocked = lockResult.getOrElse((l) => true);
                      return _buildCallCard(call, isPlaying, isLocked);
                    },
                  );
                }).toList(),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallCard(ReferenceCall call, bool isPlaying, bool isLocked) {
    final palette = AppColors.of(context);
    final hasImage = call.imageUrl.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: 'View details for ${call.animalName} ${call.callType}',
        child: InkWell(
          onTap: () => _navigateToDetail(call),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background animal image
                if (hasImage)
                  Image.asset(
                    call.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: palette.cardOverlay),
                  ),
                // Dark gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: isLocked ? 0.85 : 0.75),
                        Colors.black.withValues(alpha: isLocked ? 0.7 : 0.45),
                      ],
                    ),
                  ),
                ),
                // Playing/selected highlight overlay
                if (isPlaying)
                  Container(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  ),
                // Border overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLocked
                          ? palette.cardOverlay
                          : isPlaying
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          _buildPlayButton(call, isPlaying, isLocked),
                          const SizedBox(width: 16),
                          // Names
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  call.animalName,
                                  style: GoogleFonts.oswald(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  call.callType,
                                  style: TextStyle(
                                    color: isLocked
                                        ? Colors.white38
                                        : Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (call.scientificName.isNotEmpty)
                                      Flexible(
                                        child: Text(
                                          call.scientificName,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (call.scientificName.isNotEmpty)
                                      const SizedBox(width: 8),
                                    _buildDifficultyBadge(call.difficulty),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Favorite button
                          _buildFavoriteButton(call),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _buildMetricChip(
                              Icons.music_note, '${call.idealPitchHz.toInt()} Hz'),
                          const SizedBox(width: 8),
                          _buildMetricChip(
                              Icons.timer_outlined, '${call.idealDurationSec}s'),
                          const SizedBox(width: 8),
                          const Spacer(),
                          // Learn More Indicator
                          if (call.proTips.isNotEmpty)
                            const Icon(Icons.info_outline,
                                size: 16,
                                color: Colors.white38),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
         ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Theme.of(context).primaryColor;
        break;
      case 'intermediate':
        color = const Color(0xFFFFB74D);
        break;
      case 'pro':
        color = const Color(0xFFE57373);
        break;
      default:
        color = AppColors.of(context).textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.cardOverlay,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(ReferenceCall call) {
    final profileState = ref.watch(profileNotifierProvider);
    final favorites = profileState.profile?.favoriteCallIds ?? [];
    final isFavorite = favorites.contains(call.id);

    return Semantics(
      button: true,
      label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      child: InkWell(
        onTap: () {
          ref.read(profileNotifierProvider.notifier).toggleFavorite(call.id);
        },
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFavorite ? Colors.redAccent : AppColors.of(context).textTertiary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPlayButton(ReferenceCall call, bool isPlaying, bool isLocked) {
    final palette = AppColors.of(context);
    return Semantics(
      button: true,
      label: isPlaying ? 'Stop playback' : 'Play ${call.animalName} audio',
      child: InkWell(
        onTap: () => _togglePlayback(call),
      child: Icon(
        isLocked
            ? Icons.lock_outline
            : isPlaying
                ? Icons.stop_circle_rounded
                : Icons.play_circle_filled_rounded,
        color: isLocked
            ? palette.textSubtle
            : isPlaying
                ? Theme.of(context).primaryColor
                : palette.textSecondary,
        size: 40,
      ),
    ),
    );
  }
}
