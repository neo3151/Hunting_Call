import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';

/// Displays the most recent hunt result on the home screen.
class RecentActivityCard extends StatelessWidget {
  final HistoryItem historyItem;

  const RecentActivityCard({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.of(context).border : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.of(context).border : Colors.black.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  historyItem.result.score.toStringAsFixed(0),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(historyItem.animalId.toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Text('Last Session',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
