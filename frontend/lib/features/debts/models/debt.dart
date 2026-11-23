import 'package:flutter/material.dart';

enum DebtType {
  receivable, // Me deben (Cuentas por cobrar)
  payable;    // Debo (Cuentas por pagar a proveedores/bancos)

  String get label => this == DebtType.receivable ? 'Me deben' : 'Debo a otros';
  Color get color => this == DebtType.receivable ? const Color(0xFF10B981) : const Color(0xFFEF4444);
}

enum DebtStatus {
  pending,
  partial,
  paid;

  String get label {
    switch (this) {
      case DebtStatus.pending:
        return 'Pendiente';
      case DebtStatus.partial:
        return 'Con Abonos';
      case DebtStatus.paid:
        return 'Completamente Pagado';
    }
  }
}

class DebtPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String accountId;
  final String accountName;
  final String? note;

  const DebtPayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.accountId,
    required this.accountName,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'accountName': accountName,
      'note': note,
    };
  }

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      accountId: json['accountId'] as String,
      accountName: json['accountName'] as String? ?? 'Cuenta',
      note: json['note'] as String?,
    );
  }
}

class DebtModel {
  final String id;
  final DebtType type;
  final String personName;
  final String? phoneNumber; // CU-3.3: Teléfono para WhatsApp
  final double totalAmount;
  final double remainingAmount;
  final DateTime? dueDate; // Fecha pactada
  final String? concept; // Ej: Mercadería fiada, préstamo
  final DebtStatus status;
  final List<DebtPayment> payments;
  final DateTime createdAt;

  const DebtModel({
    required this.id,
    required this.type,
    required this.personName,
    this.phoneNumber,
    required this.totalAmount,
    required this.remainingAmount,
    this.dueDate,
    this.concept,
    this.status = DebtStatus.pending,
    this.payments = const [],
    required this.createdAt,
  });

  double get paidAmount => totalAmount - remainingAmount;

  double get progressPercentage {
    if (totalAmount <= 0) return 0.0;
    return (paidAmount / totalAmount).clamp(0.0, 1.0);
  }

  bool get isPaid => remainingAmount <= 0.01;

  DebtModel copyWith({
    String? id,
    DebtType? type,
    String? personName,
    String? phoneNumber,
    double? totalAmount,
    double? remainingAmount,
    DateTime? dueDate,
    String? concept,
    DebtStatus? status,
    List<DebtPayment>? payments,
    DateTime? createdAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dueDate: dueDate ?? this.dueDate,
      concept: concept ?? this.concept,
      status: status ?? this.status,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'personName': personName,
      'phoneNumber': phoneNumber,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'dueDate': dueDate?.toIso8601String(),
      'concept': concept,
      'status': status.name,
      'payments': payments.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      type: json['type'] == 'payable' ? DebtType.payable : DebtType.receivable,
      personName: json['personName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      concept: json['concept'] as String?,
      status: DebtStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DebtStatus.pending,
      ),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => DebtPayment.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
