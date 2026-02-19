import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/recording/presentation/recorder_page.dart';
import '../../features/progress_map/presentation/progress_map_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

/// Persistent bottom navigation shell that wraps all main screens.
/// Matches the Play Store screenshot design with dark green + orange brand colors.
class MainShell extends StatefulWidget {
  final String userId;
  const MainShell({super.key, required this.userId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(userId: widget.userId),
      LibraryScreen(userId: widget.userId),
      RecorderPage(userId: widget.userId),
      ProgressMapScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFFF8C00), // Orange
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: GoogleFonts.oswald(
            fontSize: 11,
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
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_none),
              activeIcon: Icon(Icons.mic),
              label: 'Practice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
