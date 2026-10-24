import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _deviceIdKey = 'dateora_unique_device_id';
  static String? _cachedDeviceId;

  /// Returns a persistent, anonymous device UUID generated once per installation.
  /// Used for backend quota and daily rate limit enforcement.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);

    if (id == null || id.trim().isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }

    _cachedDeviceId = id;
    return id;
  }
}
