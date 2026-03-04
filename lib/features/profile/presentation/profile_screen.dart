import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:outcall/config/app_config.dart';
import 'package:outcall/core/services/referral_service.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/core/widgets/offline_banner.dart';
import 'package:outcall/core/widgets/upgrade_prompter.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/payment/presentation/paywall_screen.dart';
import 'package:outcall/features/profile/domain/achievement_service.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/progress_map/presentation/progress_map_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).loadProfile(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.profile;
    final isLoading = profileState.isLoading;

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('HANDLER PROFILE',
              style: GoogleFonts.oswald(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.of(context).textPrimary))
                  : profile == null
                      ? Center(
                          child: Text('Profile not found.',
                              style: TextStyle(color: AppColors.of(context).textSecondary)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Header Section
                              _buildProfileHeader(profile),
                              const SizedBox(height: 32),

                              // Upgrade to Pro Banner (Non-Premium Users Only)
                              if (!profile.isPremium) ...[
                                _buildUpgradeBanner(context),
                                const SizedBox(height: 24),
                              ],

                              // Manage Subscription (Premium Users Only)
                              if (profile.isPremium) ...[
                                _buildManageSubscriptionCard(context),
                                const SizedBox(height: 24),
                              ],

                              // Stats Row
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildGlassStatCard(
                                          'TOTAL CALLS', profile.totalCalls.toString(), Icons.mic)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildGlassStatCard(
                                          'AVG ACCURACY',
                                          '${profile.averageScore.toStringAsFixed(1)}%',
                                          Icons.analytics)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildGlassStatCard(
                                          'DAILY STREAK',
                                          '${profile.currentStreak} 🔥',
                                          Icons.local_fire_department)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Invite Friends Card
                              _buildInviteFriendsCard(profile),
                              const SizedBox(height: 16),

                              // Map Button
                              if (AppConfig.instance.allowMap || (profile.isPremium))
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ProgressMapScreen(userId: widget.userId)),
                                      );
                                    },
                                    icon: Icon(Icons.map_outlined,
                                        color: AppColors.of(context).textSecondary),
                                    label: const Text('VIEW FIELD MAP'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: AppColors.of(context).border),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        UpgradePrompter.show(context, featureName: 'Field Map'),
                                    icon: Icon(Icons.lock_outline,
                                        color: AppColors.of(context).textSubtle),
                                    label: const Text('FIELD MAP (LOCKED)'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white38,
                                      side: BorderSide(color: AppColors.of(context).border),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 32),

                              // Achievements Section
                              if (profile.achievements.isNotEmpty) ...[
                                _buildSectionHeader('HONORS & BADGES'),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: profile.achievements.length,
                                    itemBuilder: (context, index) {
                                      final achievementId = profile.achievements[index];
                                      final achievement =
                                          AchievementService.achievements.firstWhere(
                                        (a) => a.id == achievementId,
                                        orElse: () => Achievement(
                                          id: 'unknown',
                                          name: 'Unknown',
                                          description: '',
                                          icon: '❓',
                                          isEarned: (_) => false,
                                        ),
                                      );
                                      return _buildAchievementBadge(achievement);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],

                              // History Section
                              _buildSectionHeader('RECENT ACTIVITY'),
                              const SizedBox(height: 16),
                              if (profile.history.isEmpty)
                                _buildEmptyHistory()
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: profile.history.length,
                                  itemBuilder: (context, index) {
                                    final item = profile.history[index];
                                    return _buildHistoryCard(item);
                                  },
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.of(context).border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profile.avatarUrl!),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.of(context).surface,
                      child:
                          Icon(Icons.person, size: 50, color: AppColors.of(context).textSecondary),
                    ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.edit, size: 20, color: AppColors.of(context).textPrimary),
                onPressed: () => _showEditProfileDialog(context, profile),
                tooltip: 'Edit Profile',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          (profile.nickname?.isNotEmpty == true ? profile.nickname! : profile.name).toUpperCase(),
          style: GoogleFonts.oswald(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
              letterSpacing: 1.0),
        ),
        if (profile.nickname?.isNotEmpty == true && profile.name != profile.nickname)
          Text(
            '(${profile.name})',
            style: GoogleFonts.lato(color: AppColors.of(context).textSubtle, fontSize: 12),
          ),
        const SizedBox(height: 4),
        Text(
          'HANDLING SINCE ${DateFormat.yMMMd().format(profile.joinedDate).toUpperCase()}',
          style: GoogleFonts.lato(
              color: AppColors.of(context).textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
        if (profile.isAlphaTester) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Theme.of(context).primaryColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ALPHA TESTER',
                  style: GoogleFonts.lato(
                      color: Theme.of(context).primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    final nicknameController = TextEditingController(text: profile.nickname);
    final avatarUrlController = TextEditingController(text: profile.avatarUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.of(context).surface,
          title: Text(
            'EDIT PROFILE',
            style: GoogleFonts.oswald(
              color: AppColors.of(context).textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nicknameController,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nickname',
                    labelStyle: TextStyle(color: AppColors.of(context).textTertiary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.of(context).border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: avatarUrlController,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Avatar Image URL',
                    labelStyle: TextStyle(color: AppColors.of(context).textTertiary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.of(context).border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Note: Nicknames are revokable by moderators if they contain improper words.',
                  style: GoogleFonts.lato(color: Colors.redAccent, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: AppColors.of(context).textTertiary)),
            ),
            ElevatedButton(
              onPressed: () {
                final newNickname = nicknameController.text.trim();
                final newAvatarUrl = avatarUrlController.text.trim();
                ref.read(profileNotifierProvider.notifier).updateProfile(
                      nickname: newNickname.isEmpty ? null : newNickname,
                      avatarUrl: newAvatarUrl.isEmpty ? null : newAvatarUrl,
                    );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: AppColors.of(context).background,
              ),
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildGlassStatCard(String label, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.of(context).cardOverlay,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.of(context).textTertiary, size: 20),
              const SizedBox(height: 12),
              Text(value,
                  style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.of(context).textPrimary)),
              Text(label,
                  style: GoogleFonts.lato(
                      fontSize: 10,
                      color: AppColors.of(context).textSubtle,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.of(context).cardOverlay,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(achievement.icon, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: GoogleFonts.lato(
                fontSize: 10,
                color: AppColors.of(context).textSecondary,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final call = ReferenceDatabase.getById(item.animalId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.of(context).cardOverlay,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _getScoreColor(item.result.score).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.result.score.toStringAsFixed(0),
                    style: TextStyle(
                        color: _getScoreColor(item.result.score),
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(call.animalName.toUpperCase(),
                          style: GoogleFonts.oswald(
                              color: AppColors.of(context).textPrimary,
                              fontWeight: FontWeight.bold)),
                      Text(DateFormat.yMMMd().add_jm().format(item.timestamp).toUpperCase(),
                          style: GoogleFonts.lato(
                              color: AppColors.of(context).textSubtle,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.of(context).divider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteFriendsCard(UserProfile profile) {
    final referralCode = profile.referralCode ?? ReferralService.generateCode(profile.id);
    final referralCount = profile.referralCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentGold.withValues(alpha: 0.1),
                AppColors.accentGold.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline, color: AppColors.accentGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'INVITE FRIENDS',
                    style: GoogleFonts.oswald(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (referralCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '$referralCount referred',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Referral Code Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.of(context).border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        referralCode,
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, size: 18, color: AppColors.of(context).textTertiary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Code copied!', style: GoogleFonts.lato()),
                            backgroundColor: AppColors.accentGold,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Copy code',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Share Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final msg = ReferralService.shareMessage(referralCode);
                    await SharePlus.instance.share(ShareParams(text: msg));
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(
                    'SHARE INVITE',
                    style: GoogleFonts.oswald(
                        fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardOverlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Column(
        children: [
          Icon(Icons.mic_none, color: AppColors.of(context).divider, size: 48),
          const SizedBox(height: 16),
          Text('NO HUNTS RECORDED YET',
              style: GoogleFonts.oswald(
                  color: AppColors.of(context).border, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUpgradeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.accentGoldDark,
            AppColors.accentGold,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPGRADE TO PRO',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Unlock all calls & features',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => PaywallScreen.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accentGoldDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: Text(
              'VIEW',
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageSubscriptionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardOverlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGoldDark, AppColors.accentGold],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'OUTCALL PRO',
                      style: GoogleFonts.oswald(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: GoogleFonts.lato(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.greenAccent,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'All features unlocked',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.of(context).textTertiary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              // Deep-link to Google Play subscription management
              const url =
                  'https://play.google.com/store/account/subscriptions?sku=outcall_premium_yearly&package=com.huntingcall.app';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.of(context).textSecondary,
              side: BorderSide(color: AppColors.of(context).border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'MANAGE',
              style: GoogleFonts.oswald(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 60) return Theme.of(context).primaryColor;
    return Colors.redAccent;
  }
}
