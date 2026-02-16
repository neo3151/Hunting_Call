
import 'config/app_config.dart';
import 'main_common.dart';

void main() {
  AppConfig.create(
    flavor: AppFlavor.full,
    appName: "Gobble Guru Pro",
  );
  mainCommon();
}
