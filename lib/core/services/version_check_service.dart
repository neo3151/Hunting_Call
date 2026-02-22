import 'package:hunting_calls_perfection/core/services/api_gateway.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

abstract class VersionCheckService {
  Future<bool> isUpdateRequired();
  Future<String?> getMinVersion();
}

class VersionCheckServiceImpl implements VersionCheckService {
  final ApiGateway? _apiGateway;

  VersionCheckServiceImpl({
    ApiGateway? apiGateway,
  })  : _apiGateway = apiGateway;

  @override
  Future<String?> getMinVersion() async {
    try {
      if (_apiGateway == null) return null;
      final data = await _apiGateway!.getDocument('config', 'app_v1');
      return data?['min_version'] as String?;
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
