import 'package:flutter/material.dart';

/// Identidades visuales del sistema de diseño (Figma Make)
enum VisualIdentityType {
  azulTecnologico,     // Estándar por defecto
  violetaPremium,
  minimalistaClaro,
  oscuroElegante,
  petroleoSereno,
  terracotaEditorial,
  aceroContemporaneo,
  olivaEsencial,
}

/// Definición completa de una identidad visual
class VisualIdentity {
  final VisualIdentityType type;
  final String id;
  final String name;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final Color defaultScaffoldBg;
  final Color defaultCardBg;
  final Color balanceCardColor;
  final Color balanceCardTextColor;
  final bool isDefaultDark;

  const VisualIdentity({
    required this.type,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.defaultScaffoldBg,
    required this.defaultCardBg,
    required this.balanceCardColor,
    required this.balanceCardTextColor,
    this.isDefaultDark = false,
  });
}

/// Catálogo de las identidades visuales según Figma
class AppVisualIdentities {
  // 1. AZUL TECNOLÓGICO (Estándar por defecto)
  static const azulTecnologico = VisualIdentity(
    type: VisualIdentityType.azulTecnologico,
    id: 'azul_tecnologico',
    name: 'Azul tecnológico',
    subtitle: 'AZUL ZAFIRO',
    primary: Color(0xFF3366D6),
    secondary: Color(0xFF1E40AF),
    defaultScaffoldBg: Color(0xFFF0F4FA),
    defaultCardBg: Colors.white,
    balanceCardColor: Color(0xFF3366D6),
    balanceCardTextColor: Colors.white,
    isDefaultDark: false,
  );

  // 2. VIOLETA PREMIUM
  static const violetaPremium = VisualIdentity(
    type: VisualIdentityType.violetaPremium,
    id: 'violeta_premium',
    name: 'Violeta premium',
    subtitle: 'VIOLETA SOFISTICADO',
    primary: Color(0xFF8261B8),
    secondary: Color(0xFF5B3D8A),
    defaultScaffoldBg: Color(0xFFF7F5FA),
    defaultCardBg: Colors.white,
    balanceCardColor: Color(0xFF8261B8),
    balanceCardTextColor: Colors.white,
    isDefaultDark: false,
  );

  // 3. MINIMALISTA CLARO
  static const minimalistaClaro = VisualIdentity(
    type: VisualIdentityType.minimalistaClaro,
    id: 'minimalista_claro',
    name: 'Minimalista claro',
    subtitle: 'VERDE PETRÓLEO',
    primary: Color(0xFF367B70),
    secondary: Color(0xFF204F55),
    defaultScaffoldBg: Color(0xFFF4F6F4),
    defaultCardBg: Colors.white,
    balanceCardColor: Color(0xFF367B70),
    balanceCardTextColor: Colors.white,
    isDefaultDark: false,
  );

  // 4. OSCURO ELEGANTE CON DORADO
  static const oscuroElegante = VisualIdentity(
    type: VisualIdentityType.oscuroElegante,
    id: 'oscuro_elegante',
    name: 'Oscuro elegante',
    subtitle: 'DORADO CHAMPAGNE',
    primary: Color(0xFFCBB58B),
    secondary: Color(0xFFA38E65),
    defaultScaffoldBg: Color(0xFF1E2022),
    defaultCardBg: Color(0xFF2C2E31),
    balanceCardColor: Color(0xFFCBB58B),
    balanceCardTextColor: Color(0xFF1E2022),
    isDefaultDark: true,
  );

  // 5. PETRÓLEO SERENO
  static const petroleoSereno = VisualIdentity(
    type: VisualIdentityType.petroleoSereno,
    id: 'petroleo_sereno',
    name: 'Petróleo sereno',
    subtitle: 'TRANQUILIDAD Y ORGANIZACIÓN',
    primary: Color(0xFF277B80),
    secondary: Color(0xFF204F55),
    defaultScaffoldBg: Color(0xFFEEF5F3),
    defaultCardBg: Colors.white,
    balanceCardColor: Color(0xFF277B80),
    balanceCardTextColor: Colors.white,
    isDefaultDark: false,
  );

  // 6. TERRACOTA EDITORIAL
  static const terracotaEditorial = VisualIdentity(
    type: VisualIdentityType.terracotaEditorial,
    id: 'terracota_editorial',
    name: 'Terracota editorial',
    subtitle: 'MODERNIDAD CON PERSONALIDAD',
    primary: Color(0xFFA85E49),
    secondary: Color(0xFF653E35),
    defaultScaffoldBg: Color(0xFFF7F1EB),
    defaultCardBg: Color(0xFFFFFCF8),
    balanceCardColor: Color(0xFFA85E49),
    balanceCardTextColor: Colors.white,
    isDefaultDark: false,
  );

