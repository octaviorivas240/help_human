import 'dart:async';
import 'package:flutter/foundation.dart'; // Nuevo: para debugPrint
import 'package:volume_listener/volume_listener.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../services/location_service.dart';
import '../services/sms_service.dart';
import '../services/whatsapp_service.dart';
import '../services/storage_service.dart';
import '../services/call_simulator.dart';

class VolumePanicService {
  static Timer? _timer;
  static int _pressCount = 0;
  static const int requiredPresses = 3;
  static const Duration timeout = Duration(seconds: 3);

  static void startListening() {
    VolumeListener.addListener((VolumeKey event) async {
      // Detecta cualquier botón de volumen
      if (event == VolumeKey.up || // Corregido: valor real del enum
          event == VolumeKey.down) {
        // Corregido: valor real del enum
        _pressCount++;

        // Reinicia el contador si pasa mucho tiempo
        _timer?.cancel();
        _timer = Timer(timeout, () {
          _pressCount = 0;
        });

        // Si llega a 3 pulsos rápidos → ¡ACTIVA PÁNICO!
        if (_pressCount >= requiredPresses) {
          _pressCount = 0;
          _timer?.cancel();
          await _triggerVolumePanic();
        }
      }
    });
  }

  static Future<void> _triggerVolumePanic() async {
    try {
      // Vibración sutil para confirmar (solo tú sientes)
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 200);
        await Future.delayed(const Duration(milliseconds: 100));
        Vibration.vibrate(duration: 200);
      }

      final userData = await StorageService.getUserData();
      if (userData == null || userData.emergencyContacts.isEmpty) {
        debugPrint(
          'No user data or emergency contacts available. Panic aborted.',
        ); // Corregido: debugPrint
        return;
      }

      final locationLink = await LocationService.getCurrentLocationLink();

      // ENVÍA ALERTA DE SECUESTRO / ASALTO
      await SmsService.sendPanicSms(
        userData: userData,
        locationLink: locationLink,
      );

      for (var contact in userData.emergencyContacts) {
        final clean = contact.replaceAll(RegExp(r'[^\d+]'), '');
        await WhatsappService.sendLocation(
          phone: clean,
          message:
              "¡ACTIVACIÓN CON BOTÓN DE VOLUMEN! POSIBLE SECUESTRO O ASALTO GRAVE\n¡LLAMEN A LA POLICÍA YA!\nUbicación:",
          locationLink: locationLink.isEmpty
              ? 'Ubicación no disponible.'
              : locationLink, // Corregido: evita dead code
        );
      }

      // Llamada falsa + real
      await CallSimulator.simulateIncomingCall();

      // Llamada real a 911 en 30 segundos
      Future.delayed(const Duration(seconds: 30), () async {
        await FlutterPhoneDirectCaller.callNumber(
          '911',
        ); // O '*911' según región
        debugPrint(
          "Llamando al 911 por botón de volumen...",
        ); // Corregido: debugPrint
      });
    } catch (e) {
      debugPrint('Error triggering panic: $e'); // Corregido: debugPrint
    }
  }

  static void stopListening() {
    VolumeListener.removeListener();
    _timer?.cancel();
  }
}
