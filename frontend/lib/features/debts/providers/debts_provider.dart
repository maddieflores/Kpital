import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

class DebtsProvider extends ChangeNotifier {
  static const String _storageKey = 'kpital_debts_v1';

  List<DebtModel> _debts = [];
  bool _isLoading = true;

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

  DebtsProvider() {
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_storageKey);

      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(dataString);
        _debts = decoded.map((e) => DebtModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Datos semilla representativos de comercio local boliviano
        final now = DateTime.now();
        _debts = [
          DebtModel(
            id: 'debt_1',
            type: DebtType.receivable,
            personName: 'Carlos Mamani',
            phoneNumber: '78945612',
            totalAmount: 600.00,
            remainingAmount: 450.00,
            dueDate: now.add(const Duration(days: 7)),
            concept: '1 docena parkas térmicas al crédito',
            status: DebtStatus.partial,
            payments: [
              DebtPayment(
                id: 'pay_1',
                amount: 150.00,
                date: now.subtract(const Duration(days: 2)),
                accountId: 'acc_union',
                accountName: 'Banco Unión (QR)',
                note: 'Primer abono por QR',
              ),
            ],
            createdAt: now.subtract(const Duration(days: 10)),
          ),
          DebtModel(
            id: 'debt_2',
            type: DebtType.receivable,
            personName: 'Doña Elena (Feria)',
            phoneNumber: '71234567',
            totalAmount: 280.00,
            remainingAmount: 280.00,
            dueDate: now.add(const Duration(days: 4)),
            concept: 'Ropa fiada puesto 42',
            status: DebtStatus.pending,
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          DebtModel(
            id: 'debt_3',
            type: DebtType.payable,
            personName: 'Distribuidora La Paz (Insumos)',
            phoneNumber: '65432198',
            totalAmount: 1200.00,
            remainingAmount: 800.00,
            dueDate: now.add(const Duration(days: 12)),
            concept: 'Lote fardo de invierno cuota 2/3',
            status: DebtStatus.partial,
            payments: [
              DebtPayment(
                id: 'pay_prov_1',
                amount: 400.00,
                date: now.subtract(const Duration(days: 3)),
                accountId: 'acc_union',
                accountName: 'Banco Unión (QR)',
                note: 'Pago cuota inicial',
              ),
            ],
            createdAt: now.subtract(const Duration(days: 15)),
          ),
        ];
        await _saveDebts();
      }
    } catch (e) {
      debugPrint('Error al cargar deudas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDebts() async {
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
      // 1. Ingresa el dinero recibido a tu cuenta bancaria o efectivo
      await accountsProvider.adjustBalance(accountId, actualPayment);

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
      // Si era una cuenta por pagar a proveedor, descuenta de tu cuenta
      await accountsProvider.adjustBalance(accountId, -actualPayment);

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
