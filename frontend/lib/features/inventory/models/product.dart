enum SaleScale {
  unit,       // Al detalle (1 unidad)
  halfDozen,  // Media docena (6 unidades)
  dozen,      // Por docena (12 unidades)
  batch;      // Lote completo

  String get label {
    switch (this) {
      case SaleScale.unit:
        return 'Al Detalle (x1)';
      case SaleScale.halfDozen:
        return 'Media Docena (x6)';
      case SaleScale.dozen:
        return 'Por Docena (x12)';
      case SaleScale.batch:
        return 'Lote Completo';
    }
  }

  int get multiplier {
    switch (this) {
      case SaleScale.unit:
        return 1;
      case SaleScale.halfDozen:
        return 6;
      case SaleScale.dozen:
        return 12;
      case SaleScale.batch:
        return 1;
    }
  }
}

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String batchPackageType; // 'fardo', 'caja', 'docena', 'paquete'
  final int batchQuantity;        // Cuántas piezas vinieron en el lote
  final double totalPurchaseCost; // Costo total pagado por el lote

  // Escandallo automático (CU-5.2)
  final double unitCost;
  final double halfDozenCost;
  final double dozenCost;

  // Precios de venta fijados (CU-5.3)
  final double salePriceUnit;
  final double salePriceHalfDozen;
  final double salePriceDozen;

  // Stock y métricas de capital (CU-5.5)
  final int stockUnits;
  final int minStockAlert;
  final double capitalInvested;
  final double capitalRecovered;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.batchPackageType = 'fardo',
    required this.batchQuantity,
    required this.totalPurchaseCost,
    required this.unitCost,
    required this.halfDozenCost,
    required this.dozenCost,
    required this.salePriceUnit,
    required this.salePriceHalfDozen,
    required this.salePriceDozen,
    required this.stockUnits,
    this.minStockAlert = 5,
    required this.capitalInvested,
    this.capitalRecovered = 0.0,
    required this.createdAt,
  });

  // Márgenes netos porcentuales (CU-5.3)
  double get unitMarginPercent =>
      salePriceUnit > 0 ? (((salePriceUnit - unitCost) / salePriceUnit) * 100) : 0.0;

  double get halfDozenMarginPercent =>
      salePriceHalfDozen > 0 ? (((salePriceHalfDozen - halfDozenCost) / salePriceHalfDozen) * 100) : 0.0;

  double get dozenMarginPercent =>
      salePriceDozen > 0 ? (((salePriceDozen - dozenCost) / salePriceDozen) * 100) : 0.0;

  // Porcentaje de capital recuperado del lote (CU-5.5)
  double get capitalRecoveryPercent =>
      capitalInvested > 0 ? ((capitalRecovered / capitalInvested) * 100) : 0.0;

  bool get isCapitalFullyRecovered => capitalRecovered >= capitalInvested;

  bool get isLowStock => stockUnits <= minStockAlert;

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? batchPackageType,
    int? batchQuantity,
    double? totalPurchaseCost,
    double? unitCost,
    double? halfDozenCost,
    double? dozenCost,
    double? salePriceUnit,
    double? salePriceHalfDozen,
    double? salePriceDozen,
    int? stockUnits,
    int? minStockAlert,
    double? capitalInvested,
    double? capitalRecovered,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      batchPackageType: batchPackageType ?? this.batchPackageType,
      batchQuantity: batchQuantity ?? this.batchQuantity,
      totalPurchaseCost: totalPurchaseCost ?? this.totalPurchaseCost,
      unitCost: unitCost ?? this.unitCost,
      halfDozenCost: halfDozenCost ?? this.halfDozenCost,
      dozenCost: dozenCost ?? this.dozenCost,
      salePriceUnit: salePriceUnit ?? this.salePriceUnit,
      salePriceHalfDozen: salePriceHalfDozen ?? this.salePriceHalfDozen,
      salePriceDozen: salePriceDozen ?? this.salePriceDozen,
      stockUnits: stockUnits ?? this.stockUnits,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      capitalInvested: capitalInvested ?? this.capitalInvested,
      capitalRecovered: capitalRecovered ?? this.capitalRecovered,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'batchPackageType': batchPackageType,
      'batchQuantity': batchQuantity,
      'totalPurchaseCost': totalPurchaseCost,
      'unitCost': unitCost,
      'halfDozenCost': halfDozenCost,
      'dozenCost': dozenCost,
      'salePriceUnit': salePriceUnit,
      'salePriceHalfDozen': salePriceHalfDozen,
      'salePriceDozen': salePriceDozen,
      'stockUnits': stockUnits,
      'minStockAlert': minStockAlert,
      'capitalInvested': capitalInvested,
      'capitalRecovered': capitalRecovered,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      batchPackageType: json['batchPackageType'] as String? ?? 'fardo',
      batchQuantity: (json['batchQuantity'] as num).toInt(),
      totalPurchaseCost: (json['totalPurchaseCost'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      halfDozenCost: (json['halfDozenCost'] as num).toDouble(),
      dozenCost: (json['dozenCost'] as num).toDouble(),
      salePriceUnit: (json['salePriceUnit'] as num).toDouble(),
      salePriceHalfDozen: (json['salePriceHalfDozen'] as num).toDouble(),
      salePriceDozen: (json['salePriceDozen'] as num).toDouble(),
      stockUnits: (json['stockUnits'] as num).toInt(),
      minStockAlert: (json['minStockAlert'] as num?)?.toInt() ?? 5,
      capitalInvested: (json['capitalInvested'] as num).toDouble(),
      capitalRecovered: (json['capitalRecovered'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class ProductSaleRecord {
  final String id;
  final String productId;
  final String productName;
  final SaleScale scale;
  final int scaleQuantity;
  final int unitsDeducted;
  final double unitSalePrice;
  final double totalSaleAmount;
  final double profitAmount;
  final String paymentMethod;
  final String accountId;
  final String accountName;
  final DateTime saleDate;

  const ProductSaleRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.scale,
    required this.scaleQuantity,
    required this.unitsDeducted,
    required this.unitSalePrice,
    required this.totalSaleAmount,
    required this.profitAmount,
    required this.paymentMethod,
    required this.accountId,
    required this.accountName,
    required this.saleDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'scale': scale.name,
      'scaleQuantity': scaleQuantity,
      'unitsDeducted': unitsDeducted,
      'unitSalePrice': unitSalePrice,
      'totalSaleAmount': totalSaleAmount,
      'profitAmount': profitAmount,
      'paymentMethod': paymentMethod,
      'accountId': accountId,
      'accountName': accountName,
      'saleDate': saleDate.toIso8601String(),
    };
  }

  factory ProductSaleRecord.fromJson(Map<String, dynamic> json) {
    return ProductSaleRecord(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      scale: SaleScale.values.firstWhere(
        (s) => s.name == json['scale'],
        orElse: () => SaleScale.unit,
      ),
      scaleQuantity: (json['scaleQuantity'] as num).toInt(),
      unitsDeducted: (json['unitsDeducted'] as num).toInt(),
      unitSalePrice: (json['unitSalePrice'] as num).toDouble(),
      totalSaleAmount: (json['totalSaleAmount'] as num).toDouble(),
      profitAmount: (json['profitAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String? ?? 'QR',
      accountId: json['accountId'] as String,
      accountName: json['accountName'] as String? ?? 'Cuenta',
      saleDate: DateTime.parse(json['saleDate'] as String),
    );
  }
}
