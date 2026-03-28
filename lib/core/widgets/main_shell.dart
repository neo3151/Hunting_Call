import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/services/audio_service.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/home/presentation/home_screen.dart';
import 'package:outcall/features/library/presentation/category_grid_screen.dart';
import 'package:outcall/features/profile/presentation/profile_screen.dart';
import 'package:outcall/features/progress_map/presentation/progress_map_screen.dart';
import 'package:outcall/features/recording/presentation/controllers/recording_controller.dart';
import 'package:outcall/features/recording/presentation/recorder_page.dart';

/// Persistent bottom navigation shell that wraps all main screens.
/// Matches the Play Store screenshot design with dark green + orange brand colors.
class MainShell extends ConsumerStatefulWidget {
  final String userId;
  const MainShell({super.key, required this.userId});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      HomeScreen(
        userId: widget.userId,
        onNavigateTab: _onBottomNavTapped,
      ),
      CategoryGridScreen(userId: widget.userId),
      RecorderPage(userId: widget.userId),
      ProgressMapScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Stop any playing audio when switching tabs
    ref.read(audioServiceProvider.notifier).stop();
    // Kill any active recording session
    final recState = ref.read(recordingNotifierProvider);
    if (recState.isRecording || recState.isCountingDown) {
      ref.read(recordingNotifierProvider.notifier).reset();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTapped(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = AppColors.isDark(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onBottomNavTapped(0);
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? AppColors.surface : Colors.white,
              title: Text('Exit App?', style: GoogleFonts.oswald(color: colors.textPrimary)),
              content: Text('Are you sure you want to leave the Hunt?',
                  style: GoogleFonts.lato(color: colors.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('CANCEL', style: TextStyle(color: colors.textTertiary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('EXIT', style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        endDrawer: Drawer(
          backgroundColor: colors.surface,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'MENU',
                    style: GoogleFonts.oswald(
                      color: colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(color: colors.divider),
                ListTile(
                  leading: Icon(Icons.settings, color: colors.icon),
                  title: Text('Settings', style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _onBottomNavTapped(4); // Profile tab usually has settings
                  },
                ),
              ],
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.background : Colors.white,
            border: Border(
              top: BorderSide(
                color: colors.border,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIconTheme: IconThemeData(color: Theme.of(context).primaryColor),
            unselectedIconTheme: IconThemeData(color: colors.textTertiary),
            selectedItemColor: colors.textPrimary,
            unselectedItemColor: colors.textTertiary,
            selectedLabelStyle: GoogleFonts.oswald(
              fontSize: 11,
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: GoogleFonts.oswald(
              fontSize: 10,
              letterSpacing: 0.5,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
                tooltip: 'Home Screen',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Library',
                tooltip: 'Audio Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mic_none),
                activeIcon: Icon(Icons.mic),
                label: 'Practice',
                tooltip: 'Recording Practice',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Progress',
                tooltip: 'Training Progress',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
                tooltip: 'User Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
