import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:vibration/vibration.dart';
import 'voice_service.dart';

class CallSimulator {
  static OverlaySupportEntry? _entry;
  static bool _isVibrating = false;

  // MÉTODO PÚBLICO QUE USAS EN home_screen.dart
  static Future<void> simulateIncomingCall() async {
    await showFakeCallOverlay();
    await VoiceService.init();
    await VoiceService.speakEmergency();

    // Auto-cerrar en 15 segundos
    Future.delayed(const Duration(seconds: 15), () {
      dismissFakeCall();
      VoiceService.stop();
    });
  }

  // MÉTODO PARA SEGUNDO PLANO (Workmanager)
  static Future<void> showFakeCallOverlay() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 1000);
      _isVibrating = true;
    }

    _entry = showOverlay(
      (context, t) => _buildCallUI(context, t),
      duration: const Duration(seconds: 15),
    );
  }

  // MÉTODO PARA CERRAR
  static void dismissFakeCall() {
    if (_isVibrating) {
      Vibration.cancel();
      _isVibrating = false;
    }
    _entry?.dismiss();
    _entry = null;
  }

  // UI DE LA LLAMADA FALSA
  static Widget _buildCallUI(BuildContext context, double t) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          width: double.infinity,
          height: 400,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.red,
                child: Icon(Icons.emergency, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Emergencia 911',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Llamada entrante',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: dismissFakeCall,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: dismissFakeCall,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
