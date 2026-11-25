import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../ads/widgets/ad_banner_widget.dart';
import '../models/transaction.dart';
import '../providers/transactions_provider.dart';
import '../widgets/record_expense_sheet.dart';

class ExpensesAnalyticsScreen extends StatefulWidget {
  const ExpensesAnalyticsScreen({super.key});

  @override
  State<ExpensesAnalyticsScreen> createState() => _ExpensesAnalyticsScreenState();
}

class _ExpensesAnalyticsScreenState extends State<ExpensesAnalyticsScreen> {
  int _touchedIndex = -1;

  final List<Color> _palette = [
    const Color(0xFF3366D6), // Azul
    const Color(0xFFF59E0B), // Ámbar
    const Color(0xFF10B981), // Verde
    const Color(0xFFEC4899), // Rosa
    const Color(0xFF8B5CF6), // Violeta
    const Color(0xFF06B6D4), // Cian
    const Color(0xFFF97316), // Naranja
    const Color(0xFFEF4444), // Rojo
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final txProv = Provider.of<TransactionsProvider>(context);

    final totalExpenses = txProv.monthlyExpenses;
    final fixedExpenses = txProv.monthlyFixedExpenses;
    final antExpenses = txProv.monthlyAntExpenses;
    final categoryTotals = txProv.monthlyExpensesByCategory;
    final categoryPercentages = txProv.monthlyCategoryPercentages;

    final antPercentage = totalExpenses > 0 ? (antExpenses / totalExpenses) * 100 : 0.0;
    final fixedPercentage = totalExpenses > 0 ? (fixedExpenses / totalExpenses) * 100 : 0.0;

    final categoriesList = categoryTotals.keys.toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: tokens.scaffoldBg,
          gradient: tokens.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Encabezado
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
                              'Análisis de Gastos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              'Distribución porcentual y control de gastos hormiga',
                              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFEF4444), size: 28),
                        tooltip: 'Registrar Gasto Rápido',
                        onPressed: () => RecordExpenseSheet.show(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Tarjeta Resumen: Fijos vs Hormiga (CU-2.2)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total egresos este mes',
                          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AccountsProvider.formatAmount(totalExpenses),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Gasto Fijo
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3366D6).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.home_work_outlined, size: 14, color: Color(0xFF3366D6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Gastos Fijos',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AccountsProvider.formatAmount(fixedExpenses),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3366D6)),
                                    ),
                                    Text(
                                      '${fixedPercentage.toStringAsFixed(1)}% del total',
                                      style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Gasto Hormiga (CU-2.2)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.fastfood_outlined, size: 14, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Gastos Hormiga 🐜',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AccountsProvider.formatAmount(antExpenses),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                    ),
                                    Text(
                                      '${antPercentage.toStringAsFixed(1)}% del total',
                                      style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // CU-2.3: Gráfico Circular Interactivo (PieChart)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Distribución Porcentual',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3366D6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Mensual',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3366D6)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Renderizado del Gráfico Circular
                        if (totalExpenses <= 0)
                          Container(
                            height: 180,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pie_chart_outline_rounded, size: 48, color: tokens.textSecondary.withOpacity(0.4)),
                                const SizedBox(height: 8),
                                Text(
                                  'Aún no hay gastos registrados este mes',
                                  style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 44,
                                sections: List.generate(categoriesList.length, (i) {
                                  final isTouched = i == _touchedIndex;
                                  final fontSize = isTouched ? 14.0 : 11.0;
                                  final radius = isTouched ? 65.0 : 55.0;
                                  final cat = categoriesList[i];
                                  final percent = categoryPercentages[cat] ?? 0.0;
                                  final color = _palette[i % _palette.length];

                                  return PieChartSectionData(
                                    color: color,
                                    value: percent,
                                    title: '${percent.toStringAsFixed(0)}%',
                                    radius: radius,
                                    titleStyle: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Leyenda con montos y porcentajes
                        Column(
                          children: List.generate(categoriesList.length, (i) {
                            final cat = categoriesList[i];
                            final amount = categoryTotals[cat] ?? 0.0;
                            final percent = categoryPercentages[cat] ?? 0.0;
                            final color = _palette[i % _palette.length];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat,
                                      style: TextStyle(fontSize: 12, color: tokens.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${AccountsProvider.formatAmount(amount)} (${percent.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Lista de Gastos del Mes
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
                  child: Text(
                    'Detalle de Gastos del Mes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expenses = txProv.allTransactions
                          .where((t) => t.type == TransactionType.expense)
                          .toList();

                      if (expenses.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No hay gastos registrados',
                              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                            ),
                          ),
                        );
                      }

                      final tx = expenses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tokens.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tx.isEssential
                                    ? const Color(0xFF3366D6).withOpacity(0.1)
                                    : const Color(0xFFF59E0B).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tx.isEssential ? Icons.home_work_outlined : Icons.cookie_outlined,
                                size: 16,
                                color: tx.isEssential ? const Color(0xFF3366D6) : const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description ?? 'Gasto',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                                  ),
                                  Text(
                                    '${tx.category ?? "General"} • ${tx.isEssential ? "Fijo" : "Hormiga 🐜"} • ${tx.accountName}',
                                    style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '-${AccountsProvider.formatAmount(tx.amount)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: txProv.allTransactions
                        .where((t) => t.type == TransactionType.expense)
                        .length,
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
      bottomNavigationBar: const AdBannerWidget(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => RecordExpenseSheet.show(context),
        backgroundColor: const Color(0xFFEF4444),
        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
        label: const Text(
          'Registrar Gasto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
