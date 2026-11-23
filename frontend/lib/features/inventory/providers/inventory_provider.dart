import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

class InventoryProvider extends ChangeNotifier {
  static const String _productsStorageKey = 'kpital_inventory_products_v1';
  static const String _salesStorageKey = 'kpital_inventory_sales_v1';

  List<ProductModel> _products = [];
  List<ProductSaleRecord> _sales = [];
  bool _isLoading = true;

  List<ProductModel> get products => List.unmodifiable(_products);
  List<ProductSaleRecord> get sales => List.unmodifiable(_sales);
  bool get isLoading => _isLoading;

  /// CU-5.5: Métrica de Capital Invertido Global
  double get totalCapitalInvested =>
      _products.fold(0.0, (acc, item) => acc + item.capitalInvested);

  /// CU-5.5: Métrica de Capital Recuperado Global por Ventas
  double get totalCapitalRecovered =>
      _products.fold(0.0, (acc, item) => acc + item.capitalRecovered);

  /// Porcentaje global de recuperación de capital invertido
  double get globalRecoveryPercentage {
    if (totalCapitalInvested <= 0) return 0.0;
    return ((totalCapitalRecovered / totalCapitalInvested) * 100).clamp(0.0, 999.0);
  }

  /// Ganancia neta generada
  double get totalNetProfit => totalCapitalRecovered - totalCapitalInvested;

  /// Total de unidades disponibles en stock de todo el negocio
  int get totalStockUnits =>
      _products.fold(0, (acc, item) => acc + item.stockUnits);

  InventoryProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final productsString = prefs.getString(_productsStorageKey);
      final salesString = prefs.getString(_salesStorageKey);

      if (productsString != null && productsString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(productsString);
        _products = decoded.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Datos semilla representativos de ferias y mercados bolivianos
        final now = DateTime.now();
        _products = [
          ProductModel(
            id: 'prod_1',
            name: 'Parkas Térmicas de Invierno',
            description: 'Fardo importado con forro polar',
            batchPackageType: 'fardo',
            batchQuantity: 100,
            totalPurchaseCost: 3500.00,
            unitCost: 35.00,
            halfDozenCost: 210.00,
            dozenCost: 420.00,
            salePriceUnit: 65.00,       // Margen: 46.2%
            salePriceHalfDozen: 340.00, // Margen: 38.2%
            salePriceDozen: 600.00,     // Margen: 30.0%
            stockUnits: 76,
            minStockAlert: 10,
            capitalInvested: 3500.00,
            capitalRecovered: 2150.00,   // 61.4% recuperado
            createdAt: now.subtract(const Duration(days: 15)),
          ),
          ProductModel(
            id: 'prod_2',
            name: 'Medias de Alpaca Térmicas',
            description: 'Caja x120 pares surtidos',
            batchPackageType: 'caja',
            batchQuantity: 120,
            totalPurchaseCost: 720.00,
            unitCost: 6.00,
            halfDozenCost: 36.00,
            dozenCost: 72.00,
            salePriceUnit: 12.00,       // Margen: 50.0%
            salePriceHalfDozen: 60.00,  // Margen: 40.0%
            salePriceDozen: 100.00,     // Margen: 28.0%
            stockUnits: 48,
            minStockAlert: 15,
            capitalInvested: 720.00,
            capitalRecovered: 860.00,    // 119.4% recuperado (¡Ganancia pura!)
            createdAt: now.subtract(const Duration(days: 20)),
          ),
        ];
        await _saveData();
      }

      if (salesString != null && salesString.isNotEmpty) {
        final List<dynamic> decodedSales = jsonDecode(salesString);
        _sales = decodedSales.map((e) => ProductSaleRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error al cargar inventario: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsString = jsonEncode(_products.map((p) => p.toJson()).toList());
      final salesString = jsonEncode(_sales.map((s) => s.toJson()).toList());
      await prefs.setString(_productsStorageKey, productsString);
      await prefs.setString(_salesStorageKey, salesString);
    } catch (e) {
      debugPrint('Error al guardar inventario: $e');
    }
  }

