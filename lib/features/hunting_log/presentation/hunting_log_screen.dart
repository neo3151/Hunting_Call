import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/hunting_log_provider.dart';
import 'add_log_screen.dart';

class HuntingLogScreen extends ConsumerWidget {
  const HuntingLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(huntingLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hunting Log'),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No logs yet. Go hunt!'));
          }
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Dismissible(
                key: Key(log.id),
                background: Container(color: Colors.red),
                onDismissed: (_) {
                  ref.read(huntingLogProvider.notifier).deleteLog(log.id);
                },
                child: ListTile(
                  leading: const Icon(Icons.history_edu),
                  title: Text(
                    log.animalId ?? 'Observation',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.yMMMd().add_jm().format(log.timestamp)),
                      if (log.notes.isNotEmpty)
                        Text(
                          log.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: log.latitude != null ? const Icon(Icons.location_on, size: 16) : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddLogScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
