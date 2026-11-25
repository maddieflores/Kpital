import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../../accounts/providers/accounts_provider.dart';

enum DateFilterPeriod { all, today, thisWeek, thisMonth }

class TransactionsProvider extends ChangeNotifier {
  String _currentUserId = '';
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  String get _storageKey =>
      'kpital_transactions_${_currentUserId.isNotEmpty ? _currentUserId : "guest"}_v2';

  // Filtros activos (CU-1.4)
  String _searchQuery = '';
  DateFilterPeriod _selectedPeriod = DateFilterPeriod.all;
  String? _selectedAccountId;
  TransactionType? _selectedType;

  List<TransactionModel> get allTransactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;
  DateFilterPeriod get selectedPeriod => _selectedPeriod;
  String? get selectedAccountId => _selectedAccountId;
  TransactionType? get selectedType => _selectedType;

  /// CU-1.4: Lista filtrada dinámicamente por persona, fecha, cuenta o tipo
  List<TransactionModel> get filteredTransactions {
    return _transactions.where((t) {
      // 1. Filtro por persona o concepto (Búsqueda)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesContact = t.contactName?.toLowerCase().contains(q) ?? false;
        final matchesDesc = t.description?.toLowerCase().contains(q) ?? false;
        final matchesCategory = t.category?.toLowerCase().contains(q) ?? false;
        if (!matchesContact && !matchesDesc && !matchesCategory) {
          return false;
        }
      }

      // 2. Filtro por tipo (Ingreso, Gasto, Transferencia)
      if (_selectedType != null && t.type != _selectedType) {
        return false;
      }

      // 3. Filtro por cuenta
      if (_selectedAccountId != null &&
          t.accountId != _selectedAccountId &&
          t.destinationAccountId != _selectedAccountId) {
        return false;
      }

      // 4. Filtro por rango de fechas
      final now = DateTime.now();
      switch (_selectedPeriod) {
        case DateFilterPeriod.today:
          final startOfToday = DateTime(now.year, now.month, now.day);
          if (t.transactionDate.isBefore(startOfToday)) return false;
          break;
        case DateFilterPeriod.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          if (t.transactionDate.isBefore(startOfWeekDate)) return false;
          break;
        case DateFilterPeriod.thisMonth:
          final startOfMonth = DateTime(now.year, now.month, 1);
          if (t.transactionDate.isBefore(startOfMonth)) return false;
          break;
        case DateFilterPeriod.all:
          break;
      }

      return true;
    }).toList();
  }

  /// Total de ingresos este mes
  double get monthlyIncome {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _transactions
        .where((t) => t.type == TransactionType.income && t.transactionDate.isAfter(startOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total de gastos este mes
  double get monthlyExpenses {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _transactions
        .where((t) => t.type == TransactionType.expense && t.transactionDate.isAfter(startOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// CU-2.2: Gastos Fijos del mes (Alquiler, Luz, Insumos, etc.)
  double get monthlyFixedExpenses {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.isEssential &&
            t.transactionDate.isAfter(startOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// CU-2.2: Gastos Hormiga del mes (Antojos, comidas al paso, refrescos)
  double get monthlyAntExpenses {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.isEssential &&
            t.transactionDate.isAfter(startOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// CU-2.3: Agrupación de gastos por categoría para el Gráfico Circular
  Map<String, double> get monthlyExpensesByCategory {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final Map<String, double> categoryMap = {};

    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense && tx.transactionDate.isAfter(startOfMonth)) {
        final cat = tx.category ?? (tx.isEssential ? 'Gasto Fijo' : 'Gasto Hormiga');
        categoryMap[cat] = (categoryMap[cat] ?? 0.0) + tx.amount;
      }
    }
    return categoryMap;
  }

  /// Porcentaje de cada categoría respecto al total de gastos del mes
  Map<String, double> get monthlyCategoryPercentages {
    final total = monthlyExpenses;
    if (total <= 0) return {};
    final categoryMap = monthlyExpensesByCategory;
    return categoryMap.map((cat, amount) => MapEntry(cat, (amount / total) * 100));
  }

  TransactionsProvider();

  Future<void> setUserId(String userId) async {
    if (_currentUserId == userId && !_isLoading) return;
    _currentUserId = userId;
    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId.isEmpty) {
        _transactions = [];
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_storageKey);

      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(dataString);
        _transactions = decoded.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
        _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      } else {
        // Base limpia para usuarios nuevos: no precargar transacciones demo
        _transactions = [];
      }
    } catch (e) {
      debugPrint('Error al cargar transacciones: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveTransactions() async {
    if (_currentUserId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = jsonEncode(_transactions.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, dataString);
    } catch (e) {
      debugPrint('Error al guardar transacciones: $e');
    }
  }

  /// CU-1.1 & CU-1.2: Registrar Transferencia Recibida / Ingreso
  Future<TransactionModel> recordIncome({
    required AccountsProvider accountsProvider,
    required String accountId,
    required String accountName,
    required double amount,
    required String contactName,
    String? description,
    String? receiptImagePath,
    DateTime? transactionDate,
    String category = 'Transferencia Recibida',
  }) async {
    final now = DateTime.now();
    final newTx = TransactionModel(
      id: 'tx_${now.millisecondsSinceEpoch}',
      accountId: accountId,
      accountName: accountName,
      type: TransactionType.income,
      amount: amount,
      currency: 'BOB',
      contactName: contactName.trim(),
      description: description?.trim(),
      receiptImagePath: receiptImagePath,
      transactionDate: transactionDate ?? now,
      category: category,
      createdAt: now,
    );

    _transactions.insert(0, newTx);
    await _saveTransactions();

    // Actualiza automáticamente el saldo en la cuenta elegida (CU-1.1)
    await accountsProvider.adjustBalance(accountId, amount);

    notifyListeners();
    return newTx;
  }

  /// CU-2.1: Registrar Gasto
  Future<TransactionModel> recordExpense({
    required AccountsProvider accountsProvider,
    required String accountId,
    required String accountName,
    required double amount,
    String? contactName,
    required String description,
    required String category,
    bool isEssential = true,
    String? receiptImagePath,
    DateTime? transactionDate,
  }) async {
    final now = DateTime.now();
    final newTx = TransactionModel(
      id: 'tx_${now.millisecondsSinceEpoch}',
      accountId: accountId,
      accountName: accountName,
      type: TransactionType.expense,
      amount: amount,
      currency: 'BOB',
      contactName: contactName?.trim(),
      description: description.trim(),
      receiptImagePath: receiptImagePath,
      transactionDate: transactionDate ?? now,
      category: category,
      isEssential: isEssential,
      createdAt: now,
    );

    _transactions.insert(0, newTx);
    await _saveTransactions();

    // Descuenta el dinero de la cuenta de salida
    await accountsProvider.adjustBalance(accountId, -amount);

    notifyListeners();
    return newTx;
  }

  /// Eliminar transacción con reversión de saldo
  Future<void> deleteTransaction({
    required String transactionId,
    required AccountsProvider accountsProvider,
  }) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) return;

    final tx = _transactions[index];

    // Revertir efecto en la cuenta
    if (tx.type == TransactionType.income) {
      await accountsProvider.adjustBalance(tx.accountId, -tx.amount);
    } else if (tx.type == TransactionType.expense) {
      await accountsProvider.adjustBalance(tx.accountId, tx.amount);
    }

    _transactions.removeAt(index);
    await _saveTransactions();
    notifyListeners();
  }

  // Métodos de filtro (CU-1.4)
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPeriodFilter(DateFilterPeriod period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void setAccountFilter(String? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _selectedType = type;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedPeriod = DateFilterPeriod.all;
    _selectedAccountId = null;
    _selectedType = null;
    notifyListeners();
  }
}
