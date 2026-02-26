import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/core/utils/animal_image_alignment.dart';

/// Banner card showing today's daily challenge on the home screen.
class DailyChallengeCard extends StatelessWidget {
  final ReferenceCall challengeCall;
  final VoidCallback onTap;

  const DailyChallengeCard({
    super.key,
    required this.challengeCall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Semantics(
              label: 'Image of ${challengeCall.animalName}',
              image: true,
              child: Image.asset(
                challengeCall.imageUrl,
                fit: BoxFit.cover,
                alignment: AnimalImageAlignment.forImage(challengeCall.imageUrl),
              ),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('DAILY CHALLENGE',
                                style: GoogleFonts.oswald(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'MASTER THE\n${challengeCall.animalName.toUpperCase()}',
                            style: GoogleFonts.oswald(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.bolt,
                                  color: Colors.yellowAccent, size: 16),
                              const SizedBox(width: 4),
                              Text('+500 XP Bonus',
                                  style: GoogleFonts.lato(
                                      color: Colors.yellowAccent,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
