import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/finance_api_service.dart';
import '../models/transaction.dart';
import '../../accounts/providers/accounts_provider.dart';

enum DateFilterPeriod { all, today, thisWeek, thisMonth }

class TransactionsProvider extends ChangeNotifier {
  String _currentUserId = '';
  String? _authToken;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  Future<void>? _sessionLoad;
  AccountsProvider? _accountsProvider;
  int _revision = 0;
  String? _syncError;

  String get _storageKey =>
      'kpital_transactions_${_currentUserId.isNotEmpty ? _currentUserId : "guest"}_v2';

  // Filtros activos (CU-1.4)
  String _searchQuery = '';
  DateFilterPeriod _selectedPeriod = DateFilterPeriod.all;
  String? _selectedAccountId;
  TransactionType? _selectedType;

  List<TransactionModel> get allTransactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get syncError => _syncError;

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

  Future<void> setAuthSession({required String userId, String? token,
    required AccountsProvider accountsProvider}) async {
    final userChanged = _currentUserId != userId;
    final tokenChanged = _authToken != token;
    if (!userChanged && !tokenChanged) return;
    if (userChanged) _transactions = [];
    _syncError = null;
    _currentUserId = userId;
    _authToken = token;
    _accountsProvider = accountsProvider;
    final load = Future<void>.microtask(_loadTransactions);
    _sessionLoad = load;
    await load;
  }

  Future<void> synchronize() async {
    await _sessionLoad;
    if (_isLoading || _authToken == null) return;
    final load = _loadTransactions();
    _sessionLoad = load;
    await load;
  }

  Future<void> _loadTransactions() async {
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
      var loaded = <TransactionModel>[];
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored) as List<dynamic>;
        loaded = decoded.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      loaded.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      if (_revision == revision) _transactions = loaded;
      if (token != null && token.isNotEmpty) {
        await _accountsProvider?.waitForCloud();
        if (!sessionIsCurrent() || _revision != revision) return;
        final importedKey = '${storageKey}_imported';
        final imported = prefs.getBool(importedKey) ?? false;
        final cloud = await FinanceApiService.syncTransactions(token, imported ? [] : loaded);
        if (!sessionIsCurrent() || _revision != revision) return;
        _transactions = cloud;
        await _saveTransactions();
        if (!imported) await prefs.setBool(importedKey, true);
      }
      if (sessionIsCurrent()) _syncError = null;
    } on FinanceSyncException catch (e) {
      if (sessionIsCurrent()) _syncError = e.message;
    } catch (e) {
      if (sessionIsCurrent()) _syncError = 'No se pudieron sincronizar los movimientos.';
    } finally {
      if (sessionIsCurrent()) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _saveTransactions() async {
    if (_currentUserId.isEmpty) return;
    try {
      final storageKey = _storageKey;
      final dataString = jsonEncode(_transactions.map((t) => t.toJson()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, dataString);
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
    String? transactionId,
    String category = 'Transferencia Recibida',
  }) async {
    final now = DateTime.now();
    final newTx = TransactionModel(
      id: transactionId ?? FinanceApiService.newId('tx'),
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

    return _record(newTx, accountsProvider);
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
    String? transactionId,
  }) async {
    final now = DateTime.now();
    final newTx = TransactionModel(
      id: transactionId ?? FinanceApiService.newId('tx'),
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

    return _record(newTx, accountsProvider);
  }

  Future<TransactionModel> recordTransfer({
    required AccountsProvider accountsProvider,
    required String originAccountId,
    required String destinationAccountId,
    required double amount,
    required String transactionId,
  }) async {
    final origin = accountsProvider.accounts.where((a) => a.id == originAccountId).firstOrNull;
    final destination = accountsProvider.accounts.where((a) => a.id == destinationAccountId).firstOrNull;
    if (origin == null || destination == null) {
      throw const FinanceSyncException('Una de las cuentas de la transferencia ya no está disponible.');
    }
    final now = DateTime.now();
    return _record(
      TransactionModel(
        id: transactionId,
        accountId: origin.id,
        accountName: origin.name,
        destinationAccountId: destination.id,
        destinationAccountName: destination.name,
        type: TransactionType.transfer,
        amount: amount,
        currency: origin.currency,
        transactionDate: now,
        createdAt: now,
      ),
      accountsProvider,
    );
  }

  Future<TransactionModel> _record(TransactionModel tx, AccountsProvider accounts) async {
    final token = FinanceApiService.requireSession(_authToken);
    await accounts.waitForCloud();
    if (token != _authToken) {
      throw const FinanceSyncException('La sesión cambió. Vuelve a abrir el formulario.');
    }
    final saved = await FinanceApiService.saveTransaction(token, tx);
    if (token == _authToken) {
      _revision++;
      _transactions.removeWhere((t) => t.id == saved.id);
      _transactions.add(saved);
      _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      await _saveTransactions();
      notifyListeners();
      await accounts.synchronize();
    }
    return saved;
  }

  Future<void> deleteTransaction({
    required String transactionId,
    required AccountsProvider accountsProvider,
  }) async {
    final token = FinanceApiService.requireSession(_authToken);
    await FinanceApiService.deleteTransaction(token, transactionId);
    if (token != _authToken) return;
    _revision++;
    _transactions.removeWhere((t) => t.id == transactionId);
    await _saveTransactions();
    notifyListeners();
    await accountsProvider.synchronize();
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
