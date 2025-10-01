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

  // Recent mobile numbers management
  static const String _recentMobilesKey = 'recent_mobile_numbers';
  static const int _maxRecentEntries = 10;

  static Future<void> addRecentMobile(String mobile) async {
    if (mobile.trim().isEmpty) return;

    final recentMobiles = getRecentMobiles();

    // Remove if already exists
    recentMobiles.remove(mobile);

    // Add to the beginning
    recentMobiles.insert(0, mobile);

    // Keep only last 10 entries
    if (recentMobiles.length > _maxRecentEntries) {
      recentMobiles.removeRange(_maxRecentEntries, recentMobiles.length);
    }

    await _prefs.setString(_recentMobilesKey, jsonEncode(recentMobiles));
  }

  static List<String> getRecentMobiles() {
    final value = _prefs.getString(_recentMobilesKey);
    if (value == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(value);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      print("[AppStorage] Error decoding recent mobiles: $e");
      return [];
    }
  }

  static Future<void> clearRecentMobiles() async {
    await _prefs.remove(_recentMobilesKey);
  }
}
