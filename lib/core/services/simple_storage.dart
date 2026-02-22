import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction for persistent key-value storage.
abstract class ISimpleStorage {
  Future<String?> getString(String key);
  Future<bool> setString(String key, String value);
  
  Future<int?> getInt(String key);
  Future<bool> setInt(String key, int value);
  
  Future<bool?> getBool(String key);
  Future<bool> setBool(String key, bool value);
  
  Future<double?> getDouble(String key);
  Future<bool> setDouble(String key, double value);
  
  Future<List<String>?> getStringList(String key);
  Future<bool> setStringList(String key, List<String> value);
  
  Future<bool> remove(String key);
  Future<bool> clear();
}

/// SharedPreferences implementation of ISimpleStorage.
class SharedPrefsStorage implements ISimpleStorage {
  final SharedPreferences _prefs;

  SharedPrefsStorage(this._prefs);

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<bool> setString(String key, String value) async => _prefs.setString(key, value);

  @override
  Future<int?> getInt(String key) async => _prefs.getInt(key);

  @override
  Future<bool> setInt(String key, int value) async => _prefs.setInt(key, value);

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<bool> setBool(String key, bool value) async => _prefs.setBool(key, value);

  @override
  Future<double?> getDouble(String key) async => _prefs.getDouble(key);

  @override
  Future<bool> setDouble(String key, double value) async => _prefs.setDouble(key, value);
  
  @override
  Future<List<String>?> getStringList(String key) async => _prefs.getStringList(key);
  
  @override
  Future<bool> setStringList(String key, List<String> value) async => _prefs.setStringList(key, value);

  @override
  Future<bool> remove(String key) async => _prefs.remove(key);

  @override
  Future<bool> clear() async => _prefs.clear();
}
