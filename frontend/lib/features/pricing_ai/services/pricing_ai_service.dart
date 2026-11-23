import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PricingAIResult {
  final String productName;
  final String country;
  final String currency;
  final double unitCost;
  final double halfDozenCost;
  final double dozenCost;

  // Precios sugeridos (CU-6.2)
  final double suggestedUnitPrice;
  final double suggestedHalfDozenPrice;
  final double suggestedDozenPrice;

  // Márgenes proyectados
  final double unitMarginPercent;
  final double halfDozenMarginPercent;
  final double dozenMarginPercent;

  // Veredicto de compra con IA (CU-6.1)
  final bool isPurchaseCostFavorable;
  final String advice;
  final String localTip;

  const PricingAIResult({
    required this.productName,
    required this.country,
    required this.currency,
    required this.unitCost,
    required this.halfDozenCost,
    required this.dozenCost,
    required this.suggestedUnitPrice,
    required this.suggestedHalfDozenPrice,
    required this.suggestedDozenPrice,
    required this.unitMarginPercent,
    required this.halfDozenMarginPercent,
    required this.dozenMarginPercent,
    required this.isPurchaseCostFavorable,
    required this.advice,
    required this.localTip,
  });
}

class SeasonalTrendResult {
  final String country;
  final String currentMonth;
  final String seasonalFocus;
  final List<String> topProducts;
  final List<String> evergreenProducts;
  final String capitalAllocationTip;

  const SeasonalTrendResult({
    required this.country,
    required this.currentMonth,
    required this.seasonalFocus,
    required this.topProducts,
    required this.evergreenProducts,
    required this.capitalAllocationTip,
  });
}

class PricingAIService {
  static const String _backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// CU-6.1 & CU-6.2: Evaluador de Compra y Recomendador de Precios con IA
  static Future<PricingAIResult> evaluateAndRecommendPricing({
    required String productName,
    required double totalPurchaseCost,
    required int batchUnits,
    String countryCode = 'BO',
    String extraNotes = '',
  }) async {
    // 1. Intento de consulta al Backend FastAPI si está levantado
    try {
      final url = Uri.parse('$_backendBaseUrl/api/ai/analyze-pricing');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'product_name': productName,
              'total_purchase_cost': totalPurchaseCost,
              'batch_units': batchUnits,
              'country_code': countryCode,
              'extra_notes': extraNotes,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final breakdown = data['cost_breakdown'];
        final pricing = data['suggested_pricing'];
        final verdict = data['ai_verdict'];

        return PricingAIResult(
          productName: data['product_name'] ?? productName,
          country: data['country'] ?? 'Bolivia',
          currency: data['currency'] ?? 'BOB',
          unitCost: _parseAmount(breakdown['unit_cost']),
          halfDozenCost: _parseAmount(breakdown['half_dozen_cost']),
          dozenCost: _parseAmount(breakdown['dozen_cost']),
          suggestedUnitPrice: _parseAmount(pricing['unit']['price']),
          suggestedHalfDozenPrice: _parseAmount(pricing['half_dozen']['price']),
          suggestedDozenPrice: _parseAmount(pricing['dozen']['price']),
          unitMarginPercent: 40.0,
          halfDozenMarginPercent: 30.0,
          dozenMarginPercent: 20.0,
          isPurchaseCostFavorable: verdict['is_purchase_cost_favorable'] ?? true,
          advice: verdict['advice'] ?? '',
          localTip: verdict['local_tip'] ?? '',
        );
      }
    } catch (_) {
      debugPrint('Usando motor económico embebido para la IA.');
    }

    // 2. Motor Económico Embebido (Contextualizado a Bolivia / Argentina)
    final curr = countryCode == 'BO' ? 'Bs' : '\$';
    final countryName = countryCode == 'BO' ? 'Bolivia' : 'Argentina';

    final unitCost = double.parse((totalPurchaseCost / batchUnits).toStringAsFixed(2));
    final halfCost = double.parse((unitCost * 6).toStringAsFixed(2));
    final dozCost = double.parse((unitCost * 12).toStringAsFixed(2));

    // Factor según economía: en Bolivia se maneja ~40% detalle y ~20% docena; en Argentina mayor margen por reposición
    final unitFactor = countryCode == 'BO' ? 0.60 : 0.50; // Margen 40% en BO, 50% en AR
    final halfFactor = countryCode == 'BO' ? 0.70 : 0.65;
    final dozFactor = countryCode == 'BO' ? 0.80 : 0.75;

    final unitSale = double.parse((unitCost / unitFactor).toStringAsFixed(2));
    final halfSale = double.parse((halfCost / halfFactor).toStringAsFixed(2));
    final dozSale = double.parse((dozCost / dozFactor).toStringAsFixed(2));

