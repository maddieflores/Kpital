import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../models/debt.dart';
import '../providers/debts_provider.dart';
import '../utils/whatsapp_helper.dart';
import '../widgets/create_debt_sheet.dart';
import '../widgets/record_debt_payment_sheet.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  void _showDeleteDialog(BuildContext context, DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Estás seguro de que deseas eliminar la cuenta de "${debt.personName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Provider.of<DebtsProvider>(context, listen: false).deleteDebt(debt.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPaymentsHistory(BuildContext context, DebtModel debt) {
    final tokens = context.tokens;
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de Abonos - ${debt.personName}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (debt.payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Aún no se han registrado abonos a esta deuda.', style: TextStyle(color: tokens.textSecondary)),
                ),
              )
            else
              ...debt.payments.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(p.date),
                            style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                          ),
                          Text(
                            'Ingresado a: ${p.accountName}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                          ),
                          if (p.note != null && p.note!.isNotEmpty)
                            Text(p.note!, style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                        ],
                      ),
                      Text(
                        '+${AccountsProvider.formatAmount(p.amount)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final debtsProv = Provider.of<DebtsProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: tokens.scaffoldBg,
            gradient: tokens.backgroundGradient,
          ),
          child: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // Encabezado
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Préstamos y Deudas',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Cuentas por cobrar, abonos y cobrador de WhatsApp',
                                  style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF3366D6), size: 30),
                            tooltip: 'Nueva Deuda',
                            onPressed: () => CreateDebtSheet.show(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Resumen Superior (Me deben vs Debo)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          // Por Cobrar (Me deben)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: tokens.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Me deben (Cobrar)',
                                        style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AccountsProvider.formatAmount(debtsProv.totalReceivable),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  Text(
                                    '${debtsProv.receivables.length} personas',
                                    style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Por Pagar (Debo)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: tokens.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Debo (Pagar)',
                                        style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AccountsProvider.formatAmount(debtsProv.totalPayable),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  Text(
                                    '${debtsProv.payables.length} proveedores',
                                    style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // TabBar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: tokens.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: tokens.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          labelColor: tokens.textPrimary,
                          unselectedLabelColor: tokens.textSecondary,
                          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          tabs: [
                            Tab(text: "Me deben (${debtsProv.receivables.length})"),
                            Tab(text: "Debo a otros (${debtsProv.payables.length})"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _DebtListView(
                    debts: debtsProv.receivables,
                    emptyMessage: 'Nadie te debe dinero actualmente. ¡Finanzas al día!',
                    onDelete: (d) => _showDeleteDialog(context, d),
                    onShowHistory: (d) => _showPaymentsHistory(context, d),
                  ),
                  _DebtListView(
                    debts: debtsProv.payables,
                    emptyMessage: 'No tienes deudas pendientes con proveedores.',
                    onDelete: (d) => _showDeleteDialog(context, d),
                    onShowHistory: (d) => _showPaymentsHistory(context, d),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => CreateDebtSheet.show(context),
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Nueva Deuda / Fiado',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _DebtListView extends StatelessWidget {
  final List<DebtModel> debts;
  final String emptyMessage;
  final Function(DebtModel) onDelete;
  final Function(DebtModel) onShowHistory;

  const _DebtListView({
    required this.debts,
    required this.emptyMessage,
    required this.onDelete,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (debts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handshake_outlined, size: 48, color: tokens.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80, top: 4),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        return _DebtCardWidget(
          debt: debt,
          onDelete: () => onDelete(debt),
          onShowHistory: () => onShowHistory(debt),
        );
      },
    );
  }
}

class _DebtCardWidget extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onDelete;
  final VoidCallback onShowHistory;

  const _DebtCardWidget({
    required this.debt,
    required this.onDelete,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isReceivable = debt.type == DebtType.receivable;
    final percent = debt.progressPercentage;
    final percentInt = (percent * 100).toInt();
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Nombre, Badge y Menú
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isReceivable ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                    ),
                    if (debt.concept != null && debt.concept!.isNotEmpty)
                      Text(
                        debt.concept!,
                        style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AccountsProvider.formatAmount(debt.remainingAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  Text(
                    'de ${AccountsProvider.formatAmount(debt.totalAmount)}',
                    style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: tokens.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: tokens.cardBg,
                onSelected: (val) {
                  if (val == 'history') onShowHistory();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Ver historial abonos'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Fila 2: Barra de progreso de pago si hubo abonos
          if (debt.payments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Abonado: ${AccountsProvider.formatAmount(debt.paidAmount)} ($percentInt%)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                ),
                Text(
                  '${debt.payments.length} abonos',
                  style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                minHeight: 6,
              ),
            ),
          ],

          const SizedBox(height: 12),
          Container(height: 1, color: tokens.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
          const SizedBox(height: 12),

          // Fila 3: Vencimiento y Botones de Acción (Abonar CU-3.2 y WhatsApp CU-3.3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fecha límite
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: tokens.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    debt.dueDate != null ? 'Vence: ${dateFormat.format(debt.dueDate!)}' : 'Sin fecha fija',
                    style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                  ),
                ],
              ),

              // Botones de Acción
              Row(
                children: [
                  // CU-3.3: Cobrador de WhatsApp
                  if (isReceivable && debt.phoneNumber != null && debt.phoneNumber!.isNotEmpty)
                    InkWell(
                      onTap: () async {
                        final sent = await WhatsAppHelper.sendReminder(debt);
                        if (!sent && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_rounded, size: 14, color: Color(0xFF25D366)),
                            SizedBox(width: 4),
                            Text(
                              'Cobrar WhatsApp',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF25D366)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),

                  // CU-3.2: Registrar Abono
                  ElevatedButton.icon(
                    onPressed: () => RecordDebtPaymentSheet.show(context, debt: debt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.payment_rounded, size: 14, color: Colors.white),
                    label: Text(
                      isReceivable ? 'Abonar' : 'Pagar',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
