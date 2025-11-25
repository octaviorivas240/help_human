import 'dart:async';
import 'package:torch_light/torch_light.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/material.dart';

class SirenService {
  static final AudioPlayer _player = AudioPlayer();
  static Timer? _flashTimer;
  static bool _isRunning = false;

  /// SIRENA ULTRA FUERTE + FLASH PARPADEANDO RÁPIDO + VIBRACIÓN CONTINUA
  static Future<void> startSiren({int durationSeconds = 90}) async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      // 1. SONIDO INMEDIATO Y AL MÁXIMO VOLUMEN
      await _player.setAsset('assets/sounds/siren.mp3');
      await _player.setVolume(1.0);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();

      // 2. FLASH PARPADEANDO RÁPIDO (400ms) – MÉTODO CORRECTO Y ESTABLE
      bool isOn = true;
      _flashTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        if (!_isRunning) return;
        if (isOn) {
          TorchLight.disableTorch().catchError((_) {});
        } else {
          TorchLight.enableTorch().catchError((_) {});
        }
        isOn = !isOn;
      });

      // 3. VIBRACIÓN FUERTE Y CONTINUA
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          repeat: -1,
        ); // -1 = infinito
      }

      // Auto parar después de X segundos
      Future.delayed(Duration(seconds: durationSeconds), () {
        if (_isRunning) stopSiren();
      });
    } catch (e) {
      debugPrint('Error al iniciar sirena: $e');
      _isRunning = false;
    }
  }

  /// DETENER TODO AL INSTANTE
  static Future<void> stopSiren() async {
    if (!_isRunning) return;
    _isRunning = false;

    try {
      await _player.stop();
    } catch (_) {}

    try {
      await TorchLight.disableTorch();
    } catch (_) {}

    _flashTimer?.cancel();
    _flashTimer = null;

    try {
      await Vibration.cancel();
    } catch (_) {}

    debugPrint('Sirena detenida correctamente');
  }

  /// ¿ESTÁ SONANDO?
  static bool get isRunning => _isRunning;
}
