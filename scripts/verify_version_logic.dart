/// Standalone verification script for OUTCALL's version comparison logic.
/// Run this with: dart scripts/verify_version_logic.dart

bool isVersionOlder(String current, String minimum) {
  try {
    final currentParts = current.split('.').map(int.parse).toList();
    final minParts = minimum.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minPart = i < minParts.length ? minParts[i] : 0;

      if (currentPart < minPart) return true;
      if (currentPart > minPart) return false;
    }
    return false;
  } catch (e) {
    print('Error parsing version: $e');
    return false;
  }
}

void test(String current, String minimum, bool expected) {
  final result = isVersionOlder(current, minimum);
  final status = result == expected ? '✅ PASS' : '❌ FAIL';
  print('$status: Current($current) < Min($minimum) -> $result (Expected: $expected)');
}

void main() {
  print('--- OUTCALL Version Checker Logic Test ---');
  
  // Scenario 1: Same version
  test('1.5.0', '1.5.0', false);
  
  // Scenario 2: Older major
  test('0.9.0', '1.0.0', true);
  
  // Scenario 3: Older minor
  test('1.4.0', '1.5.0', true);
  
  // Scenario 4: Older patch
  test('1.5.0', '1.5.1', true);
  
  // Scenario 5: Newer major
  test('2.0.0', '1.5.0', false);
  
  // Scenario 6: Newer minor
  test('1.6.0', '1.5.0', false);
  
  // Scenario 7: Simple formats
  test('1.5', '1.5.0', false);
  test('1.4', '1.5.0', true);

  print('\n--- Logic Verification Complete ---');
}
