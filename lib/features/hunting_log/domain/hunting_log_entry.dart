import 'package:equatable/equatable.dart';

class HuntingLogEntry extends Equatable {
  final String id;
  final String? animalId; // ID of the animal call used or animal sighted
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String notes;
  final String? imagePath; // Path to a captured image

  const HuntingLogEntry({
    required this.id,
    this.animalId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.notes = '',
    this.imagePath,
  });

  @override
  List<Object?> get props => [id, animalId, timestamp, latitude, longitude, notes, imagePath];

  // SQLite Helper Methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'imagePath': imagePath,
    };
  }

  factory HuntingLogEntry.fromMap(Map<String, dynamic> map) {
    return HuntingLogEntry(
      id: map['id'] as String,
      animalId: map['animalId'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      notes: map['notes'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
    );
  }
}
