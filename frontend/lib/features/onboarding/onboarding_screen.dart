import 'package:flutter/material.dart';
import '../../core/widgets/kpital_logo.dart';
import '../auth/welcome_screen.dart';
import 'widgets/onboarding_illustrations.dart';

/// Modelo de datos para las diapositivas de Onboarding
class OnboardingSlide {
  final String category;
  final String title;
  final String description;
  final Widget illustration;
  final String buttonText;

  const OnboardingSlide({
    required this.category,
    required this.title,
    required this.description,
    required this.illustration,
    this.buttonText = 'Continuar',
  });
}

/// Pantalla 2: Onboarding (3 diapositivas interactivas)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      category: 'CONTROL FINANCIERO',
      title: 'Tu capital,\nen calma.',
      description:
          'Organiza tus ingresos, gastos y cuentas desde un solo lugar.',
      illustration: FinanceControlIllustration(),
      buttonText: 'Continuar',
    ),
    OnboardingSlide(
      category: 'AHORRO PROTEGIDO',
      title: 'Ahorra con\ntranquilidad.',
      description:
          'Separa tu dinero y avanza hacia tus metas financieras.',
      illustration: ProtectedSavingsIllustration(),
      buttonText: 'Continuar',
    ),
    OnboardingSlide(
      category: 'NEGOCIO INTELIGENTE',
      title: 'Tu negocio,\nmás inteligente.',
      description:
          'Calcula precios, controla ganancias y toma mejores decisiones.',
      illustration: SmartBusinessIllustration(),
      buttonText: 'Comenzar',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToWelcome();
    }
  }

  void _goToWelcome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KpitalAppBar(
        showBackButton: false,
        onSkip: _goToWelcome,
        skipText: 'Saltar',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenido deslizable
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Ilustración central
                        Center(child: slide.illustration),

                        const SizedBox(height: 24),

                        // Categoría en mayúsculas lila
                        Text(
                          slide.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: Color(0xFF8261B8),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Título de la diapositiva
                        Text(
                          slide.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.15,
                            color: Color(0xFF1E1A29),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Descripción
                        Text(
                          slide.description,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF6E6879),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Controles inferiores: Indicadores y Botón de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                children: [
                  // Indicador de páginas (Pill + dots)
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 5,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF8261B8)
                              : const Color(0xFF8261B8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón principal: "Continuar >" o "Comenzar >"
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8261B8),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF8261B8).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _slides[_currentPage].buttonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtítulo de tranquilidad al pie
                  const Text(
                    'Tu tranquilidad es un buen comienzo.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8F889B),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
