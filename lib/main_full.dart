
import 'config/app_config.dart';
import 'main_common.dart';

void main() {
  AppConfig.create(
    flavor: AppFlavor.full,
    appName: 'Outcall Pro',
  );
  mainCommon();
}
