import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0; // 0 for General Feedback, 1 for Bug Reports

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ADMIN PORTAL', style: GoogleFonts.oswald(letterSpacing: 1.5)),
        backgroundColor: Colors.black,
      ),
      body: BackgroundWrapper(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('General Feedback')),
                  ButtonSegment(value: 1, label: Text('Bug Reports')),
                ],
                selected: {_currentIndex},
                onSelectionChanged: (set) => setState(() => _currentIndex = set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return AppColors.success.withValues(alpha: 0.3);
                    return Colors.black54;
                  }),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
              ),
            ),
            Expanded(
              child: _currentIndex == 0 ? _buildGeneralFeedback() : _buildBugReports(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralFeedback() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('general_feedback')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text('No feedback yet.', style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildTicketCard(docs[index].id, data, 'general_feedback');
          },
        );
      },
    );
  }

  Widget _buildBugReports() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bug_reports')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text('No bug reports yet.', style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildTicketCard(docs[index].id, data, 'bug_reports');
          },
        );
      },
    );
  }

  Widget _buildTicketCard(String id, Map<String, dynamic> data, String collection) {
    final status = data['status'] ?? 'open';
    final isClosed = status == 'closed';
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null ? timestamp.toDate().toString().split('.')[0] : 'Unknown date';

    return Card(
      color: isClosed ? Colors.black45 : Colors.black87,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isClosed ? Colors.white12 : AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['category'] ?? data['reason'] ?? 'Unknown',
                    style: GoogleFonts.oswald(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClosed ? Colors.grey.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: isClosed ? Colors.grey : AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('User ID: ${data['userId']}', style: TextStyle(color: Colors.white54, fontSize: 11)),
            Text('Date: $dateStr', style: TextStyle(color: Colors.white54, fontSize: 11)),
            if (data['animalName'] != null) Text('Animal: ${data['animalName']}', style: TextStyle(color: Colors.white54, fontSize: 11)),
            if (data['score'] != null) Text('Score: ${data['score']}', style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 12),
            Text(
              data['details'] ?? data['additionalDetails'] ?? 'No details provided.',
              style: GoogleFonts.lato(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  FirebaseFirestore.instance.collection(collection).doc(id).update({
                    'status': isClosed ? 'open' : 'closed',
                  });
                },
                icon: Icon(isClosed ? Icons.restore : Icons.check_circle, size: 16, color: isClosed ? Colors.blueAccent : AppColors.success),
                label: Text(isClosed ? 'Reopen Ticket' : 'Mark as Resolved', style: TextStyle(color: isClosed ? Colors.blueAccent : AppColors.success)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
