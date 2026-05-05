import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';

class GeneralFeedbackBottomSheet extends StatefulWidget {
  final String userId;

  const GeneralFeedbackBottomSheet({
    super.key,
    required this.userId,
  });

  static void show(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: GeneralFeedbackBottomSheet(userId: userId),
        );
      },
    );
  }

  @override
  State<GeneralFeedbackBottomSheet> createState() => _GeneralFeedbackBottomSheetState();
}

class _GeneralFeedbackBottomSheetState extends State<GeneralFeedbackBottomSheet> {
  String? _selectedCategory;
  bool _isSubmitting = false;
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _categories = [
    'Scoring Engine Issue',
    'Feature Request',
    'Bug Report',
    'App Crash',
    'Other'
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_selectedCategory == null || _detailsController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('general_feedback').add({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': widget.userId,
        'category': _selectedCategory,
        'details': _detailsController.text.trim(),
        'status': 'open',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback sent! Thanks for helping improve OUTCALL.', style: GoogleFonts.lato()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback. Try again.', style: GoogleFonts.lato()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'APP FEEDBACK',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Help us improve OUTCALL by letting us know what is on your mind.',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            'CATEGORY',
            style: GoogleFonts.oswald(fontSize: 12, color: Colors.white54, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                hint: Text('Select a category...', style: GoogleFonts.lato(color: Colors.white38)),
                dropdownColor: const Color(0xFF1A1A2E),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: GoogleFonts.lato(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'DETAILS',
            style: GoogleFonts.oswald(fontSize: 12, color: Colors.white54, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            style: GoogleFonts.lato(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Please describe the issue or your idea...',
              hintStyle: GoogleFonts.lato(color: Colors.white38),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedCategory == null || _detailsController.text.trim().isEmpty || _isSubmitting)
                  ? null
                  : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Text(
                      'SUBMIT FEEDBACK',
                      style: GoogleFonts.oswald(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
