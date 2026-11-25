import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/services/finance_api_service.dart';
import '../models/account.dart';

class AccountsProvider extends ChangeNotifier {
  String _currentUserId = '';
  String? _authToken;
  List<Account> _accounts = [];
  bool _isLoading = false;
  Future<void>? _sessionLoad;
  int _revision = 0;
  String? _syncError;

  String get _storageKey =>
      'kpital_accounts_${_currentUserId.isNotEmpty ? _currentUserId : "guest"}_v2';

  List<Account> get accounts => List.unmodifiable(_accounts);
  bool get isLoading => _isLoading;
  String? get syncError => _syncError;

  /// Cuentas operativas del día a día (Efectivo, Bancos, Billeteras)
  List<Account> get operationalAccounts =>
      _accounts.where((a) => !a.isSavingsVault).toList();

  /// Bóvedas de ahorro (fondos bloqueados para metas o fardos)
  List<Account> get savingsVaults =>
      _accounts.where((a) => a.isSavingsVault).toList();

  /// Total patrimonial global: Bancos + Efectivo + Bóvedas (CU-4.4)
  double get totalPatrimony =>
      _accounts.fold(0.0, (acc, item) => acc + item.balance);

  /// Saldo disponible diario para gastar (CU-4.3: Excluye bóvedas protegidas)
  double get availableBalance =>
      operationalAccounts.fold(0.0, (acc, item) => acc + item.balance);

  /// Total protegido en bóvedas de ahorro
  double get vaultsTotal =>
      savingsVaults.fold(0.0, (acc, item) => acc + item.balance);

  AccountsProvider();

  Future<void> setUserId(String userId) async {
    await setAuthSession(userId: userId, token: _authToken);
  }

  Future<void> setAuthSession({required String userId, String? token}) async {
    final userChanged = _currentUserId != userId;
    final tokenChanged = _authToken != token;
    if (!userChanged && !tokenChanged) return;
    if (userChanged) _accounts = [];
    _syncError = null;
    _currentUserId = userId;
    _authToken = token;
    final load = Future<void>.microtask(_loadAccounts);
    _sessionLoad = load;
    await load;
  }

  Future<void> waitForCloud() async {
    await _sessionLoad;
    if (_syncError != null) throw FinanceSyncException(_syncError!);
  }

  Future<void> synchronize() async {
    await _sessionLoad;
    if (_isLoading || _authToken == null) return;
    final load = _loadAccounts();
    _sessionLoad = load;
    await load;
  }

  Future<void> _loadAccounts() async {
    final userId = _currentUserId;
    final token = _authToken;
    final storageKey = _storageKey;
    final revision = _revision;
    bool sessionIsCurrent() => _currentUserId == userId && _authToken == token;
    _isLoading = true;
    notifyListeners();

    try {
      if (userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      if (!sessionIsCurrent()) return;
      final stored = prefs.getString(storageKey);
      var loaded = <Account>[];
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored) as List<dynamic>;
        loaded = decoded.map((item) => Account.fromJson(item as Map<String, dynamic>)).toList();
      }
      if (_revision == revision) _accounts = loaded;
      if (token != null && token.isNotEmpty) {
        final importedKey = '${storageKey}_imported';
        final imported = prefs.getBool(importedKey) ?? false;
        final cloud = await FinanceApiService.syncAccounts(token, imported ? [] : loaded);
        if (!sessionIsCurrent() || _revision != revision) return;
        _accounts = cloud;
        await _saveAccounts();
        if (!imported) await prefs.setBool(importedKey, true);
      }
      if (sessionIsCurrent()) _syncError = null;
    } on FinanceSyncException catch (e) {
      if (sessionIsCurrent()) _syncError = e.message;
    } catch (e) {
      if (sessionIsCurrent()) _syncError = 'No se pudieron sincronizar las cuentas.';
    } finally {
      if (sessionIsCurrent()) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _saveAccounts() async {
    if (_currentUserId.isEmpty) return;
    try {
      final storageKey = _storageKey;
      final dataString = jsonEncode(_accounts.map((a) => a.toJson()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, dataString);
    } catch (e) {
      debugPrint('Error al guardar cuentas: $e');
    }
  }

  /// CU-4.1 & CU-4.2: Crear nueva cuenta o bóveda de ahorro
  Future<void> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    String currency = 'BOB',
    bool isSavingsVault = false,
    double? targetAmount,
    String colorHex = '#3366D6',
    String? accountId,
  }) async {
    final newAccount = Account(
      id: accountId ?? FinanceApiService.newId('acc'),
      name: name.trim(),
      type: type,
      currency: currency,
      balance: initialBalance,
      isSavingsVault: isSavingsVault,
      targetAmount: isSavingsVault ? targetAmount : null,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    await _saveInCloud(newAccount, createOnly: true);
  }

  /// Editar cuenta o bóveda
  Future<void> updateAccount(Account updated, {required double previousBalance}) =>
      _saveInCloud(updated, previousBalance: previousBalance);

  Future<void> _saveInCloud(Account updated, {bool createOnly = false, double? previousBalance}) async {
    final token = FinanceApiService.requireSession(_authToken);
    final saved = await FinanceApiService.saveAccount(token, updated,
      createOnly: createOnly, previousBalance: previousBalance);
    if (token != _authToken) return;
    final index = _accounts.indexWhere((a) => a.id == saved.id);
    if (index < 0) {
      _accounts.add(saved);
    } else {
      _accounts[index] = saved;
    }
    _revision++;
    await _saveAccounts();
    notifyListeners();
  }

  /// Eliminar cuenta
  Future<void> deleteAccount(String accountId) async {
    final token = FinanceApiService.requireSession(_authToken);
    await FinanceApiService.deleteAccount(token, accountId);
    if (token != _authToken) return;
    _accounts.removeWhere((a) => a.id == accountId);
    _revision++;
    await _saveAccounts();
    notifyListeners();
  }

  /// Formateador monetario amigable (ej. "Bs 3.200,00")
  static String formatAmount(double value, {String currency = 'Bs'}) {
    final formatter = NumberFormat('#,##0.00', 'es_ES');
    return '$currency ${formatter.format(value)}';
  }
}
