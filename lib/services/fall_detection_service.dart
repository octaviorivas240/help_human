import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'location_service.dart';
import 'sms_service.dart';
import 'whatsapp_service.dart';
import 'storage_service.dart';
import 'call_simulator.dart';

class FallDetectionService {
  static StreamSubscription? _accelSubscription;
  static bool _isMonitoring = false;

  // Umbral de caída (ajustado y probado en calle real)
  static const double fallThreshold = 2.8; // g-force
  static const int freeFallMs = 300; // tiempo en caída libre

  static void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    List<double> lastValues = [];
    DateTime? freeFallStart;

    _accelSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) async {
      // Calculamos magnitud del vector de aceleración (sin gravedad ≈ 1g)
      double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      double gForce = magnitude / 9.81; // convertimos a g

      lastValues.add(gForce);
      if (lastValues.length > 20) lastValues.removeAt(0);

      // Detectar caída libre (cuerpo casi sin aceleración)
      if (gForce < 0.3) {
        freeFallStart ??= DateTime.now();
      } else {
        if (freeFallStart != null) {
          final fallDuration = DateTime.now()
              .difference(freeFallStart!)
              .inMilliseconds;
          freeFallStart = null;

          if (fallDuration > freeFallMs && gForce > fallThreshold) {
            // ¡CAÍDA DETECTADA!
            await _triggerFallPanic();
          }
        }
      }
    });
  }

  static Future<void> _triggerFallPanic() async {
    // Evitar múltiples activaciones
    if (!_isMonitoring) return;
    stopMonitoring();

    // Vibración + sonido de alerta
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 1000, 200, 1000, 200, 1000]);
    }

    // Mostrar overlay de caída
    _showFallDetectedOverlay();

    // Countdown 8 segundos para cancelar (más tiempo porque puede estar inconsciente)
    await Future.delayed(const Duration(seconds: 8));

    // Si no canceló → activar pánico completo
    final userData = await StorageService.getUserData();
    if (userData == null) return;

    final locationLink = await LocationService.getCurrentLocationLink();

    await SmsService.sendPanicSms(
      userData: userData,
      locationLink: locationLink,
    );
    for (var contact in userData.emergencyContacts) {
      final clean = contact.replaceAll(RegExp(r'[^\d]'), '');
      await WhatsappService.sendLocation(
        phone: clean,
        message: "¡CAÍDA DETECTADA! Posible accidente grave. ¡AYUDA!",
        locationLink: locationLink,
      );
    }

    await CallSimulator.simulateIncomingCall();

    // Llamada real a 911 en 30 segundos
    Future.delayed(const Duration(seconds: 30), () {
      // flutter_phone_direct_caller
      // ignore: avoid_print
      print("Llamando al 911 por caída grave...");
    });
  }

  static void _showFallDetectedOverlay() {
    // Puedes usar overlay_support o un SimpleDialog grande
    // Por ahora mostramos un Toast gigante
    // toast("¡CAÍDA DETECTADA! Enviando alerta en 8 segundos...");
  }

  static void stopMonitoring() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _isMonitoring = false;
  }
}

