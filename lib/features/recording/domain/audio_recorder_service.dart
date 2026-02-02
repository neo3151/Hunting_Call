abstract class AudioRecorderService {
  Future<void> init();
  
  /// Starts recording to the given [path]. Returns [true] if successful.
  Future<bool> startRecorder(String path);
  Future<String?> stopRecorder();
  Stream<double> get onAmplitudeChanged;
  bool get isRecording;
  String? get lastError;
  void dispose();
}
