import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalErrorView extends StatelessWidget {
  final FlutterErrorDetails details;
  
  const GlobalErrorView({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                "Network's drunk—try again?",
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong on our end. Give it another shot.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: const Color(0xFF121212),
                  ),
                  onPressed: () {
                    // This pops the current "broken" route if possible,
                    // otherwise it will just rebuild when the user restarts the app.
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'TRY AGAIN',
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
