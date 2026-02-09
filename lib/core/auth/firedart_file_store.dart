import 'dart:convert';
import 'dart:io';
import 'package:firedart/firedart.dart';

/// A persistent [TokenStore] implementation for Firedart on Linux/Desktop.
/// Stores the authentication token in a JSON file.
class FiredartFileStore extends TokenStore {
  final File file;

  FiredartFileStore(String path) : file = File(path);

  @override
  Token? read() {
    print("FiredartFileStore: Reading token from ${file.path}");
    if (!file.existsSync()) {
      print("FiredartFileStore: Token file does not exist.");
      return null;
    }
    try {
      final contents = file.readAsStringSync();
      if (contents.isEmpty) {
        print("FiredartFileStore: Token file is empty.");
        return null;
      }
      final map = json.decode(contents);
      print("FiredartFileStore: Token decoded. userId: ${map['userId']}");
      return Token.fromMap(map);
    } catch (e) {
      print("FiredartFileStore: Error reading token: $e");
      return null;
    }
  }

  @override
  void write(Token? token) {
    final uid = token?.toMap()['userId'];
    print("FiredartFileStore: Writing token... userId: $uid");
    try {
      if (token == null) {
        if (file.existsSync()) {
          print("FiredartFileStore: Deleting token file (token is null).");
          file.deleteSync();
        }
      } else {
        file.writeAsStringSync(json.encode(token.toMap()));
        print("FiredartFileStore: Token file written successfully for userId: $uid");
      }
    } catch (e) {
      print("FiredartFileStore: Error writing token: $e");
    }
  }

  @override
  void delete() {
    print("FiredartFileStore: delete() called.");
    try {
      if (file.existsSync()) {
        file.deleteSync();
        print("FiredartFileStore: Token file deleted.");
      } else {
        print("FiredartFileStore: delete() - file does not exist.");
      }
    } catch (e) {
      print("FiredartFileStore: Error deleting token: $e");
    }
  }
}
