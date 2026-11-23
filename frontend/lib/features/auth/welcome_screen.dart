import 'package:flutter/material.dart';
import '../../core/widgets/kpital_logo.dart';
import '../onboarding/widgets/onboarding_illustrations.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../main.dart';

/// Pantalla 3: Bienvenida a Kpital
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToDashboardDemo(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Encabezado de marca Kpital.
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    KpitalWordmark(fontSize: 26),
                    SizedBox(height: 4),
                    Text(
                      'Tu capital, en calma.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8261B8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ilustración de tarjetas Kpital y tranquilidad
              const Center(
                child: FinanceControlIllustration(size: 260),
              ),

              const SizedBox(height: 28),

              // Título y propuesta de valor
              const Text(
                'Bienvenido a Kpital',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Color(0xFF1E1A29),
                ),
              ),
              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Organiza tu dinero y haz crecer tu negocio con tranquilidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Color(0xFF6E6879),
                  ),
                ),
              ),

              const SizedBox(height: 34),

              // Botón 1: Iniciar sesión (Principal)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _goToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8261B8),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(0xFF8261B8).withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Botón 2: Crear cuenta (Secundario outline)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => _goToRegister(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8261B8),
                    side: const BorderSide(
                      color: Color(0xFF8261B8),
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Crear cuenta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8261B8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Enlace modo demo
              TextButton(
                onPressed: () => _goToDashboardDemo(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8261B8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Explorar modo demo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8261B8),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: Color(0xFF8261B8)),
                  ],
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
