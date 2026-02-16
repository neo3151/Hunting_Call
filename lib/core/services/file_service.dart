import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

abstract class FileService {
  Future<String> getTemporaryPath(String fileName);
  Future<String> getApplicationDocumentsPath(String fileName);
}

class FileServiceImpl implements FileService {
  @override
  Future<String> getTemporaryPath(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    return p.join(tempDir.path, fileName);
  }

  @override
  Future<String> getApplicationDocumentsPath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, fileName);
  }
}
