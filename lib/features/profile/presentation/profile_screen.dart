import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await sl<ProfileRepository>().getProfile(widget.userId);
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Handler Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                             _profile!.name,
                             style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                           ),
                           Text(
                             "Member since ${DateFormat.yMMMd().format(_profile!.joinedDate)}",
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
                       _buildStatCard(context, "Calls", _profile!.totalCalls.toString()),
                       _buildStatCard(context, "Avg Score", "${_profile!.averageScore.toStringAsFixed(1)}%"),
                     ],
                   ),
                   const SizedBox(height: 24),
                   
                   // History List
                   Align(
                     alignment: Alignment.centerLeft,
                     child: Text("Recent Activity", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(height: 8),
                   if (_profile!.history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("No calls recorded yet. Go hunt!"),
                      )
                   else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _profile!.history.length,
                        itemBuilder: (context, index) {
                          final item = _profile!.history[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getScoreColor(item.result.score).withValues(alpha: 0.2),
                                child: Text(item.result.score.toStringAsFixed(0), style: TextStyle(color: _getScoreColor(item.result.score), fontWeight: FontWeight.bold)),
                              ),
                              title: Text(item.animalId.toUpperCase()), // We should map ID to Name later
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
