import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../models/debt.dart';
import '../providers/debts_provider.dart';

class RecordDebtPaymentSheet extends StatefulWidget {
  final DebtModel debt;

  const RecordDebtPaymentSheet({
    super.key,
    required this.debt,
  });

  static Future<void> show(BuildContext context, {required DebtModel debt}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordDebtPaymentSheet(debt: debt),
    );
  }

  @override
  State<RecordDebtPaymentSheet> createState() => _RecordDebtPaymentSheetState();
}

class _RecordDebtPaymentSheetState extends State<RecordDebtPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final accountsProv = Provider.of<AccountsProvider>(context, listen: false);
    final accounts = accountsProv.operationalAccounts;
    if (accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _executePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una cuenta para el abono.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    final accountsProv = Provider.of<AccountsProvider>(context, listen: false);
    final txProv = Provider.of<TransactionsProvider>(context, listen: false);
    final debtsProv = Provider.of<DebtsProvider>(context, listen: false);

    final account = accountsProv.accounts.firstWhere((a) => a.id == _selectedAccountId);

    final success = await debtsProv.recordPayment(
      debtId: widget.debt.id,
      paymentAmount: amount,
      accountId: account.id,
      accountName: account.name,
      accountsProvider: accountsProv,
      transactionsProvider: txProv,
      note: _noteController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        final isReceivable = widget.debt.type == DebtType.receivable;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              isReceivable
                  ? '¡Abono de ${AccountsProvider.formatAmount(amount)} ingresado a ${account.name} y descontado de la deuda!'
                  : '¡Pago de ${AccountsProvider.formatAmount(amount)} registrado y debitado de ${account.name}!',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accountsProv = Provider.of<AccountsProvider>(context);
    final operationalAccounts = accountsProv.operationalAccounts;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isReceivable = widget.debt.type == DebtType.receivable;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isReceivable ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isReceivable ? 'Registrar Abono' : 'Registrar Pago a Proveedor',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información del deudor y saldo pendiente
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.debt.personName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                        ),
                        if (widget.debt.concept != null)
                          Text(
                            widget.debt.concept!,
                            style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Saldo pendiente',
                          style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                        ),
                        Text(
                          AccountsProvider.formatAmount(widget.debt.remainingAmount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Monto a abonar (CU-3.2)
              Text(
                'Monto del abono (Bs)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'Bs  ',
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  helperText: 'El saldo se recalculará automáticamente',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el monto del abono';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Monto no válido';
                  if (parsed > widget.debt.remainingAmount) {
                    return 'El abono supera el saldo pendiente (${AccountsProvider.formatAmount(widget.debt.remainingAmount)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Botón rápido para abonar todo el saldo restante
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _amountController.text = widget.debt.remainingAmount.toStringAsFixed(2);
                    });
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 14),
                  label: const Text('Liquidar saldo total', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(height: 8),

              // Cuenta donde entra o sale el dinero
              Text(
                isReceivable
                    ? '¿A qué cuenta ingresa el dinero?'
                    : '¿De qué cuenta se debitará el pago?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    dropdownColor: tokens.cardBg,
                    items: operationalAccounts.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Row(
                          children: [
                            Icon(acc.icon, size: 18, color: acc.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${acc.name} (${AccountsProvider.formatAmount(acc.balance)})',
                                style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAccountId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nota opcional
              Text(
                'Nota / Detalle (Opcional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Ej: Abono en efectivo o captura QR',
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar Abono
              ElevatedButton(
                onPressed: _isSaving ? null : _executePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isReceivable ? 'Ingresar Abono a Cuenta' : 'Registrar Pago a Proveedor',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
