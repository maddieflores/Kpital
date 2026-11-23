import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../widgets/create_edit_account_sheet.dart';
import '../widgets/transfer_funds_sheet.dart';

class AccountsManagerScreen extends StatelessWidget {
  const AccountsManagerScreen({super.key});

  void _showDeleteDialog(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${account.isSavingsVault ? "bóveda" : "cuenta"}'),
        content: Text('¿Estás seguro de que deseas eliminar "${account.name}"? Los datos y saldos vinculados se perderán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Provider.of<AccountsProvider>(context, listen: false).deleteAccount(account.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primaryColor = Theme.of(context).primaryColor;
    final provider = Provider.of<AccountsProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: tokens.scaffoldBg,
          gradient: tokens.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // AppBar
              SliverToBoxAdapter(
                child: Padding(
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
                              'Gestor de Cuentas y Bóvedas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              'Organiza tu capital diario y tus ahorros protegidos',
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.compare_arrows_rounded, color: primaryColor),
                        tooltip: 'Mover entre cuentas',
                        onPressed: () => TransferFundsSheet.show(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Resumen Patrimonial (CU-4.3 & CU-4.4)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.balanceCardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.balanceCardBg.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Patrimonio Total (CU-4.4)',
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.balanceCardText.withOpacity(0.85),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Bancos + Efectivo + Bóvedas',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.balanceCardText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AccountsProvider.formatAmount(provider.totalPatrimony),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: tokens.balanceCardText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: tokens.balanceCardText.withOpacity(0.18),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.wallet_outlined, size: 14, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Disponible para gastar',
                                        style: TextStyle(fontSize: 11, color: tokens.balanceCardText.withOpacity(0.85)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AccountsProvider.formatAmount(provider.availableBalance),
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tokens.balanceCardText),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.amberAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Protegido en Bóvedas',
                                        style: TextStyle(fontSize: 11, color: tokens.balanceCardText.withOpacity(0.85)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AccountsProvider.formatAmount(provider.vaultsTotal),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sección 1: Cuentas Operativas (CU-4.1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 18, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Cuentas Operativas (${provider.operationalAccounts.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Nueva Cuenta'),
                        onPressed: () => CreateEditAccountSheet.show(context, initialIsVault: false),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final account = provider.operationalAccounts[index];
                      return _AccountCard(
                        account: account,
                        onEdit: () => CreateEditAccountSheet.show(context, accountToEdit: account),
                        onDelete: () => _showDeleteDialog(context, account),
                        onTransfer: () => TransferFundsSheet.show(context, initialOriginId: account.id),
                      );
                    },
                    childCount: provider.operationalAccounts.length,
                  ),
                ),
              ),

              // Sección 2: Bóvedas de Ahorro y Metas (CU-4.2 & CU-4.3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_rounded, size: 18, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 6),
                          Text(
                            'Bóvedas de Ahorro Protegidas (${provider.savingsVaults.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_task_rounded, size: 16),
                        label: const Text('Nueva Bóveda'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
                        onPressed: () => CreateEditAccountSheet.show(context, initialIsVault: true),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final vault = provider.savingsVaults[index];
                      return _VaultCard(
                        vault: vault,
                        onEdit: () => CreateEditAccountSheet.show(context, accountToEdit: vault),
                        onDelete: () => _showDeleteDialog(context, vault),
                        onDeposit: () => TransferFundsSheet.show(context, initialDestinationId: vault.id),
                      );
                    },
                    childCount: provider.savingsVaults.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 60),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TransferFundsSheet.show(context),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
        label: const Text(
          'Mover Dinero',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTransfer;

  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: account.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(account.icon, color: account.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account.type.label,
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AccountsProvider.formatAmount(account.balance),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Disponible',
                style: TextStyle(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: tokens.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: tokens.cardBg,
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'transfer') onTransfer();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'transfer',
                child: Row(
                  children: [
                    Icon(Icons.compare_arrows_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Transferir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
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
    );
  }
}

class _VaultCard extends StatelessWidget {
  final Account vault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDeposit;

  const _VaultCard({
    required this.vault,
    required this.onEdit,
    required this.onDelete,
    required this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final percent = vault.progressPercentage;
    final percentInt = (percent * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_rounded, color: Color(0xFF8B5CF6), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vault.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Bloqueado',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Meta: ${AccountsProvider.formatAmount(vault.targetAmount ?? 0.0)}',
                      style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AccountsProvider.formatAmount(vault.balance),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$percentInt% alcanzado',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: tokens.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: tokens.cardBg,
                onSelected: (val) {
                  if (val == 'deposit') onDeposit();
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'deposit',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF8B5CF6)),
                        SizedBox(width: 8),
                        Text('Depositar a Bóveda'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Editar Meta'),
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
