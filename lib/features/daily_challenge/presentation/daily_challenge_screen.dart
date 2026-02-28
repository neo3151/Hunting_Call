import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:outcall/features/daily_challenge/presentation/controllers/daily_challenge_controller.dart';
import 'package:outcall/features/recording/presentation/recorder_page.dart';
import 'package:outcall/features/daily_challenge/presentation/widgets/challenge_card.dart';
import 'package:outcall/features/daily_challenge/presentation/widgets/leaderboard_preview.dart';
import 'package:outcall/core/utils/animal_image_alignment.dart';

class DailyChallengeScreen extends ConsumerWidget {
  final String userId;
  const DailyChallengeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsyncValue = ref.watch(dailyChallengeProvider);

    return challengeAsyncValue.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      ),
      error: (err, stack) => _buildErrorScaffold(context),
      data: (challengeCall) {
        // Handle null challenge (error case returning from UseCase)
        if (challengeCall == null) {
          return _buildErrorScaffold(context);
        }

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'DAILY CHALLENGE',
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Semantics(
                  label: 'Daily Challenge target: ${challengeCall.animalName}',
                  image: true,
                  child: Image.asset(
                    challengeCall.imageUrl,
                    fit: BoxFit.cover,
                    alignment: AnimalImageAlignment.forImage(challengeCall.imageUrl),
                    color: Colors.black87,
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      ChallengeCard(
                        challengeCall: challengeCall,
                        onStart: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecorderPage(
                                userId: userId,
                                preselectedAnimalId: challengeCall.id,
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      const LeaderboardPreview(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'DAILY CHALLENGE',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              "Unable to load today's challenge",
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GO BACK'),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildHeader() {
    final dateStr =
        DateFormat('MMMM d, yyyy').format(DateTime.now()).toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateStr,
          style: GoogleFonts.lato(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CALL OF THE DAY',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
