import 'package:sms_advanced/sms_advanced.dart';
import '../models/user_data.dart';
import 'package:flutter/material.dart';

/// Servicio para enviar SMS de emergencia.
/// Usa `sms_advanced` + limpia números correctamente.
class SmsService {
  /// Envía SMS a todos los contactos de emergencia.
  /// Retorna `true` si al menos uno se envió.
  static Future<bool> sendPanicSms({
    required UserData userData,
    required String locationLink,
  }) async {
    if (userData.emergencyContacts.isEmpty) {
      debugPrint('SMS no enviado: no hay contactos.');
      return false;
    }

    final String fullMessage =
        '''
🚨 ¡AYUDA! ¡EMERGENCIA! 🚨
Soy ${userData.name}
${userData.emergencyMessage}

Ubicación: $locationLink
'''
            .trim();

    final SmsSender sender = SmsSender();
    bool anySent = false;

    for (String rawPhone in userData.emergencyContacts) {
      try {
        // LIMPIAR NÚMERO: QUITAR TODO MENOS DÍGITOS Y +
        String cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

        // SI NO TIENE +, AGREGAR +52 (MÉXICO)
        if (!cleanPhone.startsWith('+') && cleanPhone.length == 10) {
          cleanPhone = '+52$cleanPhone';
        }

        if (cleanPhone.length < 11) {
          debugPrint('Número inválido: $rawPhone → $cleanPhone');
          continue;
        }

        final message = SmsMessage(cleanPhone, fullMessage);
        await sender.sendSms(message);
        debugPrint('SMS enviado a: $cleanPhone');
        anySent = true;
      } catch (e) {
        debugPrint('Error SMS a $rawPhone: $e');
      }
    }

    return anySent;
  }
}
