import 'package:geolocator/geolocator.dart';
import 'dart:async';
/// Servicio para obtener la ubicación actual del dispositivo
/// y devolver un enlace de Google Maps listo para compartir.
class LocationService {
  /// Solicita permiso de ubicación si no está concedido y devuelve
  /// un enlace de Google Maps con latitud y longitud.
  /// Si ocurre un error, devuelve un mensaje descriptivo.
  static Future<String> getCurrentLocationLink() async {
    // 1. Verificar si el servicio de ubicación está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'El GPS está desactivado. Actívalo para enviar tu ubicación.';
    }

    // 2. Verificar y solicitar permiso
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Permiso de ubicación denegado. No se puede enviar tu posición.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Permiso de ubicación denegado permanentemente. Ve a Ajustes > Apps > Help Human > Permisos.';
    }

    // 3. Obtener posición con alta precisión
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 4. Generar enlace de Google Maps
      final String mapsUrl =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';

      return mapsUrl;
    } on TimeoutException {
      return 'Tiempo agotado al obtener ubicación. Intenta de nuevo.';
    } catch (e) {
      return 'Error al obtener ubicación: $e';
    }
  }

  /// Versión simple que solo devuelve coordenadas (opcional)
  static Future<String> getCoordinatesOnly() async {
    final link = await getCurrentLocationLink();
    if (link.contains('maps.google.com')) {
      final uri = Uri.parse(link);
      final lat = uri.queryParameters['q']?.split(',').first;
      final lng = uri.queryParameters['q']?.split(',').last;
      return '$lat, $lng';
    }
    return 'No disponible';
  }
}