import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const _secureStorage = FlutterSecureStorage();
  static const _sessionBox = 'session_box';
  static const _appBox = 'app_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_sessionBox);
    await Hive.openBox(_appBox);
  }

  static Future<void> saveSession(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> readSession(String key) async {
    return _secureStorage.read(key: key);
  }

  static Future<void> deleteSession(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Box get sessionBox => Hive.box(_sessionBox);
  static Box get appBox => Hive.box(_appBox);

  static Future<void> clearAll() async {
    await Hive.deleteBoxFromDisk(_sessionBox);
    await Hive.deleteBoxFromDisk(_appBox);
    await _secureStorage.deleteAll();
  }
}
