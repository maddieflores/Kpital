import 'package:flutter/material.dart';

/// Logotipo oficial de Kpital: "K Ascendente"
/// Trazo superior con vector de crecimiento financiero y fintech.
class KpitalLogoIcon extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color iconColor;
  final bool hasShadow;
  final bool isSquircle;

  const KpitalLogoIcon({
    super.key,
    this.size = 64,
    this.backgroundColor,
    this.iconColor = Colors.white,
    this.hasShadow = true,
    this.isSquircle = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF8261B8);

    if (!isSquircle) {
      return CustomPaint(
        size: Size(size, size),
        painter: _KAscendentePainter(iconColor: iconColor),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            const Color(0xFF6B4A9E),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: bgColor.withOpacity(0.35),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.12),
                ),
                BoxShadow(
                  color: bgColor.withOpacity(0.15),
                  blurRadius: size * 0.08,
                  offset: Offset(0, size * 0.04),
                ),
              ]
            : null,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.72, size * 0.72),
          painter: _KAscendentePainter(iconColor: iconColor),
        ),
      ),
    );
  }
}

/// Pintor vectorial personalizado para la "K Ascendente"
class _KAscendentePainter extends CustomPainter {
  final Color iconColor;

  _KAscendentePainter({required this.iconColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.155;

    final mainPaint = Paint()
      ..color = iconColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 1. Tallo vertical izquierdo
    final stemX = size.width * 0.28;
    final stemTop = size.height * 0.16;
    final stemBottom = size.height * 0.84;
    canvas.drawLine(
      Offset(stemX, stemTop),
      Offset(stemX, stemBottom),
      mainPaint,
    );

    // 2. Trazo diagonal inferior (estable, sólido)
    final junctionY = size.height * 0.52;
    final junctionX = stemX + (strokeWidth * 0.15);
    final bottomArmX = size.width * 0.76;
    final bottomArmY = size.height * 0.84;
    canvas.drawLine(
      Offset(junctionX, junctionY),
      Offset(bottomArmX, bottomArmY),
      mainPaint,
    );

    // 3. Trazo superior ascendente (vector de crecimiento)
    // Sube hacia la esquina superior derecha con inclinación dinámica
    final topArmStartX = junctionX + (strokeWidth * 0.1);
    final topArmStartY = junctionY - (strokeWidth * 0.15);
    final topArmEndX = size.width * 0.78;
    final topArmEndY = size.height * 0.18;

    canvas.drawLine(
      Offset(topArmStartX, topArmStartY),
      Offset(topArmEndX, topArmEndY),
      mainPaint,
    );

    // 4. Detalle de flecha / crecimiento en la punta ascendente
    // Un sutil relieve luminoso que enfatiza el crecimiento continuo
    final tipPointPaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(topArmEndX, topArmEndY),
      strokeWidth * 0.25,
      tipPointPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _KAscendentePainter oldDelegate) {
    return oldDelegate.iconColor != iconColor;
  }
}

/// Wordmark de marca: "Kpital."
class KpitalWordmark extends StatelessWidget {
  final double fontSize;
  final Color? textColor;
  final Color dotColor;
  final bool showDot;

  const KpitalWordmark({
    super.key,
    this.fontSize = 28,
    this.textColor,
    this.dotColor = const Color(0xFF8261B8),
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? const Color(0xFF1E1A29);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: color,
        ),
        children: [
          const TextSpan(text: 'Kpital'),
          if (showDot)
            TextSpan(
              text: '.',
              style: TextStyle(
                color: dotColor,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

/// Header con barra superior Kpital (Back opcional, Logo o Título, Acción opcional)
class KpitalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final String? skipText;
  final bool showWordmark;
  final bool showBackButton;

  const KpitalAppBar({
    super.key,
    this.onBack,
    this.onSkip,
    this.skipText = 'Saltar',
    this.showWordmark = true,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: const Color(0xFF1E1A29),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onBack ?? () => Navigator.maybePop(context),
              )
            else if (showWordmark)
              const KpitalWordmark(fontSize: 24)
            else
              const SizedBox.shrink(),

            const Spacer(),

            if (showBackButton && showWordmark)
              const KpitalWordmark(fontSize: 24),

            if (onSkip != null)
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8261B8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  skipText ?? 'Saltar',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
