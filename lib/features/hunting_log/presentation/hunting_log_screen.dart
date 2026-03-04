import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/hunting_log/domain/hunting_log_entry.dart';
import 'package:outcall/features/hunting_log/presentation/controllers/hunting_log_controller.dart';
import 'package:outcall/features/hunting_log/presentation/add_log_screen.dart';

class HuntingLogScreen extends ConsumerWidget {
  const HuntingLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(huntingLogProvider);
    final colors = AppColors.of(context);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: BackgroundWrapper(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HUNTING LOG',
                      style: GoogleFonts.oswald(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: logsAsync.when(
                        data: (logs) => Text(
                          '${logs.length} ENTRIES',
                          style: GoogleFonts.oswald(color: primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: logsAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: primary)),
                  error: (err, _) => Center(
                    child: Text('Error: $err', style: TextStyle(color: colors.textSecondary)),
                  ),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return _buildEmptyState(context, colors, primary);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) => _buildLogCard(
                        context, ref, logs[index], colors, primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddLogScreen()),
        ),
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColorPalette colors, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_edu, color: primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No Logs Yet',
            style: GoogleFonts.oswald(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to record your first hunt.',
            style: GoogleFonts.lato(color: colors.textSubtle, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(
    BuildContext context,
    WidgetRef ref,
    HuntingLogEntry log,
    AppColorPalette colors,
    Color primary,
  ) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, colors),
      onDismissed: (_) => ref.read(huntingLogProvider.notifier).deleteLog(log.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.cardOverlay,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history_edu, color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.animalId ?? 'Observation',
                      style: GoogleFonts.oswald(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(log.timestamp),
                      style: GoogleFonts.lato(color: colors.textSubtle, fontSize: 12),
                    ),
                    if (log.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        log.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(color: colors.textTertiary, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              // Location indicator
              if (log.latitude != null)
                Icon(Icons.location_on, color: primary.withValues(alpha: 0.6), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, AppColorPalette colors) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Delete Entry?', style: GoogleFonts.oswald(color: colors.textPrimary)),
        content: Text(
          'This log entry will be permanently deleted.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: TextStyle(color: colors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
