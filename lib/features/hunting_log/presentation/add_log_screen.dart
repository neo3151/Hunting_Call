import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/hunting_log/domain/hunting_log_entry.dart';
import 'package:outcall/features/hunting_log/presentation/controllers/hunting_log_controller.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _animalIdController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveLog() {
    if (_formKey.currentState!.validate()) {
      final log = HuntingLogEntry(
        id: const Uuid().v4(),
        animalId: _animalIdController.text.isNotEmpty ? _animalIdController.text : 'Observation',
        timestamp: DateTime.now(),
        notes: _notesController.text,
        latitude: _latitude,
        longitude: _longitude,
      );

      ref.read(huntingLogProvider.notifier).addLog(log);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animalIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'NEW ENTRY',
                      style: GoogleFonts.oswald(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Animal field
                        _buildTextField(
                          controller: _animalIdController,
                          label: 'Animal',
                          hint: 'e.g. Whitetail Buck, Turkey, etc.',
                          icon: Icons.pets,
                          colors: colors,
                          primary: primary,
                        ),
                        const SizedBox(height: 20),

                        // Notes field
                        _buildTextField(
                          controller: _notesController,
                          label: 'Notes',
                          hint: 'What happened? Conditions, behavior, etc.',
                          icon: Icons.notes,
                          colors: colors,
                          primary: primary,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter some notes';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Location button
                        Container(
                          decoration: BoxDecoration(
                            color: colors.cardOverlay,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _isLoading ? null : _getLocation,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: (_latitude != null ? Colors.green : primary).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: _isLoading
                                        ? Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                                          )
                                        : Icon(
                                            _latitude != null ? Icons.check_circle : Icons.my_location,
                                            color: _latitude != null ? Colors.green : primary,
                                            size: 20,
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _latitude != null ? 'Location Captured' : 'Tag Location',
                                          style: GoogleFonts.lato(
                                            color: colors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _latitude != null
                                              ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                              : 'Use your current GPS coordinates',
                                          style: GoogleFonts.lato(color: colors.textSubtle, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: colors.iconSubtle),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Save button
                        ElevatedButton(
                          onPressed: _saveLog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'SAVE ENTRY',
                            style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required AppColorPalette colors,
    required Color primary,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.lato(color: colors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.lato(color: colors.textTertiary),
        hintStyle: GoogleFonts.lato(color: colors.textSubtle, fontSize: 13),
        prefixIcon: Icon(icon, color: primary, size: 20),
        filled: true,
        fillColor: colors.cardOverlay,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
