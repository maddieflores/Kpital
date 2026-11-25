import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class LivePreviewCard extends StatelessWidget {
  final VisualIdentity identity;
  final Color scaffoldBg;
  final Gradient? gradient;
  final bool isDark;

  const LivePreviewCard({
    super.key,
    required this.identity,
    required this.scaffoldBg,
    this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? (identity.isDefaultDark ? identity.defaultCardBg : const Color(0xFF23272F))
        : identity.defaultCardBg;

    final textPrimary = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final user = authProv.currentUser;
    final initials = user.initials;
    final greetingName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim().split(RegExp(r'\s+')).first
        : (user.username.trim().isNotEmpty && user.username != 'invitado'
            ? user.username
            : 'Usuario');

    return Container(
      decoration: BoxDecoration(
        color: scaffoldBg,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Mockup
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.06),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hola, $greetingName",
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      "Tu dinero, en calma.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.settings_outlined, size: 20, color: textSecondary),
            ],
          ),
          const SizedBox(height: 14),

          // Tarjeta de Saldo Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: identity.balanceCardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: identity.balanceCardColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Saldo total disponible",
                      style: TextStyle(
                        fontSize: 12,
                        color: identity.balanceCardTextColor.withOpacity(0.85),
                      ),
                    ),
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: identity.balanceCardTextColor.withOpacity(0.85),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Bs 24.680,50",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: identity.balanceCardTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: identity.balanceCardTextColor.withOpacity(0.15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.arrow_downward, size: 12, color: identity.balanceCardTextColor.withOpacity(0.8)),
                              const SizedBox(width: 4),
                              Text("Ingresos", style: TextStyle(fontSize: 11, color: identity.balanceCardTextColor.withOpacity(0.8))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text("Bs 8.500,00", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: identity.balanceCardTextColor)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 12, color: identity.balanceCardTextColor.withOpacity(0.8)),
                              const SizedBox(width: 4),
                              Text("Gastos", style: TextStyle(fontSize: 11, color: identity.balanceCardTextColor.withOpacity(0.8))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text("Bs 3.240,00", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: identity.balanceCardTextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tarjeta de Movimientos & Mini-gráfico
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Movimientos", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
                    Text("Este mes ▾", style: TextStyle(fontSize: 11, color: textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: identity.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text("Ingresos", style: TextStyle(fontSize: 10, color: textSecondary)),
                    const SizedBox(width: 10),
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFFC07040), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text("Gastos", style: TextStyle(fontSize: 10, color: textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                // Onda estilizada del gráfico
                SizedBox(
                  height: 38,
                  child: CustomPaint(
                    painter: _WaveChartPainter(
                      primaryColor: identity.primary,
                      secondaryColor: const Color(0xFFC07040),
                    ),
                    size: const Size(double.infinity, 38),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Metas de Ahorro
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.track_changes, size: 14, color: identity.primary),
                        const SizedBox(width: 6),
                        Text("Metas de ahorro", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
                      ],
                    ),
                    Text("65%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Mi próximo viaje", style: TextStyle(fontSize: 12, color: textPrimary)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(identity.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Bs 3.250 de Bs 5.000", style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveChartPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _WaveChartPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.8);
    for (double x = 0; x <= size.width; x += 10) {
      final y = (size.height * 0.5) - (size.height * 0.3) * (x / size.width) + 4 * (x % 20 == 0 ? -1 : 1);
      path1.lineTo(x, y.clamp(4.0, size.height - 4.0));
    }
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = secondaryColor.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.9);
    for (double x = 0; x <= size.width; x += 12) {
      final y = (size.height * 0.7) - (size.height * 0.2) * (x / size.width) + 3 * (x % 24 == 0 ? -1 : 1);
      path2.lineTo(x, y.clamp(10.0, size.height - 2.0));
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WaveChartPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor;
  }
}
