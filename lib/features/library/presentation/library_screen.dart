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

class LibraryScreen extends ConsumerStatefulWidget {
  final String? userId;
  const LibraryScreen({super.key, this.userId});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';
  final List<String> _categories = [
    'All',
    'Waterfowl',
    'Big Game',
    'Predators',
    'Land Birds'
  ];
  AudioService? _audioService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioService = ref.read(audioServiceProvider);
  }

  @override
  void dispose() {
    _audioService?.stop();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _audioService?.stop();
    return true;
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
      category: category,
      searchQuery: _searchQuery,
    );

    return result.fold(
      (failure) {
        // Log the error but return empty list to avoid breaking UI
        AppLogger.d('Library filter error: ${failure.message}');
        return <ReferenceCall>[];
      },
      (calls) => calls,
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
            title: Text('CALL LIBRARY',
                style: GoogleFonts.oswald(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Search calls...',
                        hintStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white54
                                    : Colors.black54),
                        prefixIcon: Icon(Icons.search,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white54
                                    : Colors.black54),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
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
                    unselectedLabelColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black54,
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
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  if (filtered.isEmpty) {
                    return Center(
                        child: Text('No calls found',
                            style: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54)));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                    ? (isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1))
                    : isPlaying
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLocked
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05))
                      : isPlaying
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.5)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              call.callType,
                              style: TextStyle(
                                color: isLocked
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black54),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Difficulty Badge
                      _buildDifficultyBadge(call.difficulty),
                    ],
                  ),
                  if (call.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      call.description,
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
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
                      // Learn More Indicator
                      if (call.proTips.isNotEmpty)
                        Icon(Icons.info_outline,
                            size: 16,
                            color: isDark ? Colors.white30 : Colors.black26),
                    ],
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
        color = Colors.white54;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPlayButton(ReferenceCall call, bool isPlaying, bool isLocked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _togglePlayback(call),
      child: Icon(
        isLocked
            ? Icons.lock_outline
            : isPlaying
                ? Icons.stop_circle_rounded
                : Icons.play_circle_filled_rounded,
        color: isLocked
            ? (isDark ? Colors.white24 : Colors.black26)
            : isPlaying
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.white70 : Colors.black54),
        size: 40,
      ),
    );
  }
}
