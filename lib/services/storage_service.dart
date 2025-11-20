import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';

/// Servicio para almacenar de forma persistente los datos del usuario
class StorageService {
  // Instancia única
  static late SharedPreferences _prefs;

  // Claves usadas
  static const String _keyUserData = 'user_data_json';
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyPanicFeaturesToast =
      'panic_features_toast_shown'; // ← NUEVA CLAVE

  /// Inicializa SharedPreferences (OBLIGATORIO en main.dart)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // =================== MÉTODOS GENÉRICOS (super útiles) ===================
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return _prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  // ===========================================================================

  /// Guarda los datos del usuario y marca que ya no es primera ejecución
  static Future<void> saveUserData(UserData data) async {
    await _prefs.setString(_keyUserData, jsonEncode(data.toJson()));
    await _prefs.setBool(_keyFirstLaunch, false);
  }

  /// Recupera los datos del usuario
  static Future<UserData?> getUserData() async {
    final raw = _prefs.getString(_keyUserData);
    if (raw == null) return null;
    return UserData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Indica si es primera vez que se abre la app
  static Future<bool> isFirstLaunch() async {
    return _prefs.getBool(_keyFirstLaunch) ?? true;
  }

  // =================== TOAST DE FUNCIONES DE PÁNICO (caída, volumen, sacudida) ===================
  static Future<bool> wasPanicToastShown() async {
    return await getBool(_keyPanicFeaturesToast);
  }

  static Future<void> markPanicToastAsShown() async {
    await setBool(_keyPanicFeaturesToast, true);
  }
  // ===========================================================================

  /// Limpia todo (útil en desarrollo)
  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
