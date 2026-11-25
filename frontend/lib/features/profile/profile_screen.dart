import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../accounts/screens/accounts_manager_screen.dart';
import '../ads/providers/ads_provider.dart';
import '../appearance/screens/appearance_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../transactions/screens/expenses_analytics_screen.dart';
import '../transactions/screens/transactions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    if (BiometricAuthService.isPlatformSupported) {
      final available = await BiometricAuthService.isBiometricAvailable();
      final enabled = await BiometricAuthService.isBiometricEnabled();
      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = enabled;
        });
      }
    }
  }

  Future<void> _showSecurityModal(BuildContext context, AuthProvider auth) async {
    final current = TextEditingController();
    final replacement = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;
          String? error;
          return StatefulBuilder(builder: (dialogContext, refresh) {
            return AlertDialog(
              title: const Text('Cambiar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña actual'),
                  ),
                  TextField(
                    controller: replacement,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nueva contraseña', helperText: 'Al menos 12 caracteres'),
                  ),
                  if (error != null) Text(error!),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: saving ? null : () async {
                    if (current.text.isEmpty || replacement.text.length < 12) {
                      refresh(() => error = 'Completa ambos campos.');
                      return;
                    }
                    refresh(() => saving = true);
                    final ok = await auth.updatePassword(current.text, replacement.text);
                    if (!dialogContext.mounted) return;
                    if (ok) {
                      Navigator.pop(dialogContext);
                    } else {
                      refresh(() {
                        saving = false;
                        error = auth.errorMessage ?? 'Vuelve a iniciar sesión.';
                      });
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          });
        },
      );
    } finally {
      current.dispose();
      replacement.dispose();
    }
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider authProv) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('¿Cerrar sesión?'),
          ],
        ),
        content: const Text('¿Estás seguro/a de que deseas cerrar tu sesión en Kpital? Tendrás que ingresar tus credenciales nuevamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await authProv.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
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
        actions: [
          if (authProv.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Cerrar sesión",
              onPressed: () => _confirmLogout(context, authProv),
            ),
        ],
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

          // SECCIÓN NUEVA: HERRAMIENTAS Y MÓDULOS DE KPITAL (Los accesos del encabezado)
          Text(
            "HERRAMIENTAS Y MÓDULOS",
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3366D6).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFF3366D6)),
                  ),
                  title: const Text("Gestor de Cuentas & Bóvedas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Efectivo, bancos y bóvedas protegidas", style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountsManagerScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 64, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
                  ),
                  title: const Text("Movimientos & QR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Historial de ingresos, gastos y transferencias", style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 64, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFFF59E0B)),
                  ),
                  title: const Text("Gráfico de Gastos (Analítica)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Desglose mensual de gastos fijos y hormiga", style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpensesAnalyticsScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 64, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF8B5CF6)),
                  ),
                  title: const Text("Inventario & Escalas (Micro-negocio)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Lotes mayoristas, escandallo, docenas y stock", style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InventoryScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 64, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentIdentity.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.palette_outlined, color: currentIdentity.primary),
                  ),
                  title: const Text("Estilos & Apariencia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${currentIdentity.name} • Colores y fondos", style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppearanceScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN 2: SEGURIDAD Y PREFERENCIAS
          Text(
            "SEGURIDAD Y PREFERENCIAS",
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
                if (authProv.isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Cambiar contraseña'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _showSecurityModal(context, authProv),
                  ),
                // Opción de Huella Digital (Solo visible en dispositivos móviles con hardware)
                if (BiometricAuthService.isPlatformSupported && _biometricAvailable) ...[
                  Divider(height: 1, indent: 56, color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint, color: Color(0xFF8261B8)),
                    title: const Text("Ingreso con huella dactilar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("Acceso rápido con la huella de tu teléfono", style: TextStyle(fontSize: 12)),
                    value: _biometricEnabled,
                    activeColor: const Color(0xFF8261B8),
                    onChanged: (val) async {
                      if (val) {
                        final auth = await BiometricAuthService.authenticate(
                          reason: 'Confirma tu huella para activar el acceso rápido',
                        );
                        if (!auth) return;
                      }
                      await BiometricAuthService.setBiometricEnabled(val);
                      setState(() => _biometricEnabled = val);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: val ? const Color(0xFF10B981) : Colors.blueGrey,
                            content: Text(val ? "¡Acceso con huella digital activado!" : "Acceso con huella desactivado."),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN 3: NOTIFICACIONES Y ALERTAS (INCISOS A Y B)
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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF8261B8),
                            content: Text("¡Notificación local enviada a tu barra de estado!"),
                          ),
                        );
                      }
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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.amber,
                            content: Text("¡Alerta de cobranza enviada a la barra de estado!"),
                          ),
                        );
                      }
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

          // SECCIÓN 4: MODO CREADOR Y PUBLICIDAD (CU-7.3)
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
                  onChanged: !authProv.isOwner ? null : (val) {
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
          const SizedBox(height: 28),

          // BOTÓN PRINCIPAL DE CERRAR SESIÓN (Muy visible y destacado)
          if (authProv.isLoggedIn)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context, authProv),
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                label: const Text(
                  "Cerrar sesión",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

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
                  "Versión 1.0.0",
                  style: TextStyle(color: tokens.textSecondary.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
