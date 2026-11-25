import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de Autenticación Biométrica (Huella Dactilar / Face ID)
/// Opera de forma segura únicamente en plataformas móviles (Android / iOS).
class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const String _keyBioEnabled = 'kpital_biometric_enabled';
  static const String _keyBioIdentifier = 'kpital_bio_identifier';
  static const String _keyBioPassword = 'kpital_bio_password';

  /// Determina si la plataforma actual soporta biometría nativa
  static bool get isPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Verifica si el teléfono tiene hardware biométrico y huellas configuradas
  static Future<bool> isBiometricAvailable() async {
    if (!isPlatformSupported) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint("Error verificando soporte biométrico: $e");
      return false;
    }
  }

  /// Ejecuta el escaneo de huella digital
  static Future<bool> authenticate({
    String reason = 'Escanea tu huella para acceder a Kpital',
  }) async {
    if (!isPlatformSupported) return false;
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint("Error en autenticación por huella: $e");
      return false;
    }
  }

  /// Saber si el usuario tiene activada la opción de huella
  static Future<bool> isBiometricEnabled() async {
    if (!isPlatformSupported) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyBioEnabled) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Activar o desactivar biometría
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBioEnabled, enabled);
      if (!enabled) {
        await prefs.remove(_keyBioIdentifier);
        await prefs.remove(_keyBioPassword);
      }
    } catch (_) {}
  }

  /// Guardar credenciales para acceso rápido por huella
  static Future<void> saveBiometricCredentials({
    required String identifier,
    required String password,
  }) async {
    if (!isPlatformSupported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBioIdentifier, identifier);
      await prefs.setString(_keyBioPassword, password);
      await prefs.setBool(_keyBioEnabled, true);
    } catch (_) {}
  }

  /// Obtener credenciales guardadas si la biometría está habilitada
  static Future<Map<String, String>?> getSavedCredentials() async {
    if (!isPlatformSupported) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyBioEnabled) ?? false;
      if (!enabled) return null;

      final id = prefs.getString(_keyBioIdentifier);
      final pass = prefs.getString(_keyBioPassword);
      if (id != null && id.isNotEmpty && pass != null && pass.isNotEmpty) {
        return {'identifier': id, 'password': pass};
      }
    } catch (_) {}
    return null;
  }

  /// Limpiar credenciales biométricas (ej. al cerrar sesión completamente)
  static Future<void> clearBiometricCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBioIdentifier);
      await prefs.remove(_keyBioPassword);
    } catch (_) {}
  }
}
