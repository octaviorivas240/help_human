import 'package:sms_advanced/sms_advanced.dart';
import '../models/user_data.dart';
import 'dart:async';
import 'package:flutter/material.dart';


/// Servicio para enviar SMS de emergencia a los contactos guardados.
/// Incluye nombre, mensaje personalizado y enlace de ubicación.
class SmsService {
  /// Envía el mensaje de pánico a todos los contactos de emergencia.
  /// Retorna `true` si al menos un SMS se envió con éxito.
  static Future<bool> sendPanicSms({
    required UserData userData,
    required String locationLink,
  }) async {
    if (userData.emergencyContacts.isEmpty) {
      debugPrint('SMS no enviado: no hay contactos de emergencia.');
      return false;
    }

    final String fullMessage = '''
${userData.emergencyMessage}

${userData.name}
Ubicación: $locationLink
'''.trim();

    final SmsSender sender = SmsSender();
    bool anySent = false;

    for (String phone in userData.emergencyContacts) {
      try {
        // Limpiar número (quitar espacios, guiones, etc.)
        final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
        if (cleanPhone.length < 10) {
          debugPrint('Número inválido: $phone');
          continue;
        }

        await sender.sendSms(SmsMessage(cleanPhone, fullMessage));
        debugPrint('SMS enviado a: $cleanPhone');
        anySent = true;
      } catch (e) {
        debugPrint('Error enviando SMS a $phone: $e');
      }
    }

    return anySent;
  }
}