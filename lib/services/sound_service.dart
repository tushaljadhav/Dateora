import 'package:flutter/services.dart';

/// Service to trigger authentic POS cash-counter sound and haptic feedback
/// when a barcode is scanned.
class SoundService {
  static const MethodChannel _channel = MethodChannel('com.dateora.dateora/sound');

  /// Plays the authentic supermarket cash-counter barcode scanner beep tone
  /// alongside a tactile haptic vibration.
  static Future<void> playBarcodeBeep() async {
    try {
      // Immediate haptic feedback
      HapticFeedback.mediumImpact();

      // Trigger native Android hardware ToneGenerator
      final bool? played = await _channel.invokeMethod<bool>('playBarcodeBeep');
      if (played != true) {
        // Fallback to system alert sound if native channel is unavailable
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }
}
