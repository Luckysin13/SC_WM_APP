import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_identity.dart';

class LocalCacheService {
  final SharedPreferences _prefs;

  static const String _keyLastDevice = 'last_device';
  static const String _keyRecentDevices = 'recent_devices';

  LocalCacheService(this._prefs);

  Future<void> saveLastDevice(DeviceIdentity device) async {
    await _prefs.setString(_keyLastDevice, jsonEncode(device.toJson()));
    await _addRecentDevice(device);
  }

  DeviceIdentity? getLastDevice() {
    final str = _prefs.getString(_keyLastDevice);
    if (str == null) return null;
    try {
      return DeviceIdentity.fromJson(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLastDevice() async {
    await _prefs.remove(_keyLastDevice);
  }

  Future<void> _addRecentDevice(DeviceIdentity device) async {
    final recent = getRecentDevices();
    final index = recent.indexWhere((d) => d.host == device.host);
    if (index >= 0) {
      recent.removeAt(index);
    }
    recent.insert(0, device);
    if (recent.length > 5) {
      recent.removeLast();
    }
    final encoded = recent.map((d) => d.toJson()).toList();
    await _prefs.setString(_keyRecentDevices, jsonEncode(encoded));
  }

  Future<void> removeRecentDevice(String host) async {
    final recent = getRecentDevices();
    recent.removeWhere((d) => d.host == host);
    final encoded = recent.map((d) => d.toJson()).toList();
    await _prefs.setString(_keyRecentDevices, jsonEncode(encoded));
    
    // Also clear from last_device if it matches
    final last = getLastDevice();
    if (last != null && last.host == host) {
      await clearLastDevice();
    }
  }

  List<DeviceIdentity> getRecentDevices() {
    final str = _prefs.getString(_keyRecentDevices);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((e) => DeviceIdentity.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
