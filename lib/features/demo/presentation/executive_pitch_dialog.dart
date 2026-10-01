import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:outcall/core/theme/app_colors.dart';

import 'package:outcall/features/demo/demo_invite_service.dart';
import 'package:outcall/features/demo/demo_mode_controller.dart';

enum QrTargetMode { localWifi, productionSsl }

class ExecutivePitchDialog extends ConsumerStatefulWidget {
  const ExecutivePitchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExecutivePitchDialog(),
    );
  }

  @override
  ConsumerState<ExecutivePitchDialog> createState() => _ExecutivePitchDialogState();
}

class _ExecutivePitchDialogState extends ConsumerState<ExecutivePitchDialog> {
  bool _isGeneratingToken = false;
  Map<String, dynamic>? _issuedTokenData;
  final String _prospectLabel = 'Outfitter Executive Demo';
  final int _ttlHours = 168; // 7 days
  QrTargetMode _targetMode = QrTargetMode.productionSsl;

  @override
  void initState() {
    super.initState();
    _generateToken();
  }

  Future<void> _generateToken() async {
    setState(() => _isGeneratingToken = true);
    final result = await DemoInviteService.createProspectInvite(
      ttlHours: _ttlHours,
      maxUses: 5,
      label: _prospectLabel,
    );
    if (mounted) {
      setState(() {
        _issuedTokenData = result;
        _isGeneratingToken = false;
      });
    }
  }

  String get _inviteUrl {
    final token = _issuedTokenData?['token'] ?? '';
    if (token.isEmpty) return '';

    if (_targetMode == QrTargetMode.localWifi) {
      // Local Wi-Fi network IP accessible by phones on the same Wi-Fi
      return 'http://192.168.1.192:8080/?invite=$token';
    }

    const publicUrl = String.fromEnvironment(
      'OUTCALL_PUBLIC_URL',
      defaultValue: 'https://outcallbackend.xyz/demo',
    );
    return '$publicUrl/?invite=$token';
  }



  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final demoState = ref.watch(demoModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.4), width: 1.5),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.present_to_all_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXECUTIVE PITCH HUB',
                        style: GoogleFonts.oswald(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Live meeting presentation & prospect pass generator',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Presenter mode status banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: demoState.isPresenterMode
                    ? AppColors.accentGold.withOpacity(0.12)
                    : colors.cardOverlay,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: demoState.isPresenterMode
                      ? AppColors.accentGold.withOpacity(0.4)
                      : colors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    demoState.isPresenterMode ? Icons.verified_user : Icons.slideshow_outlined,
                    color: demoState.isPresenterMode ? AppColors.accentGold : colors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          demoState.isPresenterMode ? 'Presenter Mode Active' : 'Standard Demo Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          demoState.isPresenterMode
                              ? 'All features & 7-agent AI swarm breakdown unlocked for live presentation.'
                              : 'Enable presenter mode to showcase full AI capabilities to clients.',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: demoState.isPresenterMode,
                    activeColor: AppColors.accentGold,
                    onChanged: (val) {
                      ref.read(demoModeProvider.notifier).togglePresenterMode();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Live QR / Token Generator section
            Text(
              'PROSPECT VIP PASS GENERATOR',
              style: GoogleFonts.oswald(
                fontSize: 14,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.cardOverlay,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  // Target Mode Selector (Local Wi-Fi IP vs Production SSL)
                  SegmentedButton<QrTargetMode>(
                    segments: const [
                      ButtonSegment(
                        value: QrTargetMode.localWifi,
                        icon: Icon(Icons.wifi_rounded, size: 16),
                        label: Text('Local Wi-Fi IP', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: QrTargetMode.productionSsl,
                        icon: Icon(Icons.language_rounded, size: 16),
                        label: Text('Production SSL', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {_targetMode},
                    onSelectionChanged: (newSelection) {
                      setState(() => _targetMode = newSelection.first);
                    },
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isGeneratingToken)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )
                  else ...[

                    // Camera-Scannable Standard ISO/IEC QR Code with Quiet Zone Padding
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _inviteUrl.isNotEmpty ? _inviteUrl : 'https://outcall.app/?invite=demo_vip_pass',
                        version: QrVersions.auto,
                        size: 180.0,
                        backgroundColor: Colors.white,
                        gapless: true,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),


                    const SizedBox(height: 14),
                    Text(
                      'Scan to activate 7-day VIP Prospect Pass',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.oswald(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _inviteUrl,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.tealAccent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy Link',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _inviteUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Prospect invite URL copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _generateToken,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('GENERATE NEW CODE'),
                      ),
                      Chip(
                        label: const Text('5 Max Uses  •  7 Days'),
                        backgroundColor: colors.surface,
                        labelStyle: TextStyle(fontSize: 10, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7-Agent AI Swarm Pitch Highlights
            Text(
              '7-AGENT AI SWARM PITCH HIGHLIGHTS',
              style: GoogleFonts.oswald(
                fontSize: 14,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _buildAgentChip(context, 'DSP Agent', 'Pitch, spectral centroid & harmonics', Icons.equalizer),
            _buildAgentChip(context, 'WindTalker Agent', 'Filters field wind noise', Icons.air),
            _buildAgentChip(context, 'ImpulseSniffer Agent', 'Rejects non-call impulse sounds', Icons.surround_sound),
            _buildAgentChip(context, 'Fingerprint Agent', 'Matches 60+ bioacoustic signatures', Icons.fingerprint),
            _buildAgentChip(context, 'SpeechGuardian Agent', 'Rejects human voice submission', Icons.record_voice_over),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentChip(BuildContext context, String name, String desc, IconData icon) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

