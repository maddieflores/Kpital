import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de Usuario en Kpital
class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role; // 'owner', 'admin', 'user'
  final String plan; // 'owner', 'pro', 'free'
  final String currency;
  final String countryCode;

  bool get isOwner => role == 'owner';

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'KP';
  }

  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.plan,
    this.currency = 'BOB',
    this.countryCode = 'BO',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'plan': plan,
        'currency': currency,
        'country_code': countryCode,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? 'user-001',
        username: json['username'] as String? ?? 'usuario',
        fullName: json['full_name'] as String? ?? 'Usuario Kpital',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phone_number'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
        plan: json['plan'] as String? ?? 'free',
        currency: json['currency'] as String? ?? 'BOB',
        countryCode: json['country_code'] as String? ?? 'BO',
      );

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? currency,
    String? countryCode,
    String? role,
    String? plan,
  }) {
    return UserModel(
      id: id,
      username: username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      currency: currency ?? this.currency,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}

/// Cliente de autenticación de Kpital. El servidor valida la identidad y el rol.
class AuthProvider extends ChangeNotifier {
  static const _backend = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://kpital-api.onrender.com',
  );
  static const _guest = UserModel(
    id: '', username: 'invitado', fullName: 'Invitado', email: '',
    phoneNumber: '', role: 'user', plan: 'free',
  );

  static const _tokenKey = 'kpital_session_token_v2';
  static const _userKey = 'kpital_session_user_v2';

  UserModel _currentUser = _guest;
  String? _token;
  String? errorMessage;

  UserModel get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;
  bool get isOwner => isLoggedIn && _currentUser.isOwner;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _clearLegacyCredentials();
    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final savedUserJson = prefs.getString(_userKey);
      if (savedToken != null &&
          savedToken.isNotEmpty &&
          savedUserJson != null &&
          savedUserJson.isNotEmpty) {
        _token = savedToken;
        _currentUser = UserModel.fromJson(
          jsonDecode(savedUserJson) as Map<String, dynamic>,
        );
        notifyListeners();
      }
    } catch (_) {
      // Ignora errores si los datos locales están corruptos.
    }
  }

  Future<void> _clearLegacyCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('kpital_owner_password_v1');
      await prefs.remove('kpital_authenticated_user_v1');
      await prefs.remove('kpital_user_accounts_v1');
      await prefs.remove('kpital_transactions_v1');
      await prefs.remove('kpital_debts_v1');
      await prefs.remove('kpital_inventory_products_v1');
      await prefs.remove('kpital_inventory_sales_v1');
    } catch (_) {
      // La sesión se administra en memoria aunque el almacenamiento no exista.
    }
  }

  Future<bool> login({required String identifier, required String password}) =>
      _startSession('login', {'identifier': identifier, 'password': password});

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String currency,
  }) => _startSession('register', {
    'full_name': fullName, 'email': email, 'phone_number': phoneNumber,
    'password': password, 'currency': currency,
  });

  Future<bool> _startSession(String path, Map<String, String> body) async {
    final response = await _post(path, body);
    if (response == null) return false;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      if (token.isEmpty) throw const FormatException();
      _token = token;
      _currentUser = user;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
      } catch (_) {}
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Kpital recibió una respuesta inesperada.';
      return false;
    }
  }

  Future<void> logout() async {
    final token = _token;
    _token = null;
    _currentUser = _guest;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
    notifyListeners();
    if (token != null) await _post('logout', {}, token: token);
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    final token = _token;
    if (token == null) return false;
    return await _post('password', {
      'current_password': currentPassword, 'new_password': newPassword,
    }, token: token) != null;
  }

  Future<http.Response?> _post(
    String path, Map<String, String> body, {String? token}
  ) async {
    errorMessage = null;
    try {
      final response = await http.post(
        Uri.parse('$_backend/api/auth/$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));
      if (response.statusCode >= 200 && response.statusCode < 300) return response;
      final data = jsonDecode(response.body);
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      errorMessage = detail is String ? detail : 'Revisa los datos ingresados.';
    } catch (_) {
      errorMessage = 'No se pudo conectar con Kpital. Intenta de nuevo.';
    }
    return null;
  }
}
