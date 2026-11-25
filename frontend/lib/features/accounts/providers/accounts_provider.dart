import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';

class AccountsProvider extends ChangeNotifier {
  String _currentUserId = '';
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
    if (_currentUserId == userId && !_isLoading) return;
    _currentUserId = userId;
    await _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId.isEmpty) {
        _accounts = [];
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_storageKey);

      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(dataString);
        _accounts = decoded.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Base limpia para usuarios nuevos: no precargar datos demo ajenos
        _accounts = [];
      }
    } catch (e) {
      debugPrint('Error al cargar cuentas: $e');
      _accounts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAccounts() async {
    if (_currentUserId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = jsonEncode(_accounts.map((a) => a.toJson()).toList());
      await prefs.setString(_storageKey, dataString);
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
    notifyListeners();
  }

  /// Editar cuenta o bóveda
  Future<void> updateAccount(Account updated) async {
    final index = _accounts.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _accounts[index] = updated;
      await _saveAccounts();
      notifyListeners();
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount(String accountId) async {
    _accounts.removeWhere((a) => a.id == accountId);
    await _saveAccounts();
    notifyListeners();
  }

  /// CU-1.3: Transferir entre cuentas propias / meter dinero a bóveda sin contar como gasto
  Future<bool> transferFunds({
    required String originAccountId,
    required String destinationAccountId,
    required double amount,
  }) async {
    if (amount <= 0) return false;

    final originIdx = _accounts.indexWhere((a) => a.id == originAccountId);
    final destIdx = _accounts.indexWhere((a) => a.id == destinationAccountId);

    if (originIdx == -1 || destIdx == -1) return false;
    if (_accounts[originIdx].balance < amount) return false; // Saldo insuficiente

    final origin = _accounts[originIdx];
    final destination = _accounts[destIdx];

    _accounts[originIdx] = origin.copyWith(balance: origin.balance - amount);
    _accounts[destIdx] = destination.copyWith(balance: destination.balance + amount);

    await _saveAccounts();
    notifyListeners();
    return true;
  }

  /// Ajustar saldo (para ingresos de transferencias, ventas o gastos)
  Future<void> adjustBalance(String accountId, double delta) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index != -1) {
      final current = _accounts[index];
      _accounts[index] = current.copyWith(balance: current.balance + delta);
      await _saveAccounts();
      notifyListeners();
    }
  }

  /// Formateador monetario amigable (ej. "Bs 3.200,00")
  static String formatAmount(double value, {String currency = 'Bs'}) {
    final formatter = NumberFormat('#,##0.00', 'es_ES');
    return '$currency ${formatter.format(value)}';
  }
}
