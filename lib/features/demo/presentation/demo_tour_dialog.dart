import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/demo/demo_mode_controller.dart';

class DemoTourDialog extends ConsumerStatefulWidget {
  const DemoTourDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DemoTourDialog(),
    );
  }

  @override
  ConsumerState<DemoTourDialog> createState() => _DemoTourDialogState();
}

class _DemoTourDialogState extends ConsumerState<DemoTourDialog> {
  int _page = 0;

  static const _steps = [
    (
      icon: Icons.explore_rounded,
      title: 'Welcome to Demo Mode',
      body: 'This is a guided preview of OUTCALL. Your profile, scores, and progress are local demo data.',
    ),
    (
      icon: Icons.graphic_eq_rounded,
      title: 'Try a Sample Call',
      body: 'Open the gold sample-call card on Home to simulate recording, analysis, scoring, and Coach Buck feedback.',
    ),
    (
      icon: Icons.workspace_premium_rounded,
      title: 'Explore Premium',
      body: 'The Profile tab shows premium features. Public previews stay limited; invited prospects can unlock the full simulated premium experience.',
    ),
    (
      icon: Icons.insights_rounded,
      title: 'Track Your Progress',
      body: 'Your sample calls are saved to history and add XP, so the rest of the app feels like an active hunter profile.',
    ),
  ];

  void _finish() {
    ref.read(demoModeProvider.notifier).completeTour();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final step = _steps[_page];
    final isLast = _page == _steps.length - 1;

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('SKIP', style: TextStyle(color: colors.textTertiary, letterSpacing: 1)),
              ),
            ),
            Icon(step.icon, size: 68, color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.oswald(fontSize: 26, color: colors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              step.body,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _page ? Theme.of(context).primaryColor : colors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLast ? _finish : () => setState(() => _page++),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isLast ? 'START EXPLORING' : 'NEXT', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