  /// CU-5.1: Registrar compra de lote mayorista
  /// CU-5.2: Escandallo automático (unitario, x6, x12)
  /// CU-5.3: Fijar precios de venta
  Future<ProductModel> addProductBatch({
    required String name,
    String? description,
    required String batchPackageType,
    required int batchQuantity,
    required double totalPurchaseCost,
    required double salePriceUnit,
    required double salePriceHalfDozen,
    required double salePriceDozen,
    int minStockAlert = 5,
    String? paidFromAccountId,
    AccountsProvider? accountsProvider,
    TransactionsProvider? transactionsProvider,
  }) async {
    // Escandallo automático (CU-5.2)
    final unitCost = double.parse((totalPurchaseCost / batchQuantity).toStringAsFixed(2));
    final halfDozenCost = double.parse((unitCost * 6).toStringAsFixed(2));
    final dozenCost = double.parse((unitCost * 12).toStringAsFixed(2));

    final newProduct = ProductModel(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description?.trim(),
      batchPackageType: batchPackageType,
      batchQuantity: batchQuantity,
      totalPurchaseCost: totalPurchaseCost,
      unitCost: unitCost,
      halfDozenCost: halfDozenCost,
      dozenCost: dozenCost,
      salePriceUnit: salePriceUnit,
      salePriceHalfDozen: salePriceHalfDozen,
      salePriceDozen: salePriceDozen,
      stockUnits: batchQuantity,
      minStockAlert: minStockAlert,
      capitalInvested: totalPurchaseCost,
      capitalRecovered: 0.0,
      createdAt: DateTime.now(),
    );

    _products.insert(0, newProduct);
    await _saveData();

    // Si se pagó con una cuenta bancaria/efectivo, se descuenta y se registra el egreso
    if (paidFromAccountId != null && accountsProvider != null && transactionsProvider != null) {
      final acc = accountsProvider.accounts.firstWhere((a) => a.id == paidFromAccountId);
      await accountsProvider.adjustBalance(paidFromAccountId, -totalPurchaseCost);
      await transactionsProvider.recordExpense(
        accountsProvider: accountsProvider,
        accountId: paidFromAccountId,
        accountName: acc.name,
        amount: totalPurchaseCost,
        description: 'Compra de lote mayorista: $name ($batchQuantity $batchPackageType)',
        category: 'Insumos / Mercadería',
        isEssential: true,
      );
    }

    notifyListeners();
    return newProduct;
  }

  /// CU-5.4: Registrar venta rápida de negocio
  /// "Vendí 2 docenas por QR" -> Suma ingreso a la cuenta y descuenta inventario
  Future<bool> recordQuickSale({
    required String productId,
    required SaleScale scale,
    required int scaleQuantity,
    double? customPrice,
    required String accountId,
    required String accountName,
    String paymentMethod = 'QR',
    required AccountsProvider accountsProvider,
    required TransactionsProvider transactionsProvider,
  }) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1 || scaleQuantity <= 0) return false;

    final product = _products[index];
    final unitsToDeduct = scaleQuantity * scale.multiplier;

    if (product.stockUnits < unitsToDeduct) return false; // Stock insuficiente

    // Determinar precio de venta unitario según la escala
    double unitSalePrice;
    if (customPrice != null && customPrice > 0) {
      unitSalePrice = customPrice;
    } else {
      switch (scale) {
        case SaleScale.unit:
          unitSalePrice = product.salePriceUnit;
          break;
        case SaleScale.halfDozen:
          unitSalePrice = product.salePriceHalfDozen;
          break;
        case SaleScale.dozen:
          unitSalePrice = product.salePriceDozen;
          break;
        case SaleScale.batch:
          unitSalePrice = product.totalPurchaseCost;
          break;
      }
    }

    final totalSaleAmount = double.parse((unitSalePrice * scaleQuantity).toStringAsFixed(2));
    final costOfSoldItems = product.unitCost * unitsToDeduct;
    final profitAmount = double.parse((totalSaleAmount - costOfSoldItems).toStringAsFixed(2));

    // 1. Actualizar stock y métrica de capital recuperado del producto (CU-5.4 & CU-5.5)
    _products[index] = product.copyWith(
      stockUnits: product.stockUnits - unitsToDeduct,
      capitalRecovered: product.capitalRecovered + totalSaleAmount,
    );

    // 2. Registrar venta en historial de ventas
    final saleRecord = ProductSaleRecord(
      id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      scale: scale,
      scaleQuantity: scaleQuantity,
      unitsDeducted: unitsToDeduct,
      unitSalePrice: unitSalePrice,
      totalSaleAmount: totalSaleAmount,
      profitAmount: profitAmount,
      paymentMethod: paymentMethod,
      accountId: accountId,
      accountName: accountName,
      saleDate: DateTime.now(),
    );

    _sales.insert(0, saleRecord);
    await _saveData();

    // 3. EFECTO AUTOMÁTICO EN CUENTAS: Suma el dinero a Banco Unión / Efectivo (CU-5.4)
    await accountsProvider.adjustBalance(accountId, totalSaleAmount);

    // 4. Registra la transacción de ingreso en el historial general
    await transactionsProvider.recordIncome(
      accountsProvider: accountsProvider,
      accountId: accountId,
      accountName: accountName,
      amount: totalSaleAmount,
      contactName: 'Venta Negocio: ${product.name}',
      description: 'Venta de $scaleQuantity ${scale.label} por $paymentMethod ($unitsToDeduct u.)',
      category: 'Venta de Negocio',
    );

    notifyListeners();
    return true;
  }

  /// Eliminar producto del inventario
  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    await _saveData();
    notifyListeners();
  }
}
