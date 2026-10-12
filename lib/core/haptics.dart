import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اهتزاز لمسي قابل للإيقاف من الإعدادات / Haptics with a user toggle
class Haptics {
  static bool enabled = true;
  static const _k = 'haptics_enabled';

  static Future<void> load() async {
    try {
      enabled = (await SharedPreferences.getInstance()).getBool(_k) ?? true;
    } catch (_) {}
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    try {
      await (await SharedPreferences.getInstance()).setBool(_k, v);
    } catch (_) {}
  }

  static void light() { if (enabled) HapticFeedback.lightImpact(); }
  static void selection() { if (enabled) HapticFeedback.selectionClick(); }
  static void heavy() { if (enabled) HapticFeedback.heavyImpact(); }
}
