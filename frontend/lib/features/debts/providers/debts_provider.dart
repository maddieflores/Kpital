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

  Future<void> setUserId(String userId) async {
    if (_currentUserId == userId && !_isLoading) return;
    _currentUserId = userId;
    await _loadDebts();
  }

  Future<void> _loadDebts() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId.isEmpty) {
        _debts = [];
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_storageKey);

      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(dataString);
        _debts = decoded.map((e) => DebtModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Base limpia para usuarios nuevos: no precargar deudas demo
        _debts = [];
      }
    } catch (e) {
      debugPrint('Error al cargar deudas: $e');
      _debts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDebts() async {
    if (_currentUserId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = jsonEncode(_debts.map((d) => d.toJson()).toList());
      await prefs.setString(_storageKey, dataString);
    } catch (e) {
      debugPrint('Error al guardar deudas: $e');
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
  }) async {
    final newDebt = DebtModel(
      id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      personName: personName.trim(),
      phoneNumber: phoneNumber?.trim(),
      totalAmount: totalAmount,
      remainingAmount: totalAmount,
      dueDate: dueDate,
      concept: concept?.trim(),
      status: DebtStatus.pending,
      createdAt: DateTime.now(),
    );

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
  }) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1 || paymentAmount <= 0) return false;

    final debt = _debts[index];
    final actualPayment = paymentAmount.clamp(0.0, debt.remainingAmount);
    final newRemaining = (debt.remainingAmount - actualPayment).clamp(0.0, double.infinity);
    final isFullyPaid = newRemaining <= 0.01;

    final newPayment = DebtPayment(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      amount: actualPayment,
      date: DateTime.now(),
      accountId: accountId,
      accountName: accountName,
      note: note,
    );

    final updatedPayments = List<DebtPayment>.from(debt.payments)..add(newPayment);

    _debts[index] = debt.copyWith(
      remainingAmount: newRemaining,
      status: isFullyPaid ? DebtStatus.paid : DebtStatus.partial,
      payments: updatedPayments,
    );

    await _saveDebts();

    // EFECTO AUTOMÁTICO EN CUENTAS Y TRANSACCIONES (CU-3.2)
    if (debt.type == DebtType.receivable) {

      // 2. Crea la transacción de ingreso en el historial
      await transactionsProvider.recordIncome(
        accountsProvider: accountsProvider,
        accountId: accountId,
        accountName: accountName,
        amount: actualPayment,
        contactName: debt.personName,
        description: 'Abono de deuda: ${debt.concept ?? "Cobro parcial"}',
        category: 'Abono de Deuda (Cobro)',
      );
    } else {

      await transactionsProvider.recordExpense(
        accountsProvider: accountsProvider,
        accountId: accountId,
        accountName: accountName,
        amount: actualPayment,
        contactName: debt.personName,
        description: 'Pago de deuda/cuota: ${debt.concept ?? "Proveedor"}',
        category: 'Pago a Proveedor / Deuda',
        isEssential: true,
      );
    }

    notifyListeners();
    return true;
  }

  /// Eliminar deuda
  Future<void> deleteDebt(String debtId) async {
    _debts.removeWhere((d) => d.id == debtId);
    await _saveDebts();
    notifyListeners();
  }
}
