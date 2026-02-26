import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor { free, full }

class AppConfig {
  final AppFlavor flavor;
  final String appName;
  final String? apiBaseUrl;
  final String? storeUrl;

  static AppConfig? _instance;

  AppConfig._internal({
    required this.flavor,
    required this.appName,
    this.apiBaseUrl,
    this.storeUrl,
  });

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig not initialized. Call AppConfig.create() first.');
    }
    return _instance!;
  }

  static void create({
    required AppFlavor flavor,
    required String appName,
    String? apiBaseUrl,
    String? storeUrl,
  }) {
    _instance = AppConfig._internal(
      flavor: flavor,
      appName: appName,
      apiBaseUrl: apiBaseUrl,
      storeUrl: storeUrl,
    );
  }

  /// Riverpod provider — zero breakage for existing code.
  /// New code can use `ref.watch(AppConfig.provider)` instead of `AppConfig.instance`.
  static final provider = Provider<AppConfig>((ref) => AppConfig.instance);

  bool get isFree => flavor == AppFlavor.free;
  bool get isFull => flavor == AppFlavor.full;

  // Feature Flags
  bool get allowMap => isFull;
  bool get allowSocial => isFull;
  bool get allowLeaderboard => isFull;

  // Constants
  static const supportEmail = 'BenchmarkAppsLLC@gmail.com';
}
