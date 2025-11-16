import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

/// Servicio para enviar ubicación + mensaje por WhatsApp
class WhatsappService {
  /// Envía mensaje con ubicación a un número de teléfono
  /// Formato: wa.me/5215512345678?text=...
  static Future<bool> sendLocation({
    required String phone,
    required String message,
    required String locationLink,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final fullMessage = '$message\n\nUbicación: $locationLink';

    final encodedMessage = Uri.encodeComponent(fullMessage);
    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error WhatsApp: $e');
      return false;
    }
  }
}