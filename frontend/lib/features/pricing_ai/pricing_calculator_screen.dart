import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/finance_api_service.dart';
import '../../core/theme/app_design_tokens.dart';
import '../ads/providers/ads_provider.dart';
import '../ads/widgets/ad_banner_widget.dart';
import '../inventory/providers/inventory_provider.dart';
import 'services/pricing_ai_service.dart';

class PricingCalculatorScreen extends StatefulWidget {
  const PricingCalculatorScreen({super.key});

  @override
  State<PricingCalculatorScreen> createState() => _PricingCalculatorScreenState();
}

class _PricingCalculatorScreenState extends State<PricingCalculatorScreen> {
  final _productNameController = TextEditingController(text: "Fardo Parkas Térmicas");
  final _totalCostController = TextEditingController(text: "3500");
  final _unitsController = TextEditingController(text: "100");
  final _notesController = TextEditingController();

  String _selectedCountry = "BO"; // Bolivia por defecto
  bool _isLoading = false;
  PricingAIResult? _analysisResult;
  bool _savingInventory = false;
  String? _productDraftId;
  DateTime? _productDraftDate;

  final List<String> _productSuggestions = [
    'Fardo Parkas Térmicas',
    'Caja Medias de Alpaca',
    'Lote Poleras de Algodón',
    'Docenas de Zapatillas',
    'Paquetes Ropa Infantil',
  ];

  @override
  void dispose() {
    _productNameController.dispose();
    _totalCostController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _analyzeWithAI() async {
    final cost = double.tryParse(_totalCostController.text.replaceAll(',', '.')) ?? 0.0;
    final units = int.tryParse(_unitsController.text) ?? 0;
    final name = _productNameController.text.trim();

    if (cost <= 0 || units <= 0 || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa el nombre, costo y piezas del lote.')),
      );
      return;
    }

    // CU-7.2 & CU-7.3: Si es usuario común requiere Rewarded Ad (15s); si es Modo Creador/Owner pasa directo
    final adsProv = Provider.of<AdsProvider>(context, listen: false);
    final granted = await adsProv.requestRewardedAd(
      context,
      onRewardGranted: () {},
    );

    if (!granted) {
      return; // El usuario canceló el anuncio recompensado
    }

    setState(() => _isLoading = true);

    final result = await PricingAIService.evaluateAndRecommendPricing(
      productName: name,
      totalPurchaseCost: cost,
      batchUnits: units,
      countryCode: _selectedCountry,
      extraNotes: _notesController.text,
    );

    setState(() {
      _analysisResult = result;
      _isLoading = false;
      _productDraftId = null;
      _productDraftDate = null;
    });
  }

