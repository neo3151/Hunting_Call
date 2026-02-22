import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:hunting_calls_perfection/features/hunting_log/domain/hunting_log_entry.dart';
import 'package:hunting_calls_perfection/features/hunting_log/presentation/controllers/hunting_log_controller.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _animalIdController = TextEditingController(); // Simple for now
  
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
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
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Log Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _animalIdController,
                decoration: const InputDecoration(labelText: 'Animal (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some notes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        _latitude != null ? 'Location Set' : 'Use Current Location',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  if (_latitude != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
