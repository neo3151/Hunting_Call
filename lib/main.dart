
import 'package:outcall/config/app_config.dart';
import 'package:outcall/main_common.dart';

// Default entry point - acts as Full version
void main() {
  AppConfig.create(
    flavor: AppFlavor.free,
    appName: 'OUTCALL',
    storeUrl: 'https://play.google.com/store/apps/details?id=com.neo3151.huntingcalls',
  );
  mainCommon();
}
