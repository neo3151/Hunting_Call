import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

void main() async {
  final jsonFile = File('assets/data/reference_calls.json');
  if (!jsonFile.existsSync()) {
    print("Error: reference_calls.json not found.");
    return;
  }

  final data = json.decode(await jsonFile.readAsString());
  final List<dynamic> calls = data['calls'];
  
  print("Processing ${calls.length} calls...");

  for (var call in calls) {
    final String id = call['id'];
    final bool isLocked = call['isLocked'] ?? false;
    final double freq = (call['idealPitchHz'] as num).toDouble();
    final double duration = (call['idealDurationSec'] as num).toDouble();
    final String assetPath = call['audioAssetPath'];
    
    // Only generate if it doesn't exist or is locked
    final audioFile = File(assetPath);
    if (!audioFile.existsSync() || isLocked) {
      print("Generating tone for $id: ${freq}Hz (${duration}s)");
      final wavData = generateWav(freq, duration);
      await audioFile.parent.create(recursive: true);
      await audioFile.writeAsBytes(wavData);
      
      // Update JSON entry to be unlocked
      call['isLocked'] = false;
    }
  }

  // Save updated JSON
  await jsonFile.writeAsString(JsonEncoder.withIndent('    ').convert(data));
  print("Success: 50 animal calls are now UNLOCKED and have reference tones.");
}

Uint8List generateWav(double frequency, double durationInSeconds) {
  const int sampleRate = 44100;
  final int numSamples = (sampleRate * durationInSeconds).toInt();
  final int dataSize = numSamples * 2; // 16-bit mono
  final int fileSize = 44 + dataSize;

  final ByteData header = ByteData(44);
  
  // RIFF header
  header.setUint8(0, 0x52); // R
  header.setUint8(1, 0x49); // I
  header.setUint8(2, 0x46); // F
  header.setUint8(3, 0x46); // F
  header.setUint32(4, fileSize - 8, Endian.little);
  header.setUint8(8, 0x57); // W
  header.setUint8(9, 0x41); // A
  header.setUint8(10, 0x56); // V
  header.setUint8(11, 0x45); // E

  // fmt chunk
  header.setUint8(12, 0x66); // f
  header.setUint8(13, 0x6d); // m
  header.setUint8(14, 0x74); // t
  header.setUint8(15, 0x20); // ' '
  header.setUint32(16, 16, Endian.little); // Chunk size
  header.setUint16(20, 1, Endian.little); // Audio format (PCM)
  header.setUint16(22, 1, Endian.little); // Channels (Mono)
  header.setUint32(24, sampleRate, Endian.little); // Sample rate
  header.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
  header.setUint16(32, 2, Endian.little); // Block align
  header.setUint16(34, 16, Endian.little); // Bits per sample

  // data chunk
  header.setUint8(36, 0x64); // d
  header.setUint8(37, 0x61); // a
  header.setUint8(38, 0x74); // t
  header.setUint8(39, 0x61); // a
  header.setUint32(40, dataSize, Endian.little);

  final Uint8List fullFile = Uint8List(fileSize);
  fullFile.setRange(0, 44, header.buffer.asUint8List());

  final int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    final double time = i / sampleRate;
    // Generate sine wave
    double sample = sin(2 * pi * frequency * time);
    
    // Apply a simple envelope to prevent clicking at start/end
    if (time < 0.05) sample *= (time / 0.05); // Fade in
    if (time > durationInSeconds - 0.05) sample *= ((durationInSeconds - time) / 0.05); // Fade out

    final int val = (sample * 32767).toInt();
    
    // Write 16-bit little-endian sample
    fullFile[offset + (i * 2)] = val & 0xFF;
    fullFile[offset + (i * 2) + 1] = (val >> 8) & 0xFF;
  }

  return fullFile;
}
