import '../../../core/services/finance_api_service.dart';
import '../../transactions/providers/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../providers/accounts_provider.dart';

class TransferFundsSheet extends StatefulWidget {
  final String? initialOriginId;
  final String? initialDestinationId;

  const TransferFundsSheet({
    super.key,
    this.initialOriginId,
    this.initialDestinationId,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialOriginId,
    String? initialDestinationId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransferFundsSheet(
        initialOriginId: initialOriginId,
        initialDestinationId: initialDestinationId,
      ),
    );
  }

  @override
  State<TransferFundsSheet> createState() => _TransferFundsSheetState();
}

class _TransferFundsSheetState extends State<TransferFundsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _originId;
  String? _destinationId;
  final _draftId = FinanceApiService.newId('tx');
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AccountsProvider>(context, listen: false);
    final allAccounts = provider.accounts;

    if (allAccounts.isNotEmpty) {
      _originId = widget.initialOriginId ??
          (provider.operationalAccounts.isNotEmpty
              ? provider.operationalAccounts.first.id
              : allAccounts.first.id);

      final otherAccounts = allAccounts.where((a) => a.id != _originId).toList();
      _destinationId = widget.initialDestinationId ??
          (otherAccounts.isNotEmpty ? otherAccounts.first.id : null);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originId == null || _destinationId == null) return;
    if (_originId == _destinationId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cuenta origen y destino deben ser distintas.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isTransferring = true);
    final provider = Provider.of<AccountsProvider>(context, listen: false);
    try {
      await context.read<TransactionsProvider>().recordTransfer(
        accountsProvider: provider,
        originAccountId: _originId!,
        destinationAccountId: _destinationId!,
        amount: amount,
        transactionId: _draftId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transferencia guardada en la nube.')),
      );
    } on FinanceSyncException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final provider = Provider.of<AccountsProvider>(context);
    final allAccounts = provider.accounts;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final originAccount = allAccounts.firstWhere(
      (a) => a.id == _originId,
      orElse: () => allAccounts.first,
    );

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mover entre cuentas propias',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Mueve dinero entre tu banco, efectivo o a una bóveda de ahorro sin que cuente como gasto.',
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
              const SizedBox(height: 20),

              // Selector Cuenta Origen
              Text(
                'Desde (Cuenta Origen)',
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
                    value: _originId,
                    isExpanded: true,
                    dropdownColor: tokens.cardBg,
                    items: allAccounts.map((acc) {
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
                      if (val != null) setState(() => _originId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Icono central de intercambio
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_downward_rounded, color: Theme.of(context).primaryColor, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Selector Cuenta Destino
              Text(
                'Hacia (Cuenta Destino / Bóveda)',
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
                    value: _destinationId,
                    isExpanded: true,
                    dropdownColor: tokens.cardBg,
                    items: allAccounts.map((acc) {
                      final isOrigin = acc.id == _originId;
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        enabled: !isOrigin,
                        child: Row(
                          children: [
                            Icon(acc.icon, size: 18, color: isOrigin ? tokens.textSecondary.withOpacity(0.3) : acc.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${acc.name} (${AccountsProvider.formatAmount(acc.balance)})${acc.isSavingsVault ? " 🔒" : ""}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isOrigin ? tokens.textSecondary.withOpacity(0.4) : tokens.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _destinationId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Monto a transferir
              Text(
                'Monto a mover (Bs)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'Bs  ',
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  helperText: 'Disponible en origen: ${AccountsProvider.formatAmount(originAccount.balance)}',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Monto no válido';
                  if (parsed > originAccount.balance) return 'Supera el saldo disponible';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón transferir
              ElevatedButton(
                onPressed: _isTransferring ? null : _executeTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isTransferring
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirmar Movimiento Interno',
                        style: TextStyle(
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
