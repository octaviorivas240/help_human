import 'dart:async';
import 'package:torch_light/torch_light.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/material.dart'; // Para debugPrint

class SirenService {
  static final AudioPlayer _player = AudioPlayer();
  static Timer? _flashTimer;
  static bool _isRunning = false;

  /// Activa sirena ultra fuerte + flash parpadeando + vibración
  static Future<void> startSiren({int durationSeconds = 90}) async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      // 1. SONIDO ULTRA FUERTE (110 dB)
      await _player.setAsset('assets/sounds/siren.mp3');
      await _player.setVolume(1.0);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();

      // 2. FLASH PARPADEANDO (300ms on/off)
      await TorchLight.enableTorch();
      _flashTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (_isRunning) {
          TorchLight.disableTorch();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_isRunning) TorchLight.enableTorch();
          });
        }
      });

      // 3. VIBRACIÓN CONTINUA
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 200, 100, 200], repeat: 1);
      }

      // Auto parar
      Future.delayed(Duration(seconds: durationSeconds), stopSiren);
    } catch (e) {
      debugPrint('Sirena error: $e');
    }
  }

  static Future<void> stopSiren() async {
    _isRunning = false;

    try {
      await _player.stop();
      await TorchLight.disableTorch();
      _flashTimer?.cancel();
      Vibration.cancel();
    } catch (e) {
      debugPrint('Sirena stop error: $e');
    }
  }
}
