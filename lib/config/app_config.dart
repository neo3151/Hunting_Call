
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
      throw Exception("AppConfig not initialized. Call AppConfig.create() first.");
    }
    return _instance!;
  }

  static void create({
    required AppFlavor flavor,
    required String appName,
    String? apiBaseUrl,
    String? storeUrl,
  }) {
    if (_instance != null) {
       // Allow re-initialization for testing or hot restart scenarios if needed, 
       // but typically this runs once. 
       // For now, we'll just overwrite it or ignore.
    }
    _instance = AppConfig._internal(
      flavor: flavor,
      appName: appName,
      apiBaseUrl: apiBaseUrl,
      storeUrl: storeUrl,
    );
  }
  
  bool get isFree => flavor == AppFlavor.free;
  bool get isFull => flavor == AppFlavor.full;

  // Feature Flags
  bool get allowMap => isFull;
  bool get allowSocial => isFull;
  bool get allowLeaderboard => isFull;
}
