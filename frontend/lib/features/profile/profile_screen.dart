import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../ads/providers/ads_provider.dart';
import '../appearance/screens/appearance_screen.dart';
import '../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showSecurityModal(BuildContext context, AuthProvider authProv) {
    final user = authProv.currentUser;
    final passCtrl = TextEditingController(text: authProv.ownerPassword);
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
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
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF8261B8)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Seguridad y Credenciales",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Cuenta Propietaria (Owner)",
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
                  const SizedBox(height: 18),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alternate_email, color: Color(0xFF8261B8)),
                    title: const Text("Usuario Owner"),
                    subtitle: Text("@${user.username}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline, color: Color(0xFF8261B8)),
                    title: const Text("Correo Real de Recuperación"),
                    subtitle: Text(user.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_iphone_outlined, color: Color(0xFF8261B8)),
                    title: const Text("Teléfono de Notificaciones y Códigos"),
                    subtitle: Text(user.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  const Text("Contraseña de Acceso Owner:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFAFAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setMState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8261B8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (passCtrl.text.trim().isNotEmpty) {
                          await authProv.updatePassword(passCtrl.text.trim());
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF10B981),
                              content: Text("Contraseña de cuenta Owner actualizada correctamente."),
                            ),
                          );
                        }
                      },
                      child: const Text("Guardar Nueva Contraseña", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final adsProv = Provider.of<AdsProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final user = authProv.currentUser;
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
                    user.initials,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                          if (user.isOwner)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star, color: Colors.amber, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "@${user.username} • ${user.email}",
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: user.isOwner
                                  ? Colors.amber.withOpacity(0.18)
                                  : currentIdentity.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (user.isOwner)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.verified, size: 13, color: Colors.amber),
                                  ),
                                Text(
                                  user.isOwner ? "👑 Cuenta Owner · Creadora" : user.plan,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: user.isOwner ? const Color(0xFFB45309) : currentIdentity.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  subtitle: Text("Cuenta Owner @${user.username} • Ver credenciales"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showSecurityModal(context, authProv),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN 2.5: NOTIFICACIONES Y ALERTAS (INCISOS A Y B)
          Text(
            "NOTIFICACIONES & ALERTAS",
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
                  leading: const Icon(Icons.alarm, color: Color(0xFF8261B8)),
                  title: const Text("Recordatorio Diario 8:00 PM (Local)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Aviso automático para registrar balance de caja y gastos.", style: TextStyle(fontSize: 12)),
                  trailing: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF8261B8)),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text("Probar", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await NotificationService().showDailyFinanceReminder(userName: user.fullName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF8261B8),
                          content: Text("¡Notificación local enviada a tu barra de estado!"),
                        ),
                      );
                    },
                  ),
                ),
                Divider(height: 1, indent: 56, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: Colors.amber),
                  title: const Text("Alerta de Cobranza (Local)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Avisos de deudas por cobrar antes de su fecha límite.", style: TextStyle(fontSize: 12)),
                  trailing: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.amber.shade800),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text("Probar", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await NotificationService().showDebtDueReminder(personName: "Cliente Ejemplo", amount: 350.0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.amber,
                          content: Text("¡Alerta de cobranza enviada a la barra de estado!"),
                        ),
                      );
                    },
                  ),
                ),
                Divider(height: 1, indent: 56, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: Colors.blue),
                  title: const Text("Push Remotas (Firebase FCM)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    NotificationService().isFirebaseInitialized
                        ? "Conectado a Firebase Cloud Messaging"
                        : "Preparado para vincular con google-services.json",
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (NotificationService().isFirebaseInitialized ? const Color(0xFF10B981) : Colors.blueGrey).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      NotificationService().isFirebaseInitialized ? "Activo" : "Listo",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: NotificationService().isFirebaseInitialized ? const Color(0xFF10B981) : Colors.blueGrey,
                      ),
                    ),
                  ),
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
                  "Kpital.",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tu capital, en calma • Finanzas en equilibrio",
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "Versión 1.0.0 · Cuenta Owner de Madeline Flores",
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
