import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../models/transaction.dart';
import '../providers/transactions_provider.dart';
import '../widgets/record_income_sheet.dart';
import '../widgets/receipt_viewer_dialog.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final txProv = Provider.of<TransactionsProvider>(context);
    final accountsProv = Provider.of<AccountsProvider>(context);

    final transactions = txProv.filteredTransactions;
    DateFormat dateFormat;
    try {
      dateFormat = DateFormat('dd MMM, hh:mm a', 'es_ES');
    } catch (_) {
      dateFormat = DateFormat('dd/MM/yyyy, hh:mm a');
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: tokens.scaffoldBg,
          gradient: tokens.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Encabezado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: tokens.textPrimary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Movimientos & Transferencias',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                          ),
                          Text(
                            'Historial de ingresos QR, gastos y transferencias',
                            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF10B981), size: 28),
                      tooltip: 'Registrar Transferencia Recibida',
                      onPressed: () => RecordIncomeSheet.show(context),
                    ),
                  ],
                ),
              ),

              // Buscador por Persona o Concepto (CU-1.4)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  onChanged: (val) => txProv.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Buscar por remitente o concepto...',
                    hintStyle: TextStyle(fontSize: 13, color: tokens.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, color: tokens.textSecondary),
                    suffixIcon: txProv.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => txProv.setSearchQuery(''),
                          )
                        : null,
                    filled: true,
                    fillColor: tokens.cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Filtros por Período de Tiempo (CU-1.4)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _PeriodFilterChip(
                      label: 'Todos',
                      isSelected: txProv.selectedPeriod == DateFilterPeriod.all,
                      onTap: () => txProv.setPeriodFilter(DateFilterPeriod.all),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterChip(
                      label: 'Hoy',
                      isSelected: txProv.selectedPeriod == DateFilterPeriod.today,
                      onTap: () => txProv.setPeriodFilter(DateFilterPeriod.today),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterChip(
                      label: 'Esta Semana',
                      isSelected: txProv.selectedPeriod == DateFilterPeriod.thisWeek,
                      onTap: () => txProv.setPeriodFilter(DateFilterPeriod.thisWeek),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterChip(
                      label: 'Este Mes',
                      isSelected: txProv.selectedPeriod == DateFilterPeriod.thisMonth,
                      onTap: () => txProv.setPeriodFilter(DateFilterPeriod.thisMonth),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Lista de Transacciones Filtradas
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: tokens.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron transferencias',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: tokens.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Prueba cambiando los filtros o registra un nuevo ingreso.',
                              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isIncome = tx.type == TransactionType.income;
                          final isTransfer = tx.type == TransactionType.transfer;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: tokens.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: tokens.isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Icono de tipo
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: tx.type.color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward_rounded
                                        : isTransfer
                                            ? Icons.compare_arrows_rounded
                                            : Icons.arrow_upward_rounded,
                                    color: tx.type.color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Datos: Remitente y cuenta de destino
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.contactName?.isNotEmpty == true
                                            ? tx.contactName!
                                            : (tx.description ?? 'Movimiento'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: tokens.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (tx.contactName?.isNotEmpty == true &&
                                          tx.description?.isNotEmpty == true &&
                                          tx.description != "Transferencia recibida") ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          tx.description!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: tokens.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.account_balance_rounded, size: 12, color: tokens.textSecondary),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              tx.destinationAccountName != null
                                                  ? '${tx.accountName} ➔ ${tx.destinationAccountName}'
                                                  : tx.accountName,
                                              style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(tx.transactionDate),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: tokens.textSecondary.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Monto y comprobante
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isIncome ? "+" : isTransfer ? "" : "-"}${AccountsProvider.formatAmount(tx.amount)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: tx.type.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // Botón de Comprobante QR (CU-1.2)
                                    if (tx.receiptImagePath != null)
                                      InkWell(
                                        onTap: () => ReceiptViewerDialog.show(
                                          context,
                                          imagePath: tx.receiptImagePath!,
                                          title: 'Comprobante de ${tx.contactName ?? tx.accountName}',
                                          amountFormatted: AccountsProvider.formatAmount(tx.amount),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.receipt_long_rounded, size: 12, color: Theme.of(context).primaryColor),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Ver QR',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                // Menú eliminar
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, size: 18, color: tokens.textSecondary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: tokens.cardBg,
                                  onSelected: (val) async {
                                    if (val == 'delete') {
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        await txProv.deleteTransaction(
                                          transactionId: tx.id,
                                          accountsProvider: accountsProv,
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Movimiento eliminado y saldo recalculado.')),
                                        );
                                      } on FinanceSyncException catch (error) {
                                        messenger.showSnackBar(SnackBar(content: Text(error.message)));
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                          SizedBox(width: 8),
                                          Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => RecordIncomeSheet.show(context),
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.arrow_downward_rounded, color: Colors.white),
        label: const Text(
          'Transferencia Recibida',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _PeriodFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : tokens.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : tokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
