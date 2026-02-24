
import 'package:hunting_calls_perfection/config/app_config.dart';
import 'package:hunting_calls_perfection/main_common.dart';

// Default entry point - acts as Full version
void main() {
  AppConfig.create(
    flavor: AppFlavor.free,
    appName: 'OUTCALL',
  );
  mainCommon();
}
