import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firedart/firedart.dart';

/// A persistent [TokenStore] implementation for Firedart on Linux/Desktop.
/// Stores the authentication token in a JSON file.
class FiredartFileStore extends TokenStore {
  final File file;

  FiredartFileStore(String path) : file = File(path);

  @override
  Token? read() {
    debugPrint('FiredartFileStore: Reading token from ${file.path}');
    if (!file.existsSync()) {
      debugPrint('FiredartFileStore: Token file does not exist.');
      return null;
    }
    try {
      final contents = file.readAsStringSync();
      if (contents.isEmpty) {
        debugPrint('FiredartFileStore: Token file is empty.');
        return null;
      }
      final map = json.decode(contents);
      debugPrint("FiredartFileStore: Token decoded. userId: ${map['userId']}");
      return Token.fromMap(map);
    } catch (e) {
      debugPrint('FiredartFileStore: Error reading token: $e');
      return null;
    }
  }

  @override
  void write(Token? token) {
    final uid = token?.toMap()['userId'];
    debugPrint('FiredartFileStore: Writing token... userId: $uid');
    try {
      if (token == null) {
        if (file.existsSync()) {
          debugPrint('FiredartFileStore: Deleting token file (token is null).');
          file.deleteSync();
        }
      } else {
        file.writeAsStringSync(json.encode(token.toMap()));
        debugPrint('FiredartFileStore: Token file written successfully for userId: $uid');
      }
    } catch (e) {
      debugPrint('FiredartFileStore: Error writing token: $e');
    }
  }

  @override
  void delete() {
    debugPrint('FiredartFileStore: delete() called.');
    try {
      if (file.existsSync()) {
        file.deleteSync();
        debugPrint('FiredartFileStore: Token file deleted.');
      } else {
        debugPrint('FiredartFileStore: delete() - file does not exist.');
      }
    } catch (e) {
      debugPrint('FiredartFileStore: Error deleting token: $e');
    }
  }
}
