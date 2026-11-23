import 'package:flutter/material.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../ads/widgets/ad_banner_widget.dart';
import '../pricing_calculator_screen.dart';
import '../services/pricing_ai_service.dart';

class SeasonalTrendsScreen extends StatefulWidget {
  const SeasonalTrendsScreen({super.key});

  @override
  State<SeasonalTrendsScreen> createState() => _SeasonalTrendsScreenState();
}

class _SeasonalTrendsScreenState extends State<SeasonalTrendsScreen> {
  String _selectedCountry = 'BO';
  late Future<SeasonalTrendResult> _futureTrends;
  final TextEditingController _capitalController = TextEditingController(text: '5000');
  double _userCapital = 5000.0;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  void _loadTrends() {
    _futureTrends = PricingAIService.getSeasonalOpportunities(countryCode: _selectedCountry);
  }

  @override
  void dispose() {
    _capitalController.dispose();
    super.dispose();
  }

  void _onCapitalChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _userCapital = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primaryColor = Theme.of(context).primaryColor;
    final curr = _selectedCountry == 'BO' ? 'Bs' : '\$';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar de Temporadas (IA)'),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tokens.isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                dropdownColor: tokens.cardBg,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                items: const [
                  DropdownMenuItem(value: 'BO', child: Text('🇧🇴 Bolivia')),
                  DropdownMenuItem(value: 'AR', child: Text('🇦🇷 Argentina')),
                ],
                onChanged: (val) {
                  if (val != null && val != _selectedCountry) {
                    setState(() {
                      _selectedCountry = val;
                      _loadTrends();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<SeasonalTrendResult>(
        future: _futureTrends,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text('No se pudo cargar el radar de temporadas'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadTrends()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final evergreenCapital = _userCapital * 0.70;
          final seasonalCapital = _userCapital * 0.30;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Tarjeta de Temporada Actual
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: tokens.isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [primaryColor.withOpacity(0.08), primaryColor.withOpacity(0.02)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.whatshot, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Mes Actual: ${data.currentMonth}',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data.country,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data.seasonalFocus,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'La IA ha identificado los mayores focos de liquidez y demanda para los comerciantes de ferias y mercados este mes.',
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SUGERENCIA DE REPARTO DE CAPITAL (Regla 70/30)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sugerencia de Reparto de Capital',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Regla 70 / 30',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tokens.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tokens.isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calculate_outlined, size: 20, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                'Calculadora de Asignación Inteligente',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _capitalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _onCapitalChanged,
                            decoration: InputDecoration(
                              labelText: 'Tu capital total para mercadería ($curr)',
                              prefixIcon: Icon(Icons.monetization_on_outlined, color: primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: tokens.isDark ? Colors.black26 : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Barra visual 70/30
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 14,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 70,
                                    child: Container(
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: 30,
                                    child: Container(
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.shield, color: Color(0xFF10B981), size: 14),
                                          SizedBox(width: 4),
                                          Text('70% Seguro', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${evergreenCapital.toStringAsFixed(0)} $curr',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: tokens.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rotación continua diaria sin riesgo',
                                        style: TextStyle(color: tokens.textSecondary, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.trending_up, color: Colors.amber, size: 14),
                                          SizedBox(width: 4),
                                          Text('30% Temporada', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${seasonalCapital.toStringAsFixed(0)} $curr',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: tokens.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pico de ganancias de este mes',
                                        style: TextStyle(color: tokens.textSecondary, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data.capitalAllocationTip,
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CU-6.3: TOP PRODUCTOS DEL MES ACTUAL
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Más Vendidos de ${data.currentMonth}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...data.topProducts.map((prod) => _SeasonalProductCard(
                          productName: prod,
                          isSeason: true,
                          countryCode: _selectedCountry,
                        )),
                    const SizedBox(height: 20),

                    // PRODUCTOS DE ALTA ROTACIÓN TODO EL AÑO (EVERGREEN)
                    Row(
                      children: [
                        const Icon(Icons.all_inclusive, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Productos Evergreen (Todo el Año)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...data.evergreenProducts.map((prod) => _SeasonalProductCard(
                          productName: prod,
                          isSeason: false,
                          countryCode: _selectedCountry,
                        )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // CU-7.1: Banner inferior no invasivo de Google AdMob
              const AdBannerWidget(),
            ],
          );
        },
      ),
    );
  }
}

class _SeasonalProductCard extends StatelessWidget {
  final String productName;
  final bool isSeason;
  final String countryCode;

  const _SeasonalProductCard({
    required this.productName,
    required this.isSeason,
    required this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSeason ? Colors.amber.withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSeason ? Icons.local_fire_department : Icons.loop,
              color: isSeason ? Colors.amber : const Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSeason ? 'Alta demanda estacional' : 'Rotación diaria constante',
                  style: TextStyle(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Evaluar precio con IA',
            icon: Icon(Icons.auto_awesome, color: primaryColor, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PricingCalculatorScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
