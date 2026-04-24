import 'package:outcall/config/app_config.dart';
import 'package:outcall/main_common.dart';

/// 🦌 OUTCALL - Unified Entrypoint
/// 
/// We have aggressively deprecated `main_free.dart` and `main_full.dart`.
/// OUTCALL now ships as a single, unified client binary.
///
/// "Pro" state and feature gating are no longer controlled at compile-time.
/// Instead, we use Firebase Remote Config and server-side user profile
/// validation (entitlements) to dynamically unlock features.
void main() {
  // Initialize the base configuration. The application always starts in the 
  // 'freemium' posture until the server proves the user holds a Pro license.
  AppConfig.create(
    flavor: AppFlavor.free,
    appName: 'OUTCALL',
    storeUrl: 'https://play.google.com/store/apps/details?id=com.neo3151.huntingcalls',
  );
  
  // Hand off to the global app initializer which spins up Riverpod,
  // SQLite, Sentry, Firebase, and the Offline Sync Watcher.
  mainCommon();
}
