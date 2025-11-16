import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';

/// Servicio para almacenar de forma persistente los datos del usuario
/// y saber si es la primera vez que se abre la app.
class StorageService {
  // Claves usadas en SharedPreferences
  static const String _keyUserData = 'user_data_json';
  static const String _keyFirstLaunch = 'is_first_launch';

  /// Guarda los datos del usuario y marca que ya no es la primera ejecución.
  static Future<void> saveUserData(UserData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(data.toJson()));
    await prefs.setBool(_keyFirstLaunch, false); // YA NO ES PRIMERA VEZ
  }

  /// Recupera los datos del usuario (puede ser null si nunca se guardaron).
  static Future<UserData?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserData);
    if (raw == null) return null;
    return UserData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Indica si la app se está abriendo por primera vez.
  /// - `true` → Mostrar Onboarding
  /// - `false` → Ir directo a Home
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // Si nunca se guardó la bandera → ES PRIMERA VEZ
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// (Opcional) Limpia todo para pruebas rápidas
  /// Útil en desarrollo: `await StorageService.clearAll();`
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
