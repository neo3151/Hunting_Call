
import 'package:outcall/config/app_config.dart';
import 'package:outcall/main_common.dart';

void main() {
  AppConfig.create(
    flavor: AppFlavor.free,
    appName: 'Outcall (Free)',
    storeUrl: 'https://play.google.com/store/apps/details?id=com.neo3151.huntingcalls',
  );
  mainCommon();
}
