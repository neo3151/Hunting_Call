
import 'config/app_config.dart';
import 'main_common.dart';

void main() {
  AppConfig.create(
    flavor: AppFlavor.free,
    appName: "Gobble Guru (Free)",
    storeUrl: "https://play.google.com/store/apps/details?id=com.huntingcall.full", // Placeholder
  );
  mainCommon();
}
