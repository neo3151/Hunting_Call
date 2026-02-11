
import 'config/app_config.dart';
import 'main_common.dart';

// Default entry point - acts as Full version
void main() {
  AppConfig.create(
    flavor: AppFlavor.free,
    appName: "Hunting Calls Free",
  );
  mainCommon();
}
