
import 'package:hunting_calls_perfection/config/app_config.dart';
import 'package:hunting_calls_perfection/main_common.dart';

void main() {
  AppConfig.create(
    flavor: AppFlavor.free,
    appName: 'Outcall (Free)',
    storeUrl: 'https://play.google.com/store/apps/details?id=com.huntingcall.full', // Placeholder
  );
  mainCommon();
}
