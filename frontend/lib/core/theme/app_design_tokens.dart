import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension de tema que entrega tokens de diseño de Figma a cualquier widget
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  final VisualIdentity identity;
  final Color scaffoldBg;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color balanceCardBg;
  final Color balanceCardText;
  final Gradient? backgroundGradient;
  final bool isDark;

  const AppDesignTokens({
    required this.identity,
    required this.scaffoldBg,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.balanceCardBg,
    required this.balanceCardText,
    this.backgroundGradient,
    required this.isDark,
  });

  @override
  AppDesignTokens copyWith({
    VisualIdentity? identity,
    Color? scaffoldBg,
    Color? cardBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? balanceCardBg,
    Color? balanceCardText,
    Gradient? backgroundGradient,
    bool? isDark,
  }) {
    return AppDesignTokens(
      identity: identity ?? this.identity,
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardBg: cardBg ?? this.cardBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      balanceCardBg: balanceCardBg ?? this.balanceCardBg,
      balanceCardText: balanceCardText ?? this.balanceCardText,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  ThemeExtension<AppDesignTokens> lerp(
    covariant ThemeExtension<AppDesignTokens>? other,
    double t,
  ) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      identity: t < 0.5 ? identity : other.identity,
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t) ?? scaffoldBg,
      cardBg: Color.lerp(cardBg, other.cardBg, t) ?? cardBg,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      balanceCardBg: Color.lerp(balanceCardBg, other.balanceCardBg, t) ?? balanceCardBg,
      balanceCardText: Color.lerp(balanceCardText, other.balanceCardText, t) ?? balanceCardText,
      backgroundGradient: other.backgroundGradient,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }

  /// Atajo para acceder fácilmente desde el BuildContext: `context.tokens`
  static AppDesignTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<AppDesignTokens>();
    if (tokens != null) return tokens;
    // Fallback estándar en caso de no encontrarse
    return AppDesignTokens(
      identity: AppVisualIdentities.azulTecnologico,
      scaffoldBg: const Color(0xFFF0F4FA),
      cardBg: Colors.white,
      textPrimary: const Color(0xFF1A243A),
      textSecondary: const Color(0xFF6B7280),
      balanceCardBg: const Color(0xFF3366D6),
      balanceCardText: Colors.white,
      isDark: false,
    );
  }
}

extension AppThemeContextExtension on BuildContext {
  AppDesignTokens get tokens => AppDesignTokens.of(this);
}
