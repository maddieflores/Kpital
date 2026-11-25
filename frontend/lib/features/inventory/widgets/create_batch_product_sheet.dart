import '../../../core/services/finance_api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../providers/inventory_provider.dart';

class CreateBatchProductSheet extends StatefulWidget {
  const CreateBatchProductSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateBatchProductSheet(),
    );
  }

  @override
  State<CreateBatchProductSheet> createState() => _CreateBatchProductSheetState();
}

class _CreateBatchProductSheetState extends State<CreateBatchProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _batchCostController = TextEditingController();
  final _batchQuantityController = TextEditingController();

  final _saleUnitController = TextEditingController();
  final _saleHalfDozenController = TextEditingController();
  final _saleDozenController = TextEditingController();

  String _packageType = 'fardo';
  String? _paidFromAccountId;
  final _draftId = FinanceApiService.newId('prod');
  final _createdAt = DateTime.now();
  bool _isSaving = false;

  final List<String> _packageOptions = ['fardo', 'caja', 'docena', 'paquete', 'bolsa'];

  // Escandallo en tiempo real (CU-5.2)
  double _unitCost = 0.0;
  double _halfDozenCost = 0.0;
  double _dozenCost = 0.0;

  @override
  void initState() {
    super.initState();
    _batchCostController.addListener(_calculateCosts);
    _batchQuantityController.addListener(_calculateCosts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _batchCostController.dispose();
    _batchQuantityController.dispose();
    _saleUnitController.dispose();
    _saleHalfDozenController.dispose();
    _saleDozenController.dispose();
    super.dispose();
  }

  void _calculateCosts() {
    final cost = double.tryParse(_batchCostController.text.replaceAll(',', '.')) ?? 0.0;
    final qty = int.tryParse(_batchQuantityController.text) ?? 0;

    if (cost > 0 && qty > 0) {
      final uCost = cost / qty;
      setState(() {
        _unitCost = double.parse(uCost.toStringAsFixed(2));
        _halfDozenCost = double.parse((uCost * 6).toStringAsFixed(2));
        _dozenCost = double.parse((uCost * 12).toStringAsFixed(2));

        // Si los campos de precio de venta están vacíos, sugerir márgenes estándar del mercado
        if (_saleUnitController.text.isEmpty) {
          _saleUnitController.text = (uCost * 1.5).toStringAsFixed(0); // Margen ~33%
        }
        if (_saleHalfDozenController.text.isEmpty) {
          _saleHalfDozenController.text = (_halfDozenCost * 1.35).toStringAsFixed(0);
        }
        if (_saleDozenController.text.isEmpty) {
          _saleDozenController.text = (_dozenCost * 1.25).toStringAsFixed(0);
        }
      });
    }
  }

  Future<void> _saveBatch() async {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.tryParse(_batchCostController.text.replaceAll(',', '.')) ?? 0.0;
    final qty = int.tryParse(_batchQuantityController.text) ?? 0;
    final saleUnit = double.tryParse(_saleUnitController.text.replaceAll(',', '.')) ?? 0.0;
    final saleHalfDozen = double.tryParse(_saleHalfDozenController.text.replaceAll(',', '.')) ?? 0.0;
    final saleDozen = double.tryParse(_saleDozenController.text.replaceAll(',', '.')) ?? 0.0;

    if (cost <= 0 || qty <= 0 || saleUnit <= 0) return;

    setState(() => _isSaving = true);

    final inventoryProv = Provider.of<InventoryProvider>(context, listen: false);
    final accountsProv = Provider.of<AccountsProvider>(context, listen: false);
    final txProv = Provider.of<TransactionsProvider>(context, listen: false);

    try {
      await inventoryProv.addProductBatch(
        productId: _draftId,
        createdAt: _createdAt,
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        batchPackageType: _packageType,
        batchQuantity: qty,
        totalPurchaseCost: cost,
        salePriceUnit: saleUnit,
        salePriceHalfDozen: saleHalfDozen > 0 ? saleHalfDozen : saleUnit * 6,
        salePriceDozen: saleDozen > 0 ? saleDozen : saleUnit * 12,
        paidFromAccountId: _paidFromAccountId,
        accountsProvider: accountsProv,
        transactionsProvider: txProv,
      );
    } on FinanceSyncException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('¡Lote "${_nameController.text}" registrado con escandallo automático!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accountsProv = Provider.of<AccountsProvider>(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Márgenes en tiempo real (CU-5.3)
    final saleUnit = double.tryParse(_saleUnitController.text.replaceAll(',', '.')) ?? 0.0;
    final saleHalf = double.tryParse(_saleHalfDozenController.text.replaceAll(',', '.')) ?? 0.0;
    final saleDoz = double.tryParse(_saleDozenController.text.replaceAll(',', '.')) ?? 0.0;

    final unitMargin = saleUnit > 0 && _unitCost > 0 ? (((saleUnit - _unitCost) / saleUnit) * 100) : 0.0;
    final halfMargin = saleHalf > 0 && _halfDozenCost > 0 ? (((saleHalf - _halfDozenCost) / saleHalf) * 100) : 0.0;
    final dozMargin = saleDoz > 0 && _dozenCost > 0 ? (((saleDoz - _dozenCost) / saleDoz) * 100) : 0.0;

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

              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.inventory_2_rounded, color: Theme.of(context).primaryColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cargar Lote Mayorista',
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
              const SizedBox(height: 16),

              // Nombre del producto
              Text(
                'Nombre del producto / lote',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ej: Fardo Parkas Térmicas #4',
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa el nombre del lote' : null,
              ),
              const SizedBox(height: 14),

              // Tipo de paquete
              Text(
                'Tipo de empaque',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _packageOptions.map((opt) {
                  final isSelected = _packageType == opt;
                  return ChoiceChip(
                    label: Text(opt.toUpperCase(), style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _packageType = opt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Costo Total del Lote y Cantidad de Piezas (CU-5.1)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Costo total pagado (Bs)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _batchCostController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '3500.00',
                            prefixText: 'Bs  ',
                            filled: true,
                            fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Costo requerido' : null,
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
                          'Piezas contenidas',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _batchQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '100',
                            suffixText: 'u.',
                            filled: true,
                            fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Cantidad requerida' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // TABLA DE ESCANDALLO AUTOMÁTICO (CU-5.2)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate_outlined, color: Theme.of(context).primaryColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Escandallo Automático de Costos',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _EscandalloItem(
                          label: 'Costo Unitario',
                          amount: AccountsProvider.formatAmount(_unitCost),
                          sub: 'por 1 pieza',
                        ),
                        _EscandalloItem(
                          label: 'Media Docena',
                          amount: AccountsProvider.formatAmount(_halfDozenCost),
                          sub: 'x6 piezas',
                        ),
                        _EscandalloItem(
                          label: 'Por Docena',
                          amount: AccountsProvider.formatAmount(_dozenCost),
                          sub: 'x12 piezas',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // FIJACIÓN DE PRECIOS DE VENTA CON MÁRGENES
              Text(
                'Fijar Precios de Venta al Público',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tokens.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Observa el porcentaje de ganancia neta en cada escala en tiempo real',
                style: TextStyle(fontSize: 11, color: tokens.textSecondary),
              ),
              const SizedBox(height: 12),

              // Escala 1: Detalle (x1)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _saleUnitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Precio al Detalle (x1)',
                        prefixText: 'Bs  ',
                        filled: true,
                        fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MarginChip(marginPercent: unitMargin),
                ],
              ),
              const SizedBox(height: 10),

              // Escala 2: Media Docena (x6)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _saleHalfDozenController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Precio Media Docena (x6)',
                        prefixText: 'Bs  ',
                        filled: true,
                        fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MarginChip(marginPercent: halfMargin),
                ],
              ),
              const SizedBox(height: 10),

              // Escala 3: Por Docena (x12)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _saleDozenController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Precio por Docena (x12)',
                        prefixText: 'Bs  ',
                        filled: true,
                        fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MarginChip(marginPercent: dozMargin),
                ],
              ),
              const SizedBox(height: 16),

              // Cuenta de pago del lote (Opcional)
              Text(
                '¿Con qué cuenta pagaste la compra del lote? (Opcional)',
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
                  child: DropdownButton<String?>(
                    value: _paidFromAccountId,
                    isExpanded: true,
                    dropdownColor: tokens.cardBg,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No debitar (Ya estaba pagado / Crédito)', style: TextStyle(fontSize: 12)),
                      ),
                      ...accountsProv.operationalAccounts.map((acc) {
                        return DropdownMenuItem<String?>(
                          value: acc.id,
                          child: Text(
                            'Debitar de ${acc.name} (${AccountsProvider.formatAmount(acc.balance)})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _paidFromAccountId = val),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton(
                onPressed: _isSaving ? null : _saveBatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar Lote en Inventario',
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

class _EscandalloItem extends StatelessWidget {
  final String label;
  final String amount;
  final String sub;

  const _EscandalloItem({required this.label, required this.amount, required this.sub});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
        Text(
          amount,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
        Text(sub, style: TextStyle(fontSize: 10, color: tokens.textSecondary.withOpacity(0.8))),
      ],
    );
  }
}

class _MarginChip extends StatelessWidget {
  final double marginPercent;

  const _MarginChip({required this.marginPercent});

  @override
  Widget build(BuildContext context) {
    final isPositive = marginPercent > 0;
    final color = isPositive ? const Color(0xFF10B981) : Colors.redAccent;

    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${marginPercent.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            isPositive ? 'Ganancia' : 'Pérdida',
            style: TextStyle(fontSize: 9, color: color),
          ),
        ],
      ),
    );
  }
}
