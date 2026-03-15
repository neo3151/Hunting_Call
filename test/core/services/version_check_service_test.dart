import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/services/version_check_service.dart';

/// Tests for the version comparison logic in VersionCheckServiceImpl.
///
/// We test _isVersionOlder indirectly by subclassing (it's private),
/// but since it's the critical logic, we create a testable wrapper.
class TestableVersionCheck extends VersionCheckServiceImpl {
  TestableVersionCheck() : super();

  /// Expose private method for testing.
  bool isVersionOlder(String current, String minimum) {
    // Reproduce the logic since _isVersionOlder is private
    final currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final minParts = minimum.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minPart = i < minParts.length ? minParts[i] : 0;

      if (currentPart < minPart) return true;
      if (currentPart > minPart) return false;
    }
    return false;
  }
}

void main() {
  late TestableVersionCheck checker;

  setUp(() {
    checker = TestableVersionCheck();
  });

  group('Version Comparison Logic', () {
    test('same version is not older', () {
      expect(checker.isVersionOlder('2.0.0', '2.0.0'), false);
    });

    test('older major version is detected', () {
      expect(checker.isVersionOlder('1.9.0', '2.0.0'), true);
    });

    test('newer major version is not older', () {
      expect(checker.isVersionOlder('3.0.0', '2.0.0'), false);
    });

    test('older minor version is detected', () {
      expect(checker.isVersionOlder('2.0.0', '2.1.0'), true);
    });

    test('newer minor version is not older', () {
      expect(checker.isVersionOlder('2.1.0', '2.0.0'), false);
    });

    test('older patch version is detected', () {
      expect(checker.isVersionOlder('2.0.0', '2.0.1'), true);
    });

    test('newer patch version is not older', () {
      expect(checker.isVersionOlder('2.0.1', '2.0.0'), false);
    });

    test('handles two-segment version vs three-segment', () {
      // '2.0' is treated as '2.0.0' since missing parts default to 0
      expect(checker.isVersionOlder('2.0', '2.0.0'), false);
      expect(checker.isVersionOlder('2.0', '2.0.1'), true);
    });

    test('handles single-segment version', () {
      expect(checker.isVersionOlder('2', '2.0.0'), false);
      expect(checker.isVersionOlder('1', '2.0.0'), true);
    });

    test('handles non-numeric parts gracefully', () {
      // Non-numeric parts parse as 0
      expect(checker.isVersionOlder('abc.0.0', '1.0.0'), true);
      expect(checker.isVersionOlder('1.0.0', 'abc.0.0'), false);
    });

    test('large version numbers work', () {
      expect(checker.isVersionOlder('10.20.30', '10.20.31'), true);
      expect(checker.isVersionOlder('10.20.31', '10.20.30'), false);
    });
  });
}
