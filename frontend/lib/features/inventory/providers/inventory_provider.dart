import '../../../core/services/finance_api_service.dart';
import '../../transactions/models/transaction.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

class InventoryProvider extends ChangeNotifier {
  String _currentUserId = '';
  List<ProductModel> _products = [];
  List<ProductSaleRecord> _sales = [];
  bool _isLoading = false;
  String? _token;
  Future<void>? _loading;
  int _revision = 0;
  String? syncError;

  String get _productsStorageKey =>
      'kpital_inventory_products_${_currentUserId.isNotEmpty ? _currentUserId : "guest"}_v2';
  String get _salesStorageKey =>
      'kpital_inventory_sales_${_currentUserId.isNotEmpty ? _currentUserId : "guest"}_v2';

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

  InventoryProvider();

  void setAuthSession(String userId, String? token) {
    if (_currentUserId == userId && _token == token) return;
    if (_currentUserId != userId) {
      _products = [];
      _sales = [];
    }
    _currentUserId = userId;
    _token = token;
    syncError = null;
    _loading = Future<void>.microtask(_loadData);
  }

  Future<void> synchronize() async {
    await _loading;
    if (_isLoading || _token == null) return;
    _loading = _loadData();
    await _loading;
  }

  Future<void> _loadData() async {
    final token = _token;
    final productsKey = _productsStorageKey;
    final salesKey = _salesStorageKey;
    final revision = _revision;
    if (token == null) return;
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != _token || revision != _revision) return;
      final products = (jsonDecode(prefs.getString(productsKey) ?? '[]') as List)
          .cast<Map<String, dynamic>>();
      final sales = (jsonDecode(prefs.getString(salesKey) ?? '[]') as List)
          .cast<Map<String, dynamic>>();
      _products = products.map(ProductModel.fromJson).toList();
      _sales = sales.map(ProductSaleRecord.fromJson).toList();
      final importedKey = '${productsKey}_imported';
      final imported = prefs.getBool(importedKey) ?? false;
      final cloud = await Future.wait([
        FinanceApiService.syncRecords(token, 'products',
            imported ? [] : _products.map((product) => product.toJson())),
        FinanceApiService.syncRecords(token, 'sales',
            imported ? [] : _sales.map((sale) => sale.toJson())),
      ]);
      if (token != _token || revision != _revision) return;
      _products = cloud[0].map(ProductModel.fromJson).toList();
      _sales = cloud[1].map(ProductSaleRecord.fromJson).toList()
        ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
      await _saveData();
      if (!imported) await prefs.setBool(importedKey, true);
      if (token == _token) syncError = null;
    } on FinanceSyncException catch (error) {
      if (token == _token) syncError = error.message;
    } catch (_) {
      if (token == _token) syncError = 'No se pudo sincronizar el inventario.';
    } finally {
      if (token == _token) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _saveData() async {
    final productsKey = _productsStorageKey;
    final salesKey = _salesStorageKey;
    final products = jsonEncode(_products.map((product) => product.toJson()).toList());
    final sales = jsonEncode(_sales.map((sale) => sale.toJson()).toList());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(productsKey, products);
      await prefs.setString(salesKey, sales);
    } catch (error) {
      debugPrint('Error al guardar la copia local de inventario: $error');
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
    required String productId,
    required DateTime createdAt,
    AccountsProvider? accountsProvider,
    TransactionsProvider? transactionsProvider,
  }) async {
    // Escandallo automático (CU-5.2)
    final unitCost = double.parse((totalPurchaseCost / batchQuantity).toStringAsFixed(2));
    final halfDozenCost = double.parse((unitCost * 6).toStringAsFixed(2));
    final dozenCost = double.parse((unitCost * 12).toStringAsFixed(2));

    final newProduct = ProductModel(
      id: productId,
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
      createdAt: createdAt,
    );

    final token = FinanceApiService.requireSession(_token);
    TransactionModel? transaction;
    if (paidFromAccountId != null && accountsProvider != null) {
      await accountsProvider.waitForCloud();
      final account = accountsProvider.accounts.where((a) => a.id == paidFromAccountId).firstOrNull;
      if (account == null) {
        throw const FinanceSyncException('La cuenta de pago ya no está disponible.');
      }
      transaction = TransactionModel(
        id: productId,
        accountId: account.id,
        accountName: account.name,
        type: TransactionType.expense,
        amount: totalPurchaseCost,
        description: 'Compra de lote mayorista: $name ($batchQuantity $batchPackageType)',
        category: 'Insumos / Mercadería',
        transactionDate: createdAt,
        createdAt: createdAt,
      );
    }
    if (token != _token) {
      throw const FinanceSyncException('La sesión cambió. Vuelve a abrir el formulario.');
    }
    await FinanceApiService.saveRecords(token, [
      FinanceRecordChange('products', newProduct.id, newProduct.toJson()),
    ], transaction: transaction);
    if (token == _token) {
      await accountsProvider?.synchronize();
      await Future.wait([synchronize(), if (transactionsProvider != null) transactionsProvider.synchronize()]);
    }
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
    required String saleId,
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
    final updated = product.copyWith(
      stockUnits: product.stockUnits - unitsToDeduct,
      capitalRecovered: product.capitalRecovered + totalSaleAmount,
    );

    // 2. Registrar venta en historial de ventas
    final saleRecord = ProductSaleRecord(
      id: saleId,
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

    final token = FinanceApiService.requireSession(_token);
    await accountsProvider.waitForCloud();
    if (token != _token) return false;
    final productName = product.name;
    await FinanceApiService.saveRecords(token, [
      FinanceRecordChange('products', updated.id, updated.toJson(), previous: product.toJson()),
      FinanceRecordChange('sales', saleRecord.id, saleRecord.toJson()),
    ], transaction: TransactionModel(
      id: saleId,
      accountId: accountId,
      accountName: accountName,
      type: TransactionType.income,
      amount: totalSaleAmount,
      contactName: 'Venta Negocio: $productName',
      description: 'Venta por $paymentMethod ($unitsToDeduct u.)',
      category: 'Venta de Negocio',
      transactionDate: saleRecord.saleDate,
      createdAt: saleRecord.saleDate,
    ));
    if (token == _token) {
      await accountsProvider.synchronize();
      await Future.wait([synchronize(), transactionsProvider.synchronize()]);
    }
    return true;
  }

  /// Eliminar producto del inventario
  Future<void> deleteProduct(String productId) async {
    final token = FinanceApiService.requireSession(_token);
    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) return;
    await FinanceApiService.saveRecords(token, [
      FinanceRecordChange('products', productId, null, previous: product.toJson()),
    ]);
    if (token != _token) return;
    _revision++;
    _products.removeWhere((p) => p.id == productId);
    await _saveData();
    notifyListeners();
  }
}
