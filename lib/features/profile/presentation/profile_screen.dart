import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../library/data/mock_reference_database.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text("Handler Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(child: Text("Profile not found."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                       // Header Card
                       Card(
                         elevation: 4,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         child: Padding(
                           padding: const EdgeInsets.all(24),
                           child: Column(
                             children: [
                               const CircleAvatar(
                                 radius: 40,
                                 backgroundColor: Colors.green,
                                 child: Icon(Icons.person, size: 40, color: Colors.white),
                               ),
                               const SizedBox(height: 16),
                               Text(
                                 profile.name,
                                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                               ),
                               Text(
                                 "Member since ${DateFormat.yMMMd().format(profile.joinedDate)}",
                                 style: const TextStyle(color: Colors.grey),
                               ),
                             ],
                           ),
                         ),
                       ),
                       const SizedBox(height: 24),
                       
                       // Stats Row
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                         children: [
                           _buildStatCard(context, "Calls", profile.totalCalls.toString()),
                           _buildStatCard(context, "Avg Score", "${profile.averageScore.toStringAsFixed(1)}%"),
                         ],
                       ),
                       const SizedBox(height: 24),
                       
                       // History List
                       Align(
                         alignment: Alignment.centerLeft,
                         child: Text("Recent Activity", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                       ),
                       const SizedBox(height: 8),
                       if (profile.history.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text("No calls recorded yet. Go hunt!"),
                          )
                       else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: profile.history.length,
                            itemBuilder: (context, index) {
                              final item = profile.history[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getScoreColor(item.result.score).withValues(alpha: 0.2),
                                    child: Text(item.result.score.toStringAsFixed(0), style: TextStyle(color: _getScoreColor(item.result.score), fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(MockReferenceDatabase.getById(item.animalId).animalName),
                                  subtitle: Text(DateFormat.yMMMd().add_jm().format(item.timestamp)),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
