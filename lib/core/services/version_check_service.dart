import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

abstract class VersionCheckService {
  Future<bool> isUpdateRequired();
  Future<String?> getMinVersion();
}

class VersionCheckServiceImpl implements VersionCheckService {
  final FirebaseFirestore? _firestore;
  final fd.Firestore? _firedart;
  final bool _isLinux;

  VersionCheckServiceImpl({
    FirebaseFirestore? firestore,
    fd.Firestore? firedart,
    required bool isLinux,
  })  : _firestore = firestore,
        _firedart = firedart,
        _isLinux = isLinux;

  @override
  Future<String?> getMinVersion() async {
    try {
      if (_isLinux) {
        if (_firedart == null) return null;
        final doc = await _firedart!.collection('config').document('app_v1').get();
        return doc.map['min_version'] as String?;
      } else {
        if (_firestore == null) return null;
        final doc = await _firestore!.collection('config').doc('app_v1').get();
        return doc.data()?['min_version'] as String?;
      }
    } catch (e) {
      AppLogger.d('VersionCheckService: Error fetching min_version: $e');
      return null;
    }
  }

  @override
  Future<bool> isUpdateRequired() async {
    final minVersionStr = await getMinVersion();
    if (minVersionStr == null) return false;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;

      return _isVersionOlder(currentVersionStr, minVersionStr);
    } catch (e) {
      AppLogger.d('VersionCheckService: Error checking version: $e');
      return false;
    }
  }

  bool _isVersionOlder(String current, String minimum) {
    final currentParts = current.split('.').map(int.parse).toList();
    final minParts = minimum.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minPart = i < minParts.length ? minParts[i] : 0;

      if (currentPart < minPart) return true;
      if (currentPart > minPart) return false;
    }
    return false;
  }
}