  // 7. ACERO CONTEMPORÁNEO
  static const aceroContemporaneo = VisualIdentity(
    type: VisualIdentityType.aceroContemporaneo,
    id: 'acero_contemporaneo',
    name: 'Acero contemporáneo',
    subtitle: 'CONFIANZA Y TECNOLOGÍA',
    primary: Color(0xFF53738E),
    secondary: Color(0xFF2F465C),
    defaultScaffoldBg: Color(0xFFF0F3F6),
    defaultCardBg: Colors.white,
    balanceCardColor: Color(0xFF53738E),
    balanceCardTextColor: Colors.white,
    isDefaultDark: false,
  );

  // 8. OLIVA ESENCIAL
  static const olivaEsencial = VisualIdentity(
    type: VisualIdentityType.olivaEsencial,
    id: 'oliva_esencial',
    name: 'Oliva esencial',
    subtitle: 'ELEGANCIA EN EQUILIBRIO',
    primary: Color(0xFF6C7650),
    secondary: Color(0xFF424C32),
    defaultScaffoldBg: Color(0xFFF4F4EC),
    defaultCardBg: Colors.white,
    balanceCardColor: Color(0xFF6C7650),
    balanceCardTextColor: Colors.white,
    isDefaultDark: false,
  );

  static const List<VisualIdentity> all = [
    azulTecnologico,
    violetaPremium,
    minimalistaClaro,
    oscuroElegante,
    petroleoSereno,
    terracotaEditorial,
    aceroContemporaneo,
    olivaEsencial,
  ];

  static VisualIdentity fromId(String id) {
    return all.firstWhere((i) => i.id == id, orElse: () => azulTecnologico);
  }
}

/// Swatches de Fondos Independientes
class BackgroundPreset {
  final String id;
  final String name;
  final Color color;

  const BackgroundPreset({
    required this.id,
    required this.name,
    required this.color,
  });
}

class AppBackgroundPresets {
  static const azulMedianoche = BackgroundPreset(id: 'azul_medianoche', name: 'Azul medianoche', color: Color(0xFF17283F));
  static const grisGrafito    = BackgroundPreset(id: 'gris_grafito',    name: 'Gris grafito',    color: Color(0xFF292D30));
  static const violetaNocturno = BackgroundPreset(id: 'violeta_nocturno', name: 'Violeta nocturno', color: Color(0xFF30283F));
  static const verdePetroleo  = BackgroundPreset(id: 'verde_petroleo',  name: 'Verde petróleo',  color: Color(0xFF163E3C));
  static const blancoPerla    = BackgroundPreset(id: 'blanco_perla',    name: 'Blanco perla',    color: Color(0xFFF5F5F1));
  static const arenaCalida    = BackgroundPreset(id: 'arena_calida',    name: 'Arena cálida',    color: Color(0xFFEDE3D4));
  static const cafeMoca       = BackgroundPreset(id: 'cafe_moca',       name: 'Café moca',       color: Color(0xFF4A3933));
  static const grisAzulado    = BackgroundPreset(id: 'gris_azulado',    name: 'Gris azulado',    color: Color(0xFFDCE4EB));

  static const List<BackgroundPreset> all = [
    azulMedianoche,
    grisGrafito,
    violetaNocturno,
    verdePetroleo,
    blancoPerla,
    arenaCalida,
    cafeMoca,
    grisAzulado,
  ];

  static BackgroundPreset? fromId(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Degradados Elegantes
class GradientPreset {
  final String id;
  final String name;
  final List<Color> colors;

  const GradientPreset({
    required this.id,
    required this.name,
    required this.colors,
  });

  LinearGradient get gradient => LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppGradientPresets {
  static const nocheOceanica = GradientPreset(
    id: 'noche_oceanica',
    name: 'Noche oceánica',
    colors: [Color(0xFF1A3548), Color(0xFF1D4851)],
  );

  static const violetaMineral = GradientPreset(
    id: 'violeta_mineral',
    name: 'Violeta mineral',
    colors: [Color(0xFF322A41), Color(0xFF24222E)],
  );

  static const champagneSuave = GradientPreset(
    id: 'champagne_suave',
    name: 'Champagne suave',
    colors: [Color(0xFFE7D6BA), Color(0xFFEDE2D0)],
  );

  static const brisaInvierno = GradientPreset(
    id: 'brisa_invierno',
    name: 'Brisa de invierno',
    colors: [Color(0xFFE6EBEF), Color(0xFFDFE9F2)],
  );

  static const List<GradientPreset> all = [
    nocheOceanica,
    violetaMineral,
    champagneSuave,
    brisaInvierno,
  ];

  static GradientPreset? fromId(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
