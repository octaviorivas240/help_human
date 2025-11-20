import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> init() async {
    await _tts.setLanguage("es-MX");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
  }

  static Future<void> speakEmergency() async {
    await _tts.speak(
      "¡Ayuda! ¡Estoy en peligro! Mi ubicación se está enviando a mis contactos de emergencia. ¡Por favor envíen ayuda rápido!",
    );
  }

  static Future<void> stop() async {
    await _tts.stop();
  }
}
