import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_notifier.dart';

class ThemeSwitchFloatingButton extends StatelessWidget {
  const ThemeSwitchFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, child) {
        return FloatingActionButton.small(
          onPressed: () => theme.toggleTheme(),
          backgroundColor: theme.isDarkMode ? Colors.grey.shade800 : Colors.white,
          child: Icon(
            theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: theme.isDarkMode ? Colors.yellow : Colors.orange,
          ),
        );
      },
    );
  }
}
