import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:vibration/vibration.dart';
import 'voice_service.dart';

class CallSimulator {
  static OverlaySupportEntry? _entry;
  static bool _isVibrating = false;

  static Future<void> simulateIncomingCall() async {
    await _startVibration();
    await VoiceService.init();
    await VoiceService.speakEmergency();

    _entry = showOverlay(
      (context, t) => _buildCallUI(context, t),
      duration: const Duration(seconds: 20),
    );

    // Auto cerrar en 20 segundos
    Future.delayed(const Duration(seconds: 20), () {
      dismissFakeCall();
      VoiceService.stop();
    });
  }

  static Future<void> _startVibration() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
      _isVibrating = true;
    }
  }

  static void dismissFakeCall() {
    if (_isVibrating) {
      Vibration.cancel();
      _isVibrating = false;
    }
    _entry?.dismiss(animate: true);
    _entry = null;
    VoiceService.stop();
  }

  static Widget _buildCallUI(BuildContext context, double t) {
    return Material(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: Center(
          child: AnimatedOpacity(
            opacity: t,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.emergency, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "911 - Emergencia",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Llamada entrante",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _callButton(
                        Icons.call,
                        Colors.green,
                        () => dismissFakeCall(),
                      ),
                      _callButton(
                        Icons.call_end,
                        Colors.red,
                        () => dismissFakeCall(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _callButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 40, color: Colors.white),
      ),
    );
  }
}
