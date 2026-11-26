import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/biometric_service.dart';
import '../../core/widgets/kpital_logo.dart';
import 'providers/auth_provider.dart';
import 'register_screen.dart';
import '../../main.dart';

/// Pantalla 4A: Login / Iniciar sesión
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndBiometrics();
  }

  Future<void> _loadPreferencesAndBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('kpital_saved_identifier_v2');
      final remember = prefs.getBool('kpital_remember_session_v2') ?? true;
      if (savedId != null && savedId.isNotEmpty) {
        _emailPhoneController.text = savedId;
      }
      if (mounted) {
        setState(() {
          _rememberMe = remember;
        });
      }

      if (BiometricAuthService.isPlatformSupported) {
        final available = await BiometricAuthService.isBiometricAvailable();
        final credentials = await BiometricAuthService.getSavedCredentials();
        if (mounted) {
          setState(() {
            _canUseBiometrics = available && credentials != null;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loginWithBiometrics() async {
    final credentials = await BiometricAuthService.getSavedCredentials();
    if (credentials == null) return;

    final authenticated = await BiometricAuthService.authenticate(
      reason: 'Usa tu huella para entrar a Kpital',
    );

    if (!authenticated || !mounted) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      identifier: credentials['identifier']!,
      password: credentials['password']!,
      rememberMe: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'No se pudo iniciar sesión con huella.'),
        ),
      );
      return;
    }

    _showWelcomeAndNavigate(authProvider, isBiometric: true);
  }

  Future<void> _submitLogin() async {
    final identifier = _emailPhoneController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu usuario o correo, y tu contraseña.'),
          backgroundColor: Color(0xFF8261B8),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      identifier: identifier,
      password: password,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'No se pudo iniciar sesión.')),
      );
      return;
    }

    // Si recordar está activo y estamos en móvil, guardar para huella
    if (_rememberMe && BiometricAuthService.isPlatformSupported) {
      await BiometricAuthService.saveBiometricCredentials(
        identifier: identifier,
        password: password,
      );
    } else {
      await BiometricAuthService.clearBiometricCredentials();
    }

    _showWelcomeAndNavigate(authProvider);
  }

  void _showWelcomeAndNavigate(AuthProvider authProvider, {bool isBiometric = false}) {
    final name = authProvider.currentUser.fullName;
    final isOwner = authProvider.isOwner;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF8261B8),
        content: Row(
          children: [
            Icon(
              isBiometric
                  ? Icons.fingerprint
                  : (isOwner ? Icons.workspace_premium : Icons.check_circle_outline),
              color: isOwner ? Colors.amber : Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isOwner
                    ? '¡Bienvenida, $name! Sesión Owner iniciada.'
                    : '¡Bienvenido/a, $name!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    // Navegar directamente al Dashboard
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF8261B8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KpitalAppBar(
        showBackButton: true,
        showWordmark: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Título y bienvenida
              const Text(
                'Bienvenido de nuevo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Color(0xFF1E1A29),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa para continuar con tus finanzas',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6E6879),
                ),
              ),

              const SizedBox(height: 28),

              // Campo: Usuario o correo
              const Text(
                'Usuario o correo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1A29),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailPhoneController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'ejemplo@correo.com',
                  hintStyle: const TextStyle(color: Color(0xFFB0A9BB)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E0EC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E0EC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: primaryPurple, width: 1.8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Campo: Contraseña
              const Text(
                'Contraseña',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1A29),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Ingresa tu contraseña',
                  hintStyle: const TextStyle(color: Color(0xFFB0A9BB)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E0EC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E0EC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: primaryPurple, width: 1.8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF8261B8),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Opción de tickeo: Recordar sesión / Mantener sesión activa
              InkWell(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: (val) {
                            setState(() => _rememberMe = val ?? true);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Mantener sesión iniciada (Recordar)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1A29),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón Iniciar sesión
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: primaryPurple.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              // Botón de huella dactilar (solo disponible en celular con credenciales recordadas)
              if (_canUseBiometrics) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithBiometrics,
                    icon: const Icon(Icons.fingerprint, color: primaryPurple, size: 26),
                    label: const Text(
                      'Ingresar con huella digital',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryPurple,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryPurple, width: 1.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Separador "o continúa a tu ritmo"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'o continúa a tu ritmo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                ],
              ),

              const SizedBox(height: 20),

              // Enlace: ¿No tienes cuenta? Regístrate
              Center(
                child: GestureDetector(
                  onTap: _goToRegister,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4A4458),
                      ),
                      children: [
                        TextSpan(text: '¿No tienes cuenta? '),
                        TextSpan(
                          text: 'Regístrate',
                          style: TextStyle(
                            color: primaryPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subtítulo de aviso
              Center(
                child: Text(
                  'Kpital · Tu capital, en calma.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
