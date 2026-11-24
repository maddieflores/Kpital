import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/kpital_logo.dart';
import '../ads/providers/ads_provider.dart';
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
  final _emailPhoneController = TextEditingController(text: 'maddie');
  final _passwordController = TextEditingController(text: 'Maddie2026*');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  Future<void> _submitLogin() async {
    final identifier = _emailPhoneController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu usuario, correo o teléfono.'),
          backgroundColor: Color(0xFF8261B8),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);

    await authProvider.login(identifier: identifier, password: password);

    // Si es la cuenta Owner, habilitar Modo Creador
    if (authProvider.isOwner) {
      await adsProvider.setCreatorMode(true);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    final name = authProvider.currentUser.fullName;
    final isOwner = authProvider.isOwner;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF8261B8),
        content: Row(
          children: [
            Icon(
              isOwner ? Icons.workspace_premium : Icons.check_circle_outline,
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

  void _goToDemo() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  void _showRecoveryBottomSheet(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String selectedMethod = 'email'; // 'email' o 'phone'
    final codeController = TextEditingController();
    bool codeSent = false;
    String generatedCode = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final targetEmail = authProvider.currentUser.email.isNotEmpty
                ? authProvider.currentUser.email
                : 'addelynie@gmail.com';
            final targetPhone = authProvider.currentUser.phoneNumber.isNotEmpty
                ? authProvider.currentUser.phoneNumber
                : '+591 69069393';

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8261B8).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_reset, color: Color(0xFF8261B8)),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recuperar Cuenta',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1A29),
                              ),
                            ),
                            Text(
                              'Envío seguro de código de verificación',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!codeSent) ...[
                    const Text(
                      '¿Por dónde deseas recibir tu código de acceso?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: selectedMethod == 'email'
                              ? const Color(0xFF8261B8)
                              : Colors.grey.shade300,
                          width: selectedMethod == 'email' ? 2 : 1,
                        ),
                      ),
                      leading: const Icon(Icons.mail_outline, color: Color(0xFF8261B8)),
                      title: const Text('Correo electrónico (Real)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(targetEmail, style: const TextStyle(color: Color(0xFF8261B8))),
                      trailing: Radio<String>(
                        value: 'email',
                        groupValue: selectedMethod,
                        activeColor: const Color(0xFF8261B8),
                        onChanged: (v) => setModalState(() => selectedMethod = v!),
                      ),
                      onTap: () => setModalState(() => selectedMethod = 'email'),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: selectedMethod == 'phone'
                              ? const Color(0xFF8261B8)
                              : Colors.grey.shade300,
                          width: selectedMethod == 'phone' ? 2 : 1,
                        ),
                      ),
                      leading: const Icon(Icons.sms_outlined, color: Color(0xFF8261B8)),
                      title: const Text('SMS / WhatsApp (Real)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(targetPhone, style: const TextStyle(color: Color(0xFF8261B8))),
                      trailing: Radio<String>(
                        value: 'phone',
                        groupValue: selectedMethod,
                        activeColor: const Color(0xFF8261B8),
                        onChanged: (v) => setModalState(() => selectedMethod = v!),
                      ),
                      onTap: () => setModalState(() => selectedMethod = 'phone'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8261B8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          generatedCode = authProvider.generateRecoveryCode();
                          setModalState(() => codeSent = true);
                          // Enviar código vía Resend/SMTP, WhatsApp Cloud API o Notificación Local
                          await NotificationService().sendRecoveryCode(
                            channel: selectedMethod == 'email' ? 'email' : 'whatsapp',
                            target: selectedMethod == 'email' ? targetEmail : targetPhone,
                            userName: authProvider.currentUser.fullName,
                          );
                        },
                        child: const Text('Enviar Código de Verificación', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8261B8).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF8261B8).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mark_email_read, color: Color(0xFF8261B8), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedMethod == 'email'
                                      ? 'Código enviado a $targetEmail'
                                      : 'Código enviado por SMS a $targetPhone',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tu código de un solo uso es: $generatedCode (válido por 10 min)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8261B8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Ingresa el código de 6 dígitos:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFFAFAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8261B8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          if (authProvider.verifyRecoveryCode(codeController.text)) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF10B981),
                                content: Text('¡Código verificado con éxito! Tu contraseña actual es: Maddie2026*'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text('Código incorrecto. Vuelve a intentarlo.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Validar y Restablecer', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
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

              // Campo: Usuario, correo o teléfono
              const Text(
                'Usuario, correo o teléfono',
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
                  hintText: 'maddie o addelynie@gmail.com',
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

              const SizedBox(height: 14),

              // Fila: Recordarme y ¿Olvidaste tu contraseña?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: const BorderSide(color: Color(0xFFB0A9BB)),
                          onChanged: (val) {
                            setState(() => _rememberMe = val ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recordarme',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A4458),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _showRecoveryBottomSheet(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

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

              const SizedBox(height: 14),

              // Modo demo
              Center(
                child: TextButton(
                  onPressed: _goToDemo,
                  child: const Text(
                    'Explorar modo demo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryPurple,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

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
