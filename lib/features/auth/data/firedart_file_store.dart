import 'dart:convert';
import 'dart:io';
import 'package:firedart/firedart.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// A persistent [TokenStore] implementation for Firedart on Linux/Desktop.
/// Stores the authentication token in a JSON file.
class FiredartFileStore extends TokenStore {
  final File file;

  FiredartFileStore(String path) : file = File(path);

  @override
  Token? read() {
    AppLogger.d('FiredartFileStore: Reading token from ${file.path}');
    if (!file.existsSync()) {
      AppLogger.d('FiredartFileStore: Token file does not exist.');
      return null;
    }
    try {
      final contents = file.readAsStringSync();
      if (contents.isEmpty) {
        AppLogger.d('FiredartFileStore: Token file is empty.');
        return null;
      }
      final map = json.decode(contents);
      AppLogger.d("FiredartFileStore: Token decoded. userId: ${map['userId']}");
      return Token.fromMap(map);
    } catch (e) {
      AppLogger.d('FiredartFileStore: Error reading token: $e');
      return null;
    }
  }

  @override
  void write(Token? token) {
    final uid = token?.toMap()['userId'];
    AppLogger.d('FiredartFileStore: Writing token... userId: $uid');
    try {
      if (token == null) {
        if (file.existsSync()) {
          AppLogger.d('FiredartFileStore: Deleting token file (token is null).');
          file.deleteSync();
        }
      } else {
        file.writeAsStringSync(json.encode(token.toMap()));
        AppLogger.d('FiredartFileStore: Token file written successfully for userId: $uid');
      }
    } catch (e) {
      AppLogger.d('FiredartFileStore: Error writing token: $e');
    }
  }

  @override
  void delete() {
    AppLogger.d('FiredartFileStore: delete() called.');
    try {
      if (file.existsSync()) {
        file.deleteSync();
        AppLogger.d('FiredartFileStore: Token file deleted.');
      } else {
        AppLogger.d('FiredartFileStore: delete() - file does not exist.');
      }
    } catch (e) {
      AppLogger.d('FiredartFileStore: Error deleting token: $e');
    }
  }
}
