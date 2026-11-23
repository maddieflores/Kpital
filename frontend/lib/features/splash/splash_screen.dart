import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/widgets/kpital_logo.dart';
import '../onboarding/onboarding_screen.dart';

/// Pantalla 1: Splash Screen
/// Incorpora el logo oficial "K Ascendente" en squircle Violeta Premium #8261B8
/// seguido de la tipografía de marca Kpital. y el lema "Tu capital, en calma."
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    );

    _animController.forward();

    // Auto-transición a Onboarding después de 2.4 segundos
    _navigationTimer = Timer(const Duration(milliseconds: 2400), () {
      _goToOnboarding();
    });
  }

  void _goToOnboarding() {
    if (!mounted) return;
    _navigationTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goToOnboarding,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Resplandor de fondo muy sutil violeta
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8261B8).withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // Logo Kpital oficial "K Ascendente" en squircle Violeta Premium
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: const KpitalLogoIcon(
                          size: 96,
                          backgroundColor: Color(0xFF8261B8),
                          hasShadow: true,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Tipografía de marca "Kpital."
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: const [
                            KpitalWordmark(
                              fontSize: 38,
                              textColor: Color(0xFF1E1A29),
                              dotColor: Color(0xFF8261B8),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tu capital, en calma.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8261B8),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 4),

                      // Barra de navegación inferior decorativa / indicador sutil
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 3,
                              child: LinearProgressIndicator(
                                backgroundColor:
                                    const Color(0xFF8261B8).withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF8261B8),
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 134,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1A29).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
