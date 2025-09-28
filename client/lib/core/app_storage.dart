import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage._();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> set(String key, dynamic value) async {
    if (value.runtimeType == double || value.runtimeType == num) {
      await _prefs.setDouble(key, value);
    } else if (value.runtimeType == int) {
      await _prefs.setInt(key, value);
    } else if (value.runtimeType == bool) {
      await _prefs.setBool(key, value);
    } else {
      if (value.runtimeType == String) {
        await _prefs.setString(key, value);
      } else {
        await _prefs.setString(key, jsonEncode(value));
      }
    }
  }

  static T? get<T>(String key) {
    final value = _prefs.get(key);
    if (value == null) {
      print("[AppStorage] No value available for '${key}'");
      return null;
    }
    if (T.runtimeType == Map) {
      return jsonDecode(value.toString());
    }
    return value as T;
  }
}
