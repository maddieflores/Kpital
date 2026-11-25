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

  String get _storageKey =>
      'kpital_accounts_${_currentUserId.isNotEmpty ? _currentUserId : "guest"}_v2';

  List<Account> get accounts => List.unmodifiable(_accounts);
  bool get isLoading => _isLoading;

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
    _currentUserId = userId;
    _authToken = token;
    await _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final userId = _currentUserId;
    final token = _authToken;
    final storageKey = _storageKey;
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
      if (token != null && token.isNotEmpty) {
        final cloud = await FinanceApiService.syncAccounts(token, loaded);
        if (!sessionIsCurrent()) return;
        if (cloud != null) {
          loaded = cloud;
          await prefs.setString(storageKey, jsonEncode(loaded.map((item) => item.toJson()).toList()));
          if (!sessionIsCurrent()) return;
        }
      }
      _accounts = loaded;
    } catch (e) {
      debugPrint('Error al sincronizar cuentas: $e');
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
  }) async {
    final token = _authToken;
    final newAccount = Account(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      type: type,
      currency: currency,
      balance: initialBalance,
      isSavingsVault: isSavingsVault,
      targetAmount: isSavingsVault ? targetAmount : null,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    _accounts.add(newAccount);
    await _saveAccounts();
    if (token != null && token.isNotEmpty) {
      await FinanceApiService.saveAccount(token, newAccount);
    }
    notifyListeners();
  }

  /// Editar cuenta o bóveda
  Future<void> updateAccount(Account updated) async {
    final token = _authToken;
    final index = _accounts.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _accounts[index] = updated;
      await _saveAccounts();
      if (token != null && token.isNotEmpty) {
        FinanceApiService.saveAccount(token, updated);
      }
      notifyListeners();
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount(String accountId) async {
    final token = _authToken;
    _accounts.removeWhere((a) => a.id == accountId);
    await _saveAccounts();
    if (token != null && token.isNotEmpty) {
      FinanceApiService.deleteAccount(token, accountId);
    }
    notifyListeners();
  }

  /// CU-1.3: Transferir entre cuentas propias / meter dinero a bóveda sin contar como gasto
  Future<bool> transferFunds({
    required String originAccountId,
    required String destinationAccountId,
    required double amount,
  }) async {
    final token = _authToken;
    if (amount <= 0) return false;

    final originIdx = _accounts.indexWhere((a) => a.id == originAccountId);
    final destIdx = _accounts.indexWhere((a) => a.id == destinationAccountId);

    if (originIdx == -1 || destIdx == -1) return false;
    if (_accounts[originIdx].balance < amount) return false; // Saldo insuficiente

    final origin = _accounts[originIdx];
    final destination = _accounts[destIdx];

    final updatedOrigin = origin.copyWith(balance: origin.balance - amount);
    final updatedDestination = destination.copyWith(balance: destination.balance + amount);
    _accounts[originIdx] = updatedOrigin;
    _accounts[destIdx] = updatedDestination;

    await _saveAccounts();
    if (token != null && token.isNotEmpty) {
      FinanceApiService.saveAccount(token, updatedOrigin);
      FinanceApiService.saveAccount(token, updatedDestination);
    }
    notifyListeners();
    return true;
  }

  /// Ajustar saldo (para ingresos de transferencias, ventas o gastos)
  Future<void> adjustBalance(
    String accountId,
    double delta, {
    bool syncToCloud = true,
  }) async {
    final token = _authToken;
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index != -1) {
      final current = _accounts[index];
      final updated = current.copyWith(balance: current.balance + delta);
      _accounts[index] = updated;
      await _saveAccounts();
      if (syncToCloud && token != null && token.isNotEmpty) {
        FinanceApiService.saveAccount(token, updated);
      }
      notifyListeners();
    }
  }

  /// Formateador monetario amigable (ej. "Bs 3.200,00")
  static String formatAmount(double value, {String currency = 'Bs'}) {
    final formatter = NumberFormat('#,##0.00', 'es_ES');
    return '$currency ${formatter.format(value)}';
  }
}
