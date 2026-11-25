import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../widgets/create_batch_product_sheet.dart';
import '../widgets/quick_sale_sheet.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _showDeleteDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Estás seguro de que deseas eliminar "${product.name}" del inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Provider.of<InventoryProvider>(context, listen: false).deleteProduct(product.id);
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
    final inventoryProv = Provider.of<InventoryProvider>(context);

    final totalInvested = inventoryProv.totalCapitalInvested;
    final totalRecovered = inventoryProv.totalCapitalRecovered;
    final recoveryPercent = inventoryProv.globalRecoveryPercentage;
    final netProfit = inventoryProv.totalNetProfit;
    final isProfitable = netProfit > 0;

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
                              'Inventario & Escalas (Módulo 5)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              'Lotes mayoristas, escandallo x6/x12 y venta rápida',
                              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 26),
                        tooltip: 'Venta Rápida',
                        onPressed: () => QuickSaleSheet.show(context),
                      ),
                    ],
                  ),
                ),
              ),

              // CU-5.5: Métrica de Capital Invertido vs. Recuperado
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                            Row(
                              children: [
                                const Icon(Icons.query_stats_rounded, size: 18, color: Color(0xFF3366D6)),
                                const SizedBox(width: 6),
                                Text(
                                  'Capital Invertido vs. Recuperado',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (recoveryPercent >= 100 ? const Color(0xFF10B981) : const Color(0xFF3366D6)).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${recoveryPercent.toStringAsFixed(1)}% recuperado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: recoveryPercent >= 100 ? const Color(0xFF10B981) : const Color(0xFF3366D6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Barra de progreso de recuperación
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (recoveryPercent / 100).clamp(0.0, 1.0),
                            backgroundColor: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              recoveryPercent >= 100 ? const Color(0xFF10B981) : const Color(0xFF3366D6),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cifras Claves
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Capital Invertido', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                                  Text(
                                    AccountsProvider.formatAmount(totalInvested),
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Capital Recuperado', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                                  Text(
                                    AccountsProvider.formatAmount(totalRecovered),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ganancia Neta', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                                  Text(
                                    '${isProfitable ? "+" : ""}${AccountsProvider.formatAmount(netProfit)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isProfitable ? const Color(0xFF10B981) : Colors.orangeAccent,
                                    ),
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

              // Encabezado de Productos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lotes en Stock (${inventoryProv.products.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Nuevo Lote'),
                        onPressed: () => CreateBatchProductSheet.show(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de Productos
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = inventoryProv.products[index];
                      return _ProductCard(
                        product: product,
                        onQuickSale: () => QuickSaleSheet.show(context, preselectedProduct: product),
                        onDelete: () => _showDeleteDialog(context, product),
                      );
                    },
                    childCount: inventoryProv.products.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickSaleSheet.show(context),
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
        label: const Text(
          'Venta Rápida',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onQuickSale;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onQuickSale,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: product.isLowStock
              ? Colors.redAccent.withOpacity(0.4)
              : (tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Nombre, Empaque y Menú
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_outlined, color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                    ),
                    Text(
                      'Lote: ${product.batchQuantity} piezas (${product.batchPackageType}) • Total: ${AccountsProvider.formatAmount(product.totalPurchaseCost)}',
                      style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isLowStock ? Colors.redAccent.withOpacity(0.12) : const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${product.stockUnits} u. stock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: product.isLowStock ? Colors.redAccent : const Color(0xFF10B981),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: tokens.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: tokens.cardBg,
                onSelected: (val) {
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Eliminar Lote', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // TABLA DE ESCANDALLO Y PRECIOS DE VENTA (CU-5.2 y CU-5.3)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Escala', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSecondary)),
                    Text('Costo Lote', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSecondary)),
                    Text('Precio Venta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSecondary)),
                    Text('Margen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSecondary)),
                  ],
                ),
                const Divider(height: 14),
                _ScaleRow(
                  scaleLabel: 'Unidad (x1)',
                  cost: product.unitCost,
                  salePrice: product.salePriceUnit,
                  margin: product.unitMarginPercent,
                ),
                const SizedBox(height: 6),
                _ScaleRow(
                  scaleLabel: 'Media Doc (x6)',
                  cost: product.halfDozenCost,
                  salePrice: product.salePriceHalfDozen,
                  margin: product.halfDozenMarginPercent,
                ),
                const SizedBox(height: 6),
                _ScaleRow(
                  scaleLabel: 'Docena (x12)',
                  cost: product.dozenCost,
                  salePrice: product.salePriceDozen,
                  margin: product.dozenMarginPercent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Fila 3: Recuperación de capital de este producto y Botón Venta Rápida (CU-5.4)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recuperado: ${AccountsProvider.formatAmount(product.capitalRecovered)} (${product.capitalRecoveryPercent.toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (product.capitalRecoveryPercent / 100).clamp(0.0, 1.0),
                        backgroundColor: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          product.isCapitalFullyRecovered ? const Color(0xFF10B981) : Theme.of(context).primaryColor,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onQuickSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.flash_on_rounded, size: 14, color: Colors.white),
                label: const Text(
                  'Venta Rápida',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  final String scaleLabel;
  final double cost;
  final double salePrice;
  final double margin;

  const _ScaleRow({
    required this.scaleLabel,
    required this.cost,
    required this.salePrice,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(scaleLabel, style: TextStyle(fontSize: 11, color: tokens.textPrimary)),
        Text(AccountsProvider.formatAmount(cost), style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
        Text(AccountsProvider.formatAmount(salePrice), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${margin.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
          ),
        ),
      ],
    );
  }
}
