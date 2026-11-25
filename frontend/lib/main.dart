import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/kpital_logo.dart';
import 'core/widgets/user_avatar.dart';
import 'features/splash/splash_screen.dart';
import 'features/pricing_ai/pricing_calculator_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/accounts/providers/accounts_provider.dart';
import 'features/accounts/screens/accounts_manager_screen.dart';
import 'features/accounts/widgets/create_edit_account_sheet.dart';
import 'features/accounts/widgets/transfer_funds_sheet.dart';
import 'features/transactions/providers/transactions_provider.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/transactions/widgets/record_income_sheet.dart';
import 'features/transactions/widgets/record_expense_sheet.dart';
import 'features/debts/providers/debts_provider.dart';
import 'features/debts/screens/debts_screen.dart';
import 'features/inventory/providers/inventory_provider.dart';
import 'features/inventory/screens/inventory_screen.dart';
import 'features/inventory/widgets/quick_sale_sheet.dart';
import 'features/ads/providers/ads_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/pricing_ai/screens/seasonal_trends_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar localización para formateo de fechas
  try {
    await initializeDateFormatting('es_ES', null);
  } catch (e) {
    debugPrint("Error inicializando locale es_ES: $e");
  }
  
  // Inicializar Notificaciones Locales (Inciso A) y Firebase Push (Inciso B)
  try {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await NotificationService().initializeLocalNotifications();
      await NotificationService().initializeFirebase();
    }
  } catch (e) {
    debugPrint("Error inicializando notificaciones: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AccountsProvider>(
          create: (_) => AccountsProvider(),
          update: (_, auth, accounts) => (accounts ?? AccountsProvider())
            ..setAuthSession(userId: auth.currentUser.id, token: auth.token),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, AccountsProvider, TransactionsProvider>(
          create: (_) => TransactionsProvider(),
          update: (_, auth, accounts, txs) => (txs ?? TransactionsProvider())
            ..setAuthSession(userId: auth.currentUser.id, token: auth.token, accountsProvider: accounts),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DebtsProvider>(
          create: (_) => DebtsProvider(),
          update: (_, auth, debts) => (debts ?? DebtsProvider())
            ..setAuthSession(auth.currentUser.id, auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, InventoryProvider>(
          create: (_) => InventoryProvider(),
          update: (_, auth, inv) => (inv ?? InventoryProvider())
            ..setAuthSession(auth.currentUser.id, auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdsProvider>(
          create: (_) => AdsProvider(),
          update: (_, auth, ads) => (ads ?? AdsProvider())..assignOwner(auth.isOwner),
        ),
      ],
      child: const KpitalApp(),
    ),
  );
}

class KpitalApp extends StatelessWidget {
  const KpitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Kpital · Tu capital, en calma',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const SplashScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _syncTimer;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_synchronize());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_synchronize());
  }

  Future<void> _synchronize() async {
    if (!mounted || _syncing || !context.read<AuthProvider>().isLoggedIn) return;
    _syncing = true;
    final accounts = context.read<AccountsProvider>();
    final movements = context.read<TransactionsProvider>();
    final debts = context.read<DebtsProvider>();
    final inventory = context.read<InventoryProvider>();
    try {
      await Future.wait([
        () async {
          await accounts.synchronize();
          await movements.synchronize();
        }(),
        debts.synchronize(),
        inventory.synchronize(),
      ]);
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PricingCalculatorScreen(),
    const DebtsScreen(),
    const SeasonalTrendsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final syncError = context.watch<AccountsProvider>().syncError ??
        context.watch<TransactionsProvider>().syncError ??
        context.watch<DebtsProvider>().syncError ??
        context.watch<InventoryProvider>().syncError;
    return Scaffold(
      body: Column(
        children: [
          if (syncError != null)
            SafeArea(
              bottom: false,
              child: ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(syncError),
                trailing: TextButton(
                  onPressed: _synchronize,
                  child: const Text('Sincronizar'),
                ),
              ),
            ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: "Cuentas",
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: "Precios IA",
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: "Deudas",
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: "Tendencias",
          ),
        ],
      ),
    );
  }
}

// 1. Pantalla de Cuentas y Ahorro (Dashboard inicial estilo Figma)
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openAccountsManager(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountsManagerScreen()),
    );
  }

  void _openTransactions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
    );
  }

  void _openInventory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InventoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primaryColor = Theme.of(context).primaryColor;
    final accountsProvider = Provider.of<AccountsProvider>(context);
    final txProv = Provider.of<TransactionsProvider>(context);
    final inventoryProv = Provider.of<InventoryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final user = authProv.currentUser;
    final String greetingName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim().split(RegExp(r'\s+')).first
        : (user.username.trim().isNotEmpty && user.username != 'invitado'
            ? user.username
            : 'Usuario');

    final primaryVault = accountsProvider.savingsVaults.isNotEmpty
        ? accountsProvider.savingsVaults.first
        : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: tokens.scaffoldBg,
          gradient: tokens.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Figma: Avatar «AV», Saludo y Engranaje
                Row(
                  children: [
                    InkWell(
                      onTap: () => _openProfile(context),
                      borderRadius: BorderRadius.circular(14),
                      child: const KpitalLogoIcon(
                        size: 44,
                        hasShadow: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openProfile(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hola, $greetingName",
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.textSecondary,
                              ),
                            ),
                            Text(
                              "Tu capital, en calma.",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Icono de Perfil único que contiene todos los accesos y ajustes
                    InkWell(
                      onTap: () => _openProfile(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Tooltip(
                        message: "Mi Perfil y Herramientas",
                        child: UserAvatar(
                          user: user,
                          radius: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Tarjeta Principal de Saldo (Figma Balance Card) - CU-4.3 & CU-4.4
                InkWell(
                  onTap: () => _openAccountsManager(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: tokens.balanceCardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.balanceCardBg.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
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
                              "Saldo disponible para gastar",
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.balanceCardText.withOpacity(0.85),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 13,
                                    color: tokens.balanceCardText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Gestionar",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.balanceCardText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AccountsProvider.formatAmount(accountsProvider.availableBalance),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.6,
                            color: tokens.balanceCardText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: tokens.balanceCardText.withOpacity(0.85),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Patrimonio Total: ${AccountsProvider.formatAmount(accountsProvider.totalPatrimony)}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: tokens.balanceCardText.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 1,
                          color: tokens.balanceCardText.withOpacity(0.15),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payments_outlined,
                                        size: 14,
                                        color: tokens.balanceCardText.withOpacity(0.85),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Operativo",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tokens.balanceCardText.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "${accountsProvider.operationalAccounts.length} cuentas",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.balanceCardText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 14,
                                        color: Colors.amberAccent.withOpacity(0.9),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Ahorro Bóvedas",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tokens.balanceCardText.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    AccountsProvider.formatAmount(accountsProvider.vaultsTotal),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amberAccent,
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
                ),
                const SizedBox(height: 16),

                // Card Movimientos con Mini Gráfico (Clic para ver Historial CU-1.4)
                InkWell(
                  onTap: () => _openTransactions(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tokens.isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
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
                                Text(
                                  "Movimientos",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "Ver Historial ➔",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Este mes ▾",
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Ingresos: ${AccountsProvider.formatAmount(txProv.monthlyIncome)}",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC07040),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Gastos: ${AccountsProvider.formatAmount(txProv.monthlyExpenses)}",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: CustomPaint(
                            painter: _DashboardWavePainter(
                              primaryColor: const Color(0xFF10B981),
                              secondaryColor: const Color(0xFFC07040),
                            ),
                            size: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("01", style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                            Text("07", style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                            Text("14", style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                            Text("21", style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                            Text("28", style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card Metas de Ahorro (CU-4.2 & CU-4.3: Conectado a Bóvedas reales)
                if (primaryVault != null)
                  InkWell(
                    onTap: () => _openAccountsManager(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tokens.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
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
                                  const Icon(Icons.lock_rounded, size: 18, color: Color(0xFF8B5CF6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Bóveda de Ahorro Destacada",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${(primaryVault.progressPercentage * 100).toInt()}%",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            primaryVault.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: primaryVault.progressPercentage,
                              backgroundColor: tokens.isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.06),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${AccountsProvider.formatAmount(primaryVault.balance)} de ${AccountsProvider.formatAmount(primaryVault.targetAmount ?? 0.0)}",
                                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                              ),
                              Text(
                                "Saldo protegido 🔒",
                                style: TextStyle(fontSize: 11, color: const Color(0xFF8B5CF6).withOpacity(0.85)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),

                // Card Micro-negocio & Escalas (CU-5)
                InkWell(
                  onTap: () => _openInventory(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tokens.isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
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
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.inventory_2_outlined, size: 16, color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Micro-negocio & Lotes",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${inventoryProv.globalRecoveryPercentage.toStringAsFixed(0)}% recuperado",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Capital invertido vs recuperado",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                            ),
                            Text(
                              "${AccountsProvider.formatAmount(inventoryProv.totalCapitalRecovered)} de ${AccountsProvider.formatAmount(inventoryProv.totalCapitalInvested)}",
                              style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (inventoryProv.globalRecoveryPercentage / 100).clamp(0.0, 1.0),
                            backgroundColor: tokens.isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.06),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Stock: ${inventoryProv.totalStockUnits} u. en ${inventoryProv.products.length} lotes",
                              style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                            ),
                            InkWell(
                              onTap: () => QuickSaleSheet.show(context),
                              child: Row(
                                children: [
                                  const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 2),
                                  const Text(
                                    "Venta Rápida ➔",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
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
                ),
                const SizedBox(height: 18),

                // Cuentas activas dinámicas (CU-4.1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Cuentas activas",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: tokens.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text("Gestionar"),
                      onPressed: () => _openAccountsManager(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Lista de cuentas operativas reales
                ...accountsProvider.operationalAccounts.map((account) {
                  return _AccountItem(
                    name: account.name,
                    balance: AccountsProvider.formatAmount(account.balance),
                    icon: account.icon,
                    color: account.color,
                    subtitle: account.type.label,
                    onTap: () => TransferFundsSheet.show(
                      context,
                      initialOriginId: account.id,
                    ),
                  );
                }),

                // Botón para agregar nueva cuenta o bóveda
                OutlinedButton.icon(
                  onPressed: () => CreateEditAccountSheet.show(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Nueva Cuenta o Bóveda"),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab_move',
            onPressed: () => TransferFundsSheet.show(context),
            backgroundColor: tokens.cardBg,
            tooltip: "Mover entre cuentas",
            mini: true,
            child: Icon(Icons.compare_arrows_rounded, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.extended(
            heroTag: 'fab_expense',
            onPressed: () => RecordExpenseSheet.show(context),
            backgroundColor: const Color(0xFFEF4444),
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
            label: const Text(
              "Gasto",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.extended(
            heroTag: 'fab_income',
            onPressed: () => RecordIncomeSheet.show(context),
            backgroundColor: const Color(0xFF10B981),
            icon: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 18),
            label: const Text(
              "Ingreso / QR",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardWavePainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _DashboardWavePainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.85);
    for (double x = 0; x <= size.width; x += 15) {
      final y = (size.height * 0.5) - (size.height * 0.35) * (x / size.width) + 5 * (x % 30 == 0 ? -1 : 1);
      path1.lineTo(x, y.clamp(6.0, size.height - 6.0));
    }
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = secondaryColor.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.9);
    for (double x = 0; x <= size.width; x += 18) {
      final y = (size.height * 0.72) - (size.height * 0.25) * (x / size.width) + 4 * (x % 36 == 0 ? -1 : 1);
      path2.lineTo(x, y.clamp(14.0, size.height - 4.0));
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _DashboardWavePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor;
  }
}

class _AccountItem extends StatelessWidget {
  final String name;
  final String balance;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const _AccountItem({
    required this.name,
    required this.balance,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.18),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: tokens.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: tokens.textSecondary),
              )
            : null,
        trailing: Text(
          balance,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: tokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