    final isFavorable = unitCost > 0;
    final advice = countryCode == 'BO'
        ? 'Para $productName en $countryName, tu costo de $unitCost $curr por unidad te deja un margen muy competitivo. '
            'Vendiendo a $unitSale $curr al detalle ganas el 40% neto, y a $dozSale $curr por docena liquidas el lote con alta rotación.'
        : 'Para el mercado argentino, considerando el costo de reposición e inflación, fija $unitSale $curr al detalle para blindar tu capital.';

    final localTip = countryCode == 'BO'
        ? 'Tip de mercado en Bolivia: Si el cliente compra por docena ($dozSale $curr), ofrece cobro inmediato con QR Simple de Banco Unión o BCP para evitar pérdidas por billetes falsos o cambio.'
        : 'Tip en Argentina: Ajusta tus precios de venta cada 15 a 30 días para no vender por debajo del costo del nuevo lote.';

    return PricingAIResult(
      productName: productName,
      country: countryName,
      currency: countryCode == 'BO' ? 'BOB' : 'ARS',
      unitCost: unitCost,
      halfDozenCost: halfCost,
      dozenCost: dozCost,
      suggestedUnitPrice: unitSale,
      suggestedHalfDozenPrice: halfSale,
      suggestedDozenPrice: dozSale,
      unitMarginPercent: countryCode == 'BO' ? 40.0 : 50.0,
      halfDozenMarginPercent: countryCode == 'BO' ? 30.0 : 35.0,
      dozenMarginPercent: countryCode == 'BO' ? 20.0 : 25.0,
      isPurchaseCostFavorable: isFavorable,
      advice: advice,
      localTip: localTip,
    );
  }

  /// CU-6.3: Radar de Oportunidades y Temporadas Comerciales
  static Future<SeasonalTrendResult> getSeasonalOpportunities({String countryCode = 'BO'}) async {
    final now = DateTime.now();
    final month = now.month;

    final monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final currentMonthName = monthNames[month];

    String seasonalFocus;
    List<String> topProducts;

    if (month == 1 || month == 2) {
      seasonalFocus = 'Temporada Escolar & Carnaval';
      topProducts = [
        'Mochilas y cartucheras escolares',
        'Cuadernos, colores y útiles por mayor',
        'Uniformes y guardapolvos',
        'Espumas y chisguetes de agua',
      ];
    } else if (month == 3 || month == 4) {
      seasonalFocus = 'Media Estación & Otoño';
      topProducts = [
        'Polerones ligeros y chompas delgadas',
        'Paraguas y chamarras rompevientos',
        'Ropa deportiva y calzados urbanos',
      ];
    } else if (month == 5) {
      seasonalFocus = 'Día de la Madre & Vísperas de Invierno';
      topProducts = [
        'Electrodomésticos pequeños y regalos',
        'Chompas gruesas y bufandas',
        'Cosméticos y sets de perfumería',
      ];
    } else if (month == 6 || month == 7) {
      seasonalFocus = 'Pleno Invierno & Vacaciones';
      topProducts = [
        'Fardos de parkas y chamarras térmicas',
        'Medias de lana y guantes polares',
        'Calefactores y mantas térmicas',
      ];
    } else if (month == 8 || month == 9) {
      seasonalFocus = 'Fiestas Patrias & Primavera';
      topProducts = [
        'Ropa ligera de cambio de temporada',
        'Banderas y distintivos cívicos',
        'Accesorios y bisutería',
      ];
    } else if (month == 10 || month == 11) {
      seasonalFocus = 'Todos Santos & Preparación Navideña';
      topProducts = [
        'Fardos de juguetes para fin de año',
        'Luces navideñas y guirnaldas',
        'Panetones y canastones mayoristas',
        'Ropa formal de fiesta y graduaciones',
      ];
    } else {
      seasonalFocus = 'Navidad, Año Nuevo y Regalos';
      topProducts = [
        'Juguetería infantil importada',
        'Luces decorativas LED',
        'Ropa de fiesta y vestidos de gala',
        'Canastones de fin de año',
      ];
    }

    final evergreenProducts = [
      'Abarrotes y alimentos no perecederos',
      'Accesorios de celular (cables, cargadores rápidos, protectores)',
      'Artículos de limpieza y aseo personal',
      'Medias básicas y ropa interior de alta rotación',
    ];

    final tip = (
      'En $currentMonthName te recomendamos la regla de capital 70/30: '
      'Coloca el 70% de tu dinero en productos evergreen de rotación diaria continua, '
      'y el 30% restante en mercadería de temporada ($seasonalFocus) para captar picos de alta ganancia sin arriesgar liquidez.'
    );

    return SeasonalTrendResult(
      country: countryCode == 'BO' ? 'Bolivia' : 'Argentina',
      currentMonth: currentMonthName,
      seasonalFocus: seasonalFocus,
      topProducts: topProducts,
      evergreenProducts: evergreenProducts,
      capitalAllocationTip: tip,
    );
  }

  static double _parseAmount(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    final clean = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
}
