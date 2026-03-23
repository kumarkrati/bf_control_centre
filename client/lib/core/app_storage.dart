import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class AppStorage {
  AppStorage._();

  static late GetStorage _box;

  static Future<void> init() async {
    await GetStorage.init('control-centre-box');
    _box = GetStorage('control-centre-box');
  }

  static Future<void> set(String key, dynamic value) async {
    if (value.runtimeType == String ||
        value.runtimeType == double ||
        value.runtimeType == num ||
        value.runtimeType == int ||
        value.runtimeType == bool) {
      await _box.write(key, value);
    } else {
      await _box.write(key, jsonEncode(value));
    }
  }

  static T? get<T>(String key) {
    final value = _box.read(key);
    if (value == null) {
      print("[AppStorage] No value available for '${key}'");
      return null;
    }
    if (T == Map) {
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

    await _box.write(_recentMobilesKey, jsonEncode(recentMobiles));
  }

  static List<String> getRecentMobiles() {
    final value = _box.read(_recentMobilesKey);
    if (value == null) return [];

    try {
      final List<dynamic> decoded =
          value is String ? jsonDecode(value) : value;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      print("[AppStorage] Error decoding recent mobiles: $e");
      return [];
    }
  }

  static Future<void> clearRecentMobiles() async {
    await _box.remove(_recentMobilesKey);
  }
}