  Future<void> _saveToInventory() async {
    if (_analysisResult == null || _savingInventory) return;

    final inventoryProv = Provider.of<InventoryProvider>(context, listen: false);
    final res = _analysisResult!;

    _savingInventory = true;
    try {
      await inventoryProv.addProductBatch(
        productId: _productDraftId ??= FinanceApiService.newId('prod'),
        createdAt: _productDraftDate ??= DateTime.now(),
        name: res.productName,
        batchPackageType: 'fardo',
        batchQuantity: int.tryParse(_unitsController.text) ?? 50,
        totalPurchaseCost: double.tryParse(_totalCostController.text.replaceAll(',', '.')) ?? 1000.0,
        salePriceUnit: res.suggestedUnitPrice,
        salePriceHalfDozen: res.suggestedHalfDozenPrice,
        salePriceDozen: res.suggestedDozenPrice,
      );
      _productDraftId = null;
      _productDraftDate = null;
    } on FinanceSyncException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    } finally {
      _savingInventory = false;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text('¡Precios recomendados de "${res.productName}" guardados en tu Inventario!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primaryColor = Theme.of(context).primaryColor;
    final curr = _selectedCountry == "BO" ? "Bs" : "\$";

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistente IA de Precios',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              'Evaluador de compras mayoristas y fijación inteligente',
                              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'IA Activa',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selector de Mercado / País
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.public, color: Color(0xFF3366D6), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Mercado económico:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                        ),
                        const Spacer(),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountry,
                            dropdownColor: tokens.cardBg,
                            items: const [
                              DropdownMenuItem(value: "BO", child: Text("Bolivia (Bs BOB)")),
                              DropdownMenuItem(value: "AR", child: Text("Argentina (\$ ARS)")),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCountry = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Formulario de Evaluación de Compra (CU-6.1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fact_check_outlined, size: 18, color: Color(0xFF3366D6)),
                            const SizedBox(width: 8),
                            Text(
                              'Evaluador de Compra Mayorista',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Producto que piensas comprar en la feria o mercado',
                          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _productNameController,
                          decoration: InputDecoration(
                            hintText: 'Ej: Fardo de Parkas Térmicas',
                            prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 18),
                            filled: true,
                            fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Chips sugerencias
                        SizedBox(
                          height: 28,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _productSuggestions.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (_, idx) => ActionChip(
                              label: Text(_productSuggestions[idx], style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(() => _productNameController.text = _productSuggestions[idx]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Costo Total y Unidades
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Costo del Lote ($curr)', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _totalCostController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '$curr  ',
                                      filled: true,
                                      fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Piezas en el lote', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _unitsController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      suffixText: 'u.',
                                      filled: true,
                                      fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Botón de Evaluación con IA
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _analyzeWithAI,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          label: Text(
                            _isLoading ? 'Analizando con IA...' : '¿Me Conviene Comprar? Evaluar con IA',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // RESULTADOS DE EVALUACIÓN Y RECOMENDACIÓN DE PRECIOS (CU-6.1 & CU-6.2)
              if (_analysisResult != null) ...[
                // Tarjeta Veredicto de Compra con IA (CU-6.1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Veredicto IA: Compra Favorable',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                              Text(
                                'Costo Unitario: ${_analysisResult!.unitCost.toStringAsFixed(2)} $curr',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _analysisResult!.advice,
                            style: TextStyle(fontSize: 12, height: 1.4, color: tokens.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tokens.cardBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tips_and_updates_outlined, color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _analysisResult!.localTip,
                                    style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Recomendador de Precios por Escalas con IA (CU-6.2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tokens.cardBg,
                        borderRadius: BorderRadius.circular(20),
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
                                  Icon(Icons.price_check_rounded, color: primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Precios Sugeridos por Escala',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tokens.textPrimary),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _saveToInventory,
                                icon: const Icon(Icons.save_outlined, size: 14),
                                label: const Text('Guardar', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _PricingCardRow(
                            title: 'Venta al Detalle (x1)',
                            price: '${_analysisResult!.suggestedUnitPrice.toStringAsFixed(2)} $curr',
                            cost: '${_analysisResult!.unitCost.toStringAsFixed(2)} $curr',
                            margin: '${_analysisResult!.unitMarginPercent.toStringAsFixed(0)}% ganancia',
                            strategy: 'Consumidor final. Maximiza el rendimiento por cada prenda vendida.',
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 10),

                          _PricingCardRow(
                            title: 'Media Docena (x6)',
                            price: '${_analysisResult!.suggestedHalfDozenPrice.toStringAsFixed(2)} $curr',
                            cost: '${_analysisResult!.halfDozenCost.toStringAsFixed(2)} $curr',
                            margin: '${_analysisResult!.halfDozenMarginPercent.toStringAsFixed(0)}% ganancia',
                            strategy: 'Compras familiares o revendedores pequeños de barrio.',
                            color: const Color(0xFF3366D6),
                          ),
                          const SizedBox(height: 10),

                          _PricingCardRow(
                            title: 'Por Docena (x12)',
                            price: '${_analysisResult!.suggestedDozenPrice.toStringAsFixed(2)} $curr',
                            cost: '${_analysisResult!.dozenCost.toStringAsFixed(2)} $curr',
                            margin: '${_analysisResult!.dozenMarginPercent.toStringAsFixed(0)}% ganancia',
                            strategy: 'Liquidación mayorista rápida para recuperar el capital en pocos días.',
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}

class _PricingCardRow extends StatelessWidget {
  final String title;
  final String price;
  final String cost;
  final String margin;
  final String strategy;
  final Color color;

  const _PricingCardRow({
    required this.title,
    required this.price,
    required this.cost,
    required this.margin,
    required this.strategy,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tokens.textPrimary)),
              Text(price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Costo base: $cost', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
              Text(margin, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(strategy, style: TextStyle(fontSize: 10, color: tokens.textSecondary.withOpacity(0.85))),
        ],
      ),
    );
  }
}
