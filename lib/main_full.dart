
import 'package:hunting_calls_perfection/config/app_config.dart';
import 'package:hunting_calls_perfection/main_common.dart';

void main() {
  AppConfig.create(
    flavor: AppFlavor.full,
    appName: 'Outcall Pro',
  );
  mainCommon();
}
