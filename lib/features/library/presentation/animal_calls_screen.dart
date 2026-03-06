import 'dart:ui';
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
import 'package:outcall/main_common.dart';

/// Filter mode for the calls screen.
enum CallFilterMode {
  /// Show calls for a specific animal.
  animal,

  /// Show only favorited calls.
  favorites,
}

/// Third-tier screen: shows the list of calls for a specific animal,
/// or a filtered view (e.g., favorites).
class AnimalCallsScreen extends ConsumerStatefulWidget {
  final String? animalName;
  final String? category;
  final String? userId;
  final CallFilterMode filterMode;
  final String? title;

  const AnimalCallsScreen({
    super.key,
    this.animalName,
    this.category,
    this.userId,
    this.filterMode = CallFilterMode.animal,
    this.title,
  });

  @override
  ConsumerState<AnimalCallsScreen> createState() => _AnimalCallsScreenState();
}

class _AnimalCallsScreenState extends ConsumerState<AnimalCallsScreen>
    with RouteAware {
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
      (failure) => true,
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
      if (mounted) setState(() {});
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
      (failure) => true,
      (locked) => locked,
    );

    if (isLocked) {
      UpgradePrompter.show(context, featureName: 'This Call');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallDetailScreen(
            call: call, userId: widget.userId ?? 'anonymous'),
      ),
    );
  }

  List<ReferenceCall> _getCalls() {
    final filterUseCase = ref.read(filterCallsUseCaseProvider);

    if (widget.filterMode == CallFilterMode.favorites) {
      // Get all calls, then filter to favorites
      final result = filterUseCase.execute(
        category: 'All',
        searchQuery: '',
      );
      return result.fold(
        (failure) {
          AppLogger.d('Calls filter error: ${failure.message}');
          return <ReferenceCall>[];
        },
        (calls) {
          final profile = ref.read(profileNotifierProvider).profile;
          final favorites = profile?.favoriteCallIds ?? [];
          return calls.where((c) => favorites.contains(c.id)).toList();
        },
      );
    }

    // Animal mode: filter by category, then by animal name
    final result = filterUseCase.execute(
      category: widget.category == 'All' ? 'All' : (widget.category ?? 'All'),
      searchQuery: '',
    );

    return result.fold(
      (failure) {
        AppLogger.d('Calls filter error: ${failure.message}');
        return <ReferenceCall>[];
      },
      (calls) {
        if (widget.animalName != null) {
          return calls
              .where((c) => c.animalName == widget.animalName)
              .toList();
        }
        return calls;
      },
    );
  }

  String get _screenTitle {
    if (widget.title != null) return widget.title!;
    return widget.animalName ?? 'Calls';
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    final currentlyPlayingId = audioService.currentlyPlayingId;
    final profileState = ref.watch(profileNotifierProvider);
    final isPremium = profileState.profile?.isPremium ?? false;
    final palette = AppColors.of(context);

    final calls = _getCalls();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _screenTitle.toUpperCase(),
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: palette.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWrapper(
        child: SafeArea(
          top: false,
          child: calls.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.filterMode == CallFilterMode.favorites
                            ? Icons.favorite_border_rounded
                            : Icons.music_off_rounded,
                        size: 48,
                        color: palette.textSubtle,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.filterMode == CallFilterMode.favorites
                            ? 'No favorites yet'
                            : 'No calls found',
                        style: TextStyle(color: palette.textTertiary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  itemCount: calls.length,
                  itemBuilder: (context, index) {
                    final call = calls[index];
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
                ),
        ),
      ),
    );
  }

  Widget _buildCallCard(ReferenceCall call, bool isPlaying, bool isLocked) {
    final palette = AppColors.of(context);
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.black.withValues(alpha: 0.2)
                      : isPlaying
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.2)
                          : palette.cardOverlay,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLocked
                        ? palette.cardOverlay
                        : isPlaying
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.5)
                            : palette.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildPlayButton(call, isPlaying, isLocked),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Show animal name in favorites mode
                              if (widget.filterMode ==
                                  CallFilterMode.favorites) ...[
                                Text(
                                  call.animalName,
                                  style: GoogleFonts.oswald(
                                    color: palette.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                              Text(
                                call.callType,
                                style: GoogleFonts.oswald(
                                  color: palette.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildDifficultyBadge(call.difficulty),
                        const SizedBox(width: 8),
                        _buildFavoriteButton(call),
                      ],
                    ),
                    if (call.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        call.description,
                        style: TextStyle(
                            color: palette.textTertiary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMetricChip(
                            Icons.music_note, '${call.idealPitchHz.toInt()} Hz'),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                            Icons.timer_outlined, '${call.idealDurationSec}s'),
                        const SizedBox(width: 8),
                        const Spacer(),
                        if (call.proTips.isNotEmpty)
                          Icon(Icons.info_outline,
                              size: 16, color: palette.textSubtle),
                      ],
                    ),
                  ],
                ),
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
              style:
                  TextStyle(color: palette.textSecondary, fontSize: 11)),
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
          color: isFavorite
              ? Colors.redAccent
              : AppColors.of(context).textTertiary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPlayButton(
      ReferenceCall call, bool isPlaying, bool isLocked) {
    final palette = AppColors.of(context);
    return Semantics(
      button: true,
      label: isPlaying ? 'Stop playback' : 'Play ${call.callType} audio',
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
