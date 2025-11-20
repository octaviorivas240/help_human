import 'package:url_launcher/url_launcher.dart';
import '../models/user_data.dart';
import 'package:flutter/material.dart';

/// Servicio para enviar SMS de emergencia usando intent nativo
class SmsService {
  /// Envía SMS directo (abre la app de mensajes con texto prellenado)
  static Future<bool> sendPanicSms({
    required UserData userData,
    required String locationLink,
  }) async {
    if (userData.emergencyContacts.isEmpty) {
      debugPrint('SMS: No hay contactos');
      return false;
    }

    final String message =
        '''
🚨 ¡AYUDA! ¡EMERGENCIA HELP HUMAN! 🚨
Soy ${userData.name.toUpperCase()}

${userData.emergencyMessage}

UBICACIÓN EN VIVO: $locationLink

¡LLAMEN AL 911 INMEDIATAMENTE!
    '''
            .trim();

    // Preparar números
    List<String> phones = [];
    for (String raw in userData.emergencyContacts) {
      String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
      if (clean.length == 10) clean = '+52$clean'; // México
      if (clean.length >= 11) phones.add(clean);
    }

    if (phones.isEmpty) return false;

    // URI para SMS (envía a múltiples números)
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phones.join(','),
      queryParameters: {'body': Uri.encodeComponent(message)},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        debugPrint('SMS enviado a ${phones.length} contactos');
        return true;
      } else {
        debugPrint('No se puede abrir app de SMS');
        return false;
      }
    } catch (e) {
      debugPrint('Error SMS: $e');
      return false;
    }
  }
}
