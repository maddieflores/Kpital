import 'package:flutter/material.dart';

enum TransactionType {
  income,
  expense,
  transfer;

  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Ingreso / Transferencia';
      case TransactionType.expense:
        return 'Gasto / Egreso';
      case TransactionType.transfer:
        return 'Movimiento Interno';
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.income:
        return const Color(0xFF10B981); // Verde éxito
      case TransactionType.expense:
        return const Color(0xFFEF4444); // Rojo gasto
      case TransactionType.transfer:
        return const Color(0xFF3366D6); // Azul neutro
    }
  }
}

class TransactionModel {
  final String id;
  final String accountId;
  final String accountName;
  final String? destinationAccountId;
  final String? destinationAccountName;
  final TransactionType type;
  final double amount;
  final String currency;
  final String? contactName; // CU-1.1: Quién transfirió o a quién se pagó
  final String? description;
  final String? receiptImagePath; // CU-1.2: Foto / Captura del comprobante QR
  final DateTime transactionDate;
  final String? category;
  final bool isEssential; // Para gastos fijos vs gastos hormiga (Módulo 2)
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.accountId,
    required this.accountName,
    this.destinationAccountId,
    this.destinationAccountName,
    required this.type,
    required this.amount,
    this.currency = 'BOB',
    this.contactName,
    this.description,
    this.receiptImagePath,
    required this.transactionDate,
    this.category,
    this.isEssential = true,
    required this.createdAt,
  });

  TransactionModel copyWith({
    String? id,
    String? accountId,
    String? accountName,
    String? destinationAccountId,
    String? destinationAccountName,
    TransactionType? type,
    double? amount,
    String? currency,
    String? contactName,
    String? description,
    String? receiptImagePath,
    DateTime? transactionDate,
    String? category,
    bool? isEssential,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      destinationAccountName: destinationAccountName ?? this.destinationAccountName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      contactName: contactName ?? this.contactName,
      description: description ?? this.description,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      isEssential: isEssential ?? this.isEssential,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'accountName': accountName,
      'destinationAccountId': destinationAccountId,
      'destinationAccountName': destinationAccountName,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'contactName': contactName,
      'description': description,
      'receiptImagePath': receiptImagePath,
      'transactionDate': transactionDate.toIso8601String(),
      'category': category,
      'isEssential': isEssential,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    TransactionType parseType(String? val) {
      switch (val) {
        case 'income':
          return TransactionType.income;
        case 'expense':
          return TransactionType.expense;
        case 'transfer':
          return TransactionType.transfer;
        default:
          return TransactionType.income;
      }
    }

    return TransactionModel(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      accountName: json['accountName'] as String? ?? 'Cuenta',
      destinationAccountId: json['destinationAccountId'] as String?,
      destinationAccountName: json['destinationAccountName'] as String?,
      type: parseType(json['type'] as String?),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'BOB',
      contactName: json['contactName'] as String?,
      description: json['description'] as String?,
      receiptImagePath: json['receiptImagePath'] as String?,
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'] as String)
          : DateTime.now(),
      category: json['category'] as String?,
      isEssential: json['isEssential'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
