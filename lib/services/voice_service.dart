import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'dart:io' show Platform;

class VoiceService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage("es-MX");
    await _tts.setSpeechRate(0.6);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    if (Platform.isAndroid) {
      await _tts.setEngine("com.google.android.tts");
    }
    _initialized = true;
  }

  static Future<void> speakEmergency() async {
    // Vibración durante el habla
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500]);
    }

    await _tts.speak(
      "¡Ayuda! ¡Emergencia! ¡Estoy en peligro! ¡Ven rápido por favor! ¡Mi ubicación está en el mensaje!",
    );
  }

  static Future<void> stop() async {
    await _tts.stop();
    Vibration.cancel();
  }
}
