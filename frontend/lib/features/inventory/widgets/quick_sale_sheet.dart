import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';

class QuickSaleSheet extends StatefulWidget {
  final ProductModel? preselectedProduct;

  const QuickSaleSheet({
    super.key,
    this.preselectedProduct,
  });

  static Future<void> show(BuildContext context, {ProductModel? preselectedProduct}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickSaleSheet(preselectedProduct: preselectedProduct),
    );
  }

  @override
  State<QuickSaleSheet> createState() => _QuickSaleSheetState();
}

class _QuickSaleSheetState extends State<QuickSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');

  String? _selectedProductId;
  SaleScale _selectedScale = SaleScale.dozen;
  String _paymentMethod = 'QR';
  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final inventoryProv = Provider.of<InventoryProvider>(context, listen: false);
    final accountsProv = Provider.of<AccountsProvider>(context, listen: false);

    if (inventoryProv.products.isNotEmpty) {
      _selectedProductId = widget.preselectedProduct?.id ?? inventoryProv.products.first.id;
    }

    if (accountsProv.operationalAccounts.isNotEmpty) {
      _selectedAccountId = accountsProv.operationalAccounts.first.id;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _executeSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null || _selectedAccountId == null) return;

    final qty = int.tryParse(_quantityController.text) ?? 1;
    if (qty <= 0) return;

    setState(() => _isSaving = true);

    final inventoryProv = Provider.of<InventoryProvider>(context, listen: false);
    final accountsProv = Provider.of<AccountsProvider>(context, listen: false);
    final txProv = Provider.of<TransactionsProvider>(context, listen: false);

    final account = accountsProv.accounts.firstWhere((a) => a.id == _selectedAccountId);

    final success = await inventoryProv.recordQuickSale(
      productId: _selectedProductId!,
      scale: _selectedScale,
      scaleQuantity: qty,
      accountId: account.id,
      accountName: account.name,
      paymentMethod: _paymentMethod,
      accountsProvider: accountsProv,
      transactionsProvider: txProv,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('¡Venta registrada con éxito! Ingreso acreditado a ${account.name} y stock actualizado.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Stock insuficiente para realizar esta venta.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final inventoryProv = Provider.of<InventoryProvider>(context);
    final accountsProv = Provider.of<AccountsProvider>(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final currentProduct = inventoryProv.products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => inventoryProv.products.first,
    );

    final qty = int.tryParse(_quantityController.text) ?? 1;
    final unitsDeducted = qty * _selectedScale.multiplier;

    double unitPrice;
    switch (_selectedScale) {
      case SaleScale.unit:
        unitPrice = currentProduct.salePriceUnit;
        break;
      case SaleScale.halfDozen:
        unitPrice = currentProduct.salePriceHalfDozen;
        break;
      case SaleScale.dozen:
        unitPrice = currentProduct.salePriceDozen;
        break;
      case SaleScale.batch:
        unitPrice = currentProduct.totalPurchaseCost;
        break;
    }

    final totalSaleAmount = unitPrice * qty;
    final totalCost = currentProduct.unitCost * unitsDeducted;
    final estimatedProfit = totalSaleAmount - totalCost;

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
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Venta Rápida de Negocio (CU-5.4)',
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
              const SizedBox(height: 14),

              // Selector de Producto
              Text(
                'Producto a vender',
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
                    value: _selectedProductId,
                    isExpanded: true,
                    dropdownColor: tokens.cardBg,
                    items: inventoryProv.products.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          '${p.name} (Stock: ${p.stockUnits} u.)',
                          style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProductId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Escala de Venta (Detalle, x6, x12)
              Text(
                'Escala de venta',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Unidad (x1)', style: TextStyle(fontSize: 11))),
                      selected: _selectedScale == SaleScale.unit,
                      onSelected: (_) => setState(() => _selectedScale = SaleScale.unit),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Media Doc (x6)', style: TextStyle(fontSize: 11))),
                      selected: _selectedScale == SaleScale.halfDozen,
                      onSelected: (_) => setState(() => _selectedScale = SaleScale.halfDozen),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Docena (x12)', style: TextStyle(fontSize: 11))),
                      selected: _selectedScale == SaleScale.dozen,
                      onSelected: (_) => setState(() => _selectedScale = SaleScale.dozen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Cantidad y Precio unitario
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cantidad a vender',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '1',
                            filled: true,
                            fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Ingresa cantidad';
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed <= 0) return 'No válido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio por ${_selectedScale.label}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            AccountsProvider.formatAmount(unitPrice),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Resumen Financiero de la Venta (CU-5.4)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total a cobrar:', style: TextStyle(fontSize: 13, color: tokens.textPrimary)),
                        Text(
                          AccountsProvider.formatAmount(totalSaleAmount),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Descuento de inventario:', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                        Text('$unitsDeducted unidades (Quedan: ${currentProduct.stockUnits - unitsDeducted})',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ganancia neta estimada:', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                        Text('+${AccountsProvider.formatAmount(estimatedProfit)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Método de Cobro y Cuenta Receptora
              Text(
                'Método de cobro',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('QR Simple / Banco'),
                    selected: _paymentMethod == 'QR',
                    onSelected: (_) => setState(() => _paymentMethod = 'QR'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Efectivo Mostrador'),
                    selected: _paymentMethod == 'Efectivo',
                    onSelected: (_) => setState(() => _paymentMethod = 'Efectivo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                '¿A qué cuenta ingresará el dinero cobrado? (CU-5.4)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
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
                    items: accountsProv.operationalAccounts.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Text(
                          '${acc.name} (${AccountsProvider.formatAmount(acc.balance)})',
                          style: TextStyle(fontSize: 12, color: tokens.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAccountId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Confirmar Venta
              ElevatedButton(
                onPressed: _isSaving ? null : _executeSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
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
                        'Registrar Venta por ${_paymentMethod.toUpperCase()}',
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
