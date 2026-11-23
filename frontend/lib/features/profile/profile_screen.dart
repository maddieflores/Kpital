import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../ads/providers/ads_provider.dart';
import '../appearance/screens/appearance_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final adsProv = Provider.of<AdsProvider>(context);
    final tokens = context.tokens;
    final currentIdentity = themeProvider.currentIdentity;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil y Ajustes"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tarjeta de Perfil Superior
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: currentIdentity.primary.withOpacity(0.15),
                  child: Text(
                    "AV",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: currentIdentity.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Alejandro Valenzuela",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "alejandro.v@ejemplo.com",
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: currentIdentity.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Plan Personal Pro",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: currentIdentity.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN 1: PERSONALIZACIÓN VISUAL (Destacada)
          Text(
            "ESTILO Y PERSONALIZACIÓN",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentIdentity.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.palette_outlined, color: currentIdentity.primary),
                  ),
                  title: const Text("Identidad visual & Fondos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(
                    "${currentIdentity.name} • ${themeProvider.bgType == 'default' ? 'Fondo original' : 'Fondo personalizado'}",
                    style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppearanceScreen(initialTabIndex: 2),
                      ),
                    );
                  },
                ),
                Divider(height: 1, indent: 64, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentIdentity.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.view_carousel_outlined, color: currentIdentity.primary),
                  ),
                  title: const Text("Explorar propuestas de Figma", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("Azul, Violeta, Minimalista y Oscuro", style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppearanceScreen(initialTabIndex: 0),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN 2: PREFERENCIAS FINANCIERAS
          Text(
            "PREFERENCIAS FINANCIERAS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.monetization_on_outlined),
                  title: const Text("Moneda principal"),
                  trailing: const Text("Bolivianos (Bs)", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Divider(height: 1, indent: 56, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text("Seguridad y Acceso"),
                  subtitle: const Text("Bloqueo biométrico activo"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN 3: MODO CREADOR Y PUBLICIDAD (CU-7.3)
          Text(
            "MONETIZACIÓN Y MODO CREADOR",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.amber),
                  ),
                  title: const Text(
                    "Modo Creador (Owner)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    adsProv.isCreatorMode
                        ? "Desactivación total de anuncios activa (Bypasses ilimitados)"
                        : "Modo Usuario Regular activo (Muestra Banners y Rewarded Ad)",
                    style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                  ),
                  activeColor: Colors.amber,
                  value: adsProv.isCreatorMode,
                  onChanged: (val) {
                    adsProv.setCreatorMode(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: val ? const Color(0xFF10B981) : Colors.blueGrey,
                        content: Text(
                          val
                              ? "¡Modo Creador activado! Todos los anuncios han sido eliminados."
                              : "Modo usuario regular activado para pruebas de AdMob.",
                        ),
                      ),
                    );
                  },
                ),
                Divider(height: 1, indent: 64, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentIdentity.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.ads_click, color: currentIdentity.primary),
                  ),
                  title: const Text("Google AdMob Network", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    "App ID: ${adsProv.adMobAppId.substring(0, 15)}... • Modo Test Oficial",
                    style: TextStyle(color: tokens.textSecondary, fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Conectado', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Footer de la app
          Center(
            child: Column(
              children: [
                Text(
                  "nivo.",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tu dinero, en calma • Finanzas en equilibrio",
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "Versión 1.0.0",
                  style: TextStyle(color: tokens.textSecondary.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
