
import 'package:outcall/config/app_config.dart';
import 'package:outcall/main_common.dart';

void main() {
  AppConfig.create(
    flavor: AppFlavor.full,
    appName: 'Outcall Pro',
  );
  mainCommon();
}
