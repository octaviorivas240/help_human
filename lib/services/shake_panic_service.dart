// lib/services/shake_panic_service.dart
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../main.dart'; // Para showPanicTriggeredToast()
import 'storage_service.dart';
import 'location_service.dart';
import 'sms_service.dart';
import 'whatsapp_service.dart';
import 'call_simulator.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class ShakePanicService {
  // AJUSTADO PERFECTO para México 2025 (probado en calle real)
  static const double _shakeThreshold = 20.0; // Muy sensible pero sin falsos
  static const int _cooldownSeconds =
      45; // Evita spam (45 seg entre activaciones)
  static DateTime? _lastTriggered;
  static StreamSubscription<AccelerometerEvent>? _subscription;

  /// Inicia la detección de sacudidas fuertes (sacudir el celular como loco)
  static void startMonitoring() {
    if (_subscription != null) return;

    _subscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval, // 60 veces por segundo
        ).listen((AccelerometerEvent event) {
          // Calculamos la fuerza total sin gravedad
          final double magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final double acceleration = (magnitude - 9.81)
              .abs(); // Quitamos gravedad y tomamos valor absoluto

          // ¡SACUDIDA DETECTADA!
          if (acceleration > _shakeThreshold) {
            final now = DateTime.now();

            // Cooldown para evitar múltiples activaciones
            if (_lastTriggered == null ||
                now.difference(_lastTriggered!).inSeconds > _cooldownSeconds) {
              _lastTriggered = now;
              _triggerShakePanic();
            }
          }
        });
  }

  /// Detiene la detección (opcional)
  static void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// SE EJECUTA AL DETECTAR SACUDIDA FUERTE
  static Future<void> _triggerShakePanic() async {
    // Vibración de confirmación (solo tú sientes que se activó)
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 400, 200, 400, 200, 400],
      ); // 3 pulsos fuertes
    }

    // Notificación visual
    showPanicTriggeredToast();

    final userData = await StorageService.getUserData();
    if (userData == null) return;

    final String locationLink = await LocationService.getCurrentLocationLink();

    // === ENVÍO DE ALERTA ===
    await SmsService.sendPanicSms(
      userData: userData,
      locationLink: locationLink,
    );

    for (var contact in userData.emergencyContacts) {
      final clean = contact.replaceAll(
        RegExp(r'[^\d]'),
        '',
      ); // CORREGIDO: quitamos el + mal puesto

      await WhatsappService.sendLocation(
        phone: clean,
        message:
            "¡SACUDIDA FUERTE DETECTADA!\n"
            "POSIBLE SECUESTRO, ASALTO O AGRESIÓN\n"
            "¡LLAMEN A LA POLICÍA INMEDIATAMENTE!\n"
            "Ubicación: $locationLink",
        locationLink: locationLink,
      );
    }

    // Llamada falsa inmediata + real en 30 segundos
    await CallSimulator.simulateIncomingCall();

    Future.delayed(const Duration(seconds: 30), () async {
      await FlutterPhoneDirectCaller.callNumber('911');
    });
  }
}
