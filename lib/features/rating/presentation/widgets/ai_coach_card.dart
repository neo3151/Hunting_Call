import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/services/remote_config/remote_config_service.dart';
import 'package:outcall/features/library/domain/providers.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/rating/data/ai_coach_service.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

/// "Coach's Corner" — AI-powered coaching card shown after rating.
/// Calls Gemma 3 4B via Cloud Function to generate personalized feedback.
/// Gated behind isPremium.
class AiCoachCard extends ConsumerStatefulWidget {
  final RatingResult result;
  final String animalId;
  final String audioPath;

  const AiCoachCard({
    super.key,
    required this.result,
    required this.animalId,
    required this.audioPath,
  });

  @override
  ConsumerState<AiCoachCard> createState() => _AiCoachCardState();
}

class _AiCoachCardState extends ConsumerState<AiCoachCard> with SingleTickerProviderStateMixin {
  String? _coaching;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fetchCoaching();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCoaching() async {
    final getCallUseCase = ref.read(getCallByIdUseCaseProvider);
    final callResult = getCallUseCase.execute(widget.animalId);

    String animalName = 'Unknown Animal';
    String callType = 'Call';
    double idealPitchHz = 0;
    String proTips = '';

    callResult.fold(
      (failure) {},
      (reference) {
        animalName = reference.animalName;
        callType = reference.callType;
        idealPitchHz = reference.idealPitchHz;
        proTips = reference.proTips;
      },
    );

    try {
      final profile = ref.read(profileNotifierProvider).profile;
      final remoteConfig = ref.read(remoteConfigServiceProvider);
      final coaching = await AiCoachService.getCoaching(
        animalName: animalName,
        callType: callType,
        result: widget.result,
        idealPitchHz: idealPitchHz,
        proTips: proTips,
        userId: profile?.id,
        baseUrl: remoteConfig.aiCoachUrl,
        audioPath: widget.audioPath,
      );

      if (mounted) {
        setState(() {
          _coaching = coaching;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show for premium users
    final profile = ref.watch(profileNotifierProvider).profile;
    if (profile == null || !profile.isPremium) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFF0D060)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology, color: Colors.black87, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'AI COACH',
                      style: GoogleFonts.oswald(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'GEMMA 3',
                style: GoogleFonts.lato(
                  fontSize: 9,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            "COACH'S CORNER",
            style: GoogleFonts.oswald(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4AF37),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),

          // Content
          if (_isLoading)
            _buildLoadingState()
          else if (_hasError)
            Text(
              'Coach is currently unavailable. Try again after your next call.',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.white54,
                height: 1.5,
              ),
            )
          else
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _coaching ?? '',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Analyzing your technique...',
              style: GoogleFonts.lato(
                fontSize: 13,
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Skeleton lines
        ...List.generate(
            3,
            (i) => Padding(
                  padding: EdgeInsets.only(bottom: 8, right: i == 2 ? 80 : 0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                )),
      ],
    );
  }
}
