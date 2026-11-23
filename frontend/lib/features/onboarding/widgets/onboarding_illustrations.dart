import 'package:flutter/material.dart';

/// Ilustración 1: Control Financiero (Billetera digital y tarjetas Kpital)
class FinanceControlIllustration extends StatelessWidget {
  final double size;

  const FinanceControlIllustration({super.key, this.size = 280});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Círculos concéntricos de fondo
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8261B8).withOpacity(0.12),
                width: 1.2,
              ),
              color: const Color(0xFFF7F4FB),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8261B8).withOpacity(0.08),
                width: 1,
              ),
            ),
          ),

          // 2. Tarjeta trasera (lila suave)
          Positioned(
            top: size * 0.16,
            left: size * 0.15,
            child: Transform.rotate(
              angle: -0.06,
              child: Container(
                width: size * 0.65,
                height: size * 0.42,
                decoration: BoxDecoration(
                  color: const Color(0xFFC7B5E2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8261B8).withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Tarjeta frontal Kpital principal (Violeta Premium)
          Positioned(
            top: size * 0.24,
            left: size * 0.18,
            child: Container(
              width: size * 0.68,
              height: size * 0.44,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF906EC7),
                    Color(0xFF8261B8),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8261B8).withOpacity(0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Marca en la tarjeta
                  const Text(
                    'Kpital',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Líneas de tarjeta / chip
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 38,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      // Chip circular
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Badge flotante: "Todo en su lugar. Más tranquilidad"
          Positioned(
            bottom: size * 0.16,
            right: size * 0.08,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 15,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Todo en su lugar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6E6879),
                        ),
                      ),
                      Text(
                        'Más tranquilidad',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1A29),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Elementos decorativos (cruz + y punto)
          Positioned(
            left: size * 0.12,
            bottom: size * 0.22,
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF8261B8).withOpacity(0.6),
              ),
            ),
          ),
          Positioned(
            top: size * 0.20,
            right: size * 0.16,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF8261B8).withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ilustración 2: Ahorro Protegido (Bóveda con candado y progreso 68%)
class ProtectedSavingsIllustration extends StatelessWidget {
  final double size;

  const ProtectedSavingsIllustration({super.key, this.size = 280});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Círculos concéntricos de fondo
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8261B8).withOpacity(0.12),
                width: 1.2,
              ),
              color: const Color(0xFFF7F4FB),
            ),
          ),

          // 2. Caja fuerte / bóveda con candado
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9472CC),
                  Color(0xFF8261B8),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8261B8).withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: size * 0.38,
                height: size * 0.38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.45),
                    width: 3.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: size * 0.22,
                    height: size * 0.22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Badge flotante: "Tu próxima meta · 68%" con barra de progreso
          Positioned(
            bottom: size * 0.16,
            left: size * 0.20,
            right: size * 0.10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Color(0xFF1E1A29),
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(text: 'Tu próxima meta '),
                        TextSpan(
                          text: '· 68%',
                          style: TextStyle(
                            color: Color(0xFF8261B8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 7,
                      width: double.infinity,
                      color: const Color(0xFFECE6F6),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.68,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF9E7FD1),
                                Color(0xFF8261B8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Elementos decorativos
          Positioned(
            left: size * 0.12,
            bottom: size * 0.32,
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF8261B8).withOpacity(0.6),
              ),
            ),
          ),
          Positioned(
            top: size * 0.18,
            right: size * 0.16,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF8261B8).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ilustración 3: Negocio Inteligente (Gráfica de barras ascendentes y badge)
class SmartBusinessIllustration extends StatelessWidget {
  final double size;

  const SmartBusinessIllustration({super.key, this.size = 280});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Círculos concéntricos de fondo
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8261B8).withOpacity(0.12),
                width: 1.2,
              ),
              color: const Color(0xFFF7F4FB),
            ),
          ),

          // 2. Tarjeta blanca con gráfica de barras
          Container(
            width: size * 0.68,
            height: size * 0.66,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8261B8).withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: ícono de tienda y badge "Tu negocio"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 22,
                      color: Color(0xFF4A4458),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EBF9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Tu negocio',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8261B8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Gráfico de barras ascendentes (crecimiento)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBar(height: 38, color: const Color(0xFFD6C6EE)),
                      _buildBar(height: 56, color: const Color(0xFFC7B1E6)),
                      _buildBar(height: 48, color: const Color(0xFFB398DC)),
                      _buildBar(height: 72, color: const Color(0xFF9E7FD1)),
                      _buildBar(height: 92, color: const Color(0xFF8261B8)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Texto inspirador del negocio
                const Text(
                  'Pequeños pasos. Grandes logros.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A5368),
                  ),
                ),
              ],
            ),
          ),

          // 3. Decoraciones
          Positioned(
            left: size * 0.10,
            bottom: size * 0.26,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF8261B8).withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.12,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFF8261B8).withOpacity(0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({required double height, required Color color}) {
    return Container(
      width: 18,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
