import '../../../core/services/finance_api_service.dart';
import '../../transactions/models/transaction.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

class DebtsProvider extends ChangeNotifier {
  String _currentUserId = '';
  List<DebtModel> _debts = [];
  bool _isLoading = false;
  String? _token;
  Future<void>? _loading;
  int _revision = 0;
  String? syncError;

  String get _storageKey =>
      'kpital_debts_${_currentUserId.isNotEmpty ? _currentUserId : "guest"}_v2';

  List<DebtModel> get allDebts => List.unmodifiable(_debts);
  bool get isLoading => _isLoading;

  /// Cuentas por cobrar activas (CU-3.1: Me deben)
  List<DebtModel> get receivables =>
      _debts.where((d) => d.type == DebtType.receivable && !d.isPaid).toList();

  /// Cuentas por pagar activas (CU-3.4: Debo a proveedores)
  List<DebtModel> get payables =>
      _debts.where((d) => d.type == DebtType.payable && !d.isPaid).toList();

  /// Historial de deudas liquidadas al 100%
  List<DebtModel> get paidDebts =>
      _debts.where((d) => d.isPaid).toList();

  /// Total de dinero que me deben
  double get totalReceivable =>
      receivables.fold(0.0, (acc, item) => acc + item.remainingAmount);

  /// Total de dinero que debo pagar
  double get totalPayable =>
      payables.fold(0.0, (acc, item) => acc + item.remainingAmount);

  DebtsProvider();

  void setAuthSession(String userId, String? token) {
    if (_currentUserId == userId && _token == token) return;
    if (_currentUserId != userId) _debts = [];
    _currentUserId = userId;
    _token = token;
    syncError = null;
    _loading = Future<void>.microtask(_loadDebts);
  }

  Future<void> synchronize() async {
    await _loading;
    if (_isLoading || _token == null) return;
    _loading = _loadDebts();
    await _loading;
  }

  Future<void> _loadDebts() async {
    final token = _token;
    final key = _storageKey;
    final revision = _revision;
    if (token == null) return;
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != _token || revision != _revision) return;
      final stored = jsonDecode(prefs.getString(key) ?? '[]') as List;
      _debts = stored.cast<Map<String, dynamic>>().map(DebtModel.fromJson).toList();
      final importedKey = '${key}_imported';
      final imported = prefs.getBool(importedKey) ?? false;
      final cloud = await FinanceApiService.syncRecords(
        token, 'debts', imported ? [] : _debts.map((debt) => debt.toJson()),
      );
      if (token != _token || revision != _revision) return;
      _debts = cloud.map(DebtModel.fromJson).toList();
      await _saveDebts();
      if (!imported) await prefs.setBool(importedKey, true);
      if (token == _token) syncError = null;
    } on FinanceSyncException catch (error) {
      if (token == _token) syncError = error.message;
    } catch (_) {
      if (token == _token) syncError = 'No se pudieron sincronizar las deudas.';
    } finally {
      if (token == _token) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _saveDebts() async {
    final key = _storageKey;
    final data = jsonEncode(_debts.map((debt) => debt.toJson()).toList());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, data);
    } catch (error) {
      debugPrint('Error al guardar la copia local de deudas: $error');
    }
  }

  /// CU-3.1 & CU-3.4: Crear cuenta por cobrar o por pagar
  Future<void> addDebt({
    required DebtType type,
    required String personName,
    String? phoneNumber,
    required double totalAmount,
    DateTime? dueDate,
    String? concept,
    String? debtId,
    required DateTime createdAt,
  }) async {
    final newDebt = DebtModel(
      id: debtId ?? FinanceApiService.newId('debt'),
      type: type,
      personName: personName.trim(),
      phoneNumber: phoneNumber?.trim(),
      totalAmount: totalAmount,
      remainingAmount: totalAmount,
      dueDate: dueDate,
      concept: concept?.trim(),
      status: DebtStatus.pending,
      createdAt: createdAt,
    );

    final token = FinanceApiService.requireSession(_token);
    await FinanceApiService.saveRecords(token, [
      FinanceRecordChange('debts', newDebt.id, newDebt.toJson()),
    ]);
    if (token != _token) return;
    _revision++;
    _debts.removeWhere((debt) => debt.id == newDebt.id);
    _debts.insert(0, newDebt);
    await _saveDebts();
    notifyListeners();
  }

  /// CU-3.2: Registrar abono parcial inteligente
  /// Descuenta la deuda e ingresa automáticamente los fondos a la cuenta elegida
  Future<bool> recordPayment({
    required String debtId,
    required double paymentAmount,
    required String accountId,
    required String accountName,
    required AccountsProvider accountsProvider,
    required TransactionsProvider transactionsProvider,
    String? note,
    required String paymentId,
  }) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1 || paymentAmount <= 0) return false;

    final debt = _debts[index];
    final actualPayment = paymentAmount.clamp(0.0, debt.remainingAmount);
    final newRemaining = (debt.remainingAmount - actualPayment).clamp(0.0, double.infinity);
    final isFullyPaid = newRemaining <= 0.01;

    final newPayment = DebtPayment(
      id: paymentId,
      amount: actualPayment,
      date: DateTime.now(),
      accountId: accountId,
      accountName: accountName,
      note: note,
    );

    final updatedPayments = List<DebtPayment>.from(debt.payments)..add(newPayment);

    final updated = debt.copyWith(
      remainingAmount: newRemaining,
      status: isFullyPaid ? DebtStatus.paid : DebtStatus.partial,
      payments: updatedPayments,
    );

    final token = FinanceApiService.requireSession(_token);
    await accountsProvider.waitForCloud();
    if (token != _token) return false;
    final income = debt.type == DebtType.receivable;
    await FinanceApiService.saveRecords(token, [
      FinanceRecordChange('debts', debt.id, updated.toJson(), previous: debt.toJson()),
    ], transaction: TransactionModel(
      id: paymentId,
      accountId: accountId,
      accountName: accountName,
      type: income ? TransactionType.income : TransactionType.expense,
      amount: actualPayment,
      contactName: debt.personName,
      description: debt.concept,
      category: income ? 'Abono de Deuda (Cobro)' : 'Pago a Proveedor / Deuda',
      transactionDate: newPayment.date,
      createdAt: newPayment.date,
    ));
    if (token == _token) {
      await accountsProvider.synchronize();
      await Future.wait([synchronize(), transactionsProvider.synchronize()]);
    }
    return true;
  }

  /// Eliminar deuda
  Future<void> deleteDebt(String debtId) async {
    final token = FinanceApiService.requireSession(_token);
    final debt = _debts.where((d) => d.id == debtId).firstOrNull;
    if (debt == null) return;
    await FinanceApiService.saveRecords(token, [
      FinanceRecordChange('debts', debtId, null, previous: debt.toJson()),
    ]);
    if (token != _token) return;
    _revision++;
    _debts.removeWhere((d) => d.id == debtId);
    await _saveDebts();
    notifyListeners();
  }
}
