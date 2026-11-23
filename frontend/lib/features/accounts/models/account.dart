import 'package:flutter/material.dart';

enum AccountType {
  cash,
  bank,
  digitalWallet,
  savingsVault;

  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Efectivo';
      case AccountType.bank:
        return 'Banco';
      case AccountType.digitalWallet:
        return 'Billetera Digital / QR';
      case AccountType.savingsVault:
        return 'Bóveda de Ahorro';
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.digitalWallet:
        return Icons.qr_code_2_rounded;
      case AccountType.savingsVault:
        return Icons.lock_rounded;
    }
  }
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final String currency;
  final double balance;
  final bool isSavingsVault;
  final double? targetAmount; // Meta para bóvedas (ej. 8.000 Bs para fardo)
  final String colorHex;
  final String? iconName;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.currency = 'BOB',
    required this.balance,
    this.isSavingsVault = false,
    this.targetAmount,
    this.colorHex = '#3366D6',
    this.iconName,
    required this.createdAt,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF3366D6);
    }
  }

  IconData get icon => type.defaultIcon;

  double get progressPercentage {
    if (targetAmount == null || targetAmount! <= 0) return 0.0;
    return (balance / targetAmount!).clamp(0.0, 1.0);
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? currency,
    double? balance,
    bool? isSavingsVault,
    double? targetAmount,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      isSavingsVault: isSavingsVault ?? this.isSavingsVault,
      targetAmount: targetAmount ?? this.targetAmount,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'currency': currency,
      'balance': balance,
      'isSavingsVault': isSavingsVault,
      'targetAmount': targetAmount,
      'colorHex': colorHex,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    AccountType parseType(String? val) {
      switch (val) {
        case 'cash':
          return AccountType.cash;
        case 'bank':
          return AccountType.bank;
        case 'digitalWallet':
          return AccountType.digitalWallet;
        case 'savingsVault':
          return AccountType.savingsVault;
        default:
          return AccountType.cash;
      }
    }

    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: parseType(json['type'] as String?),
      currency: json['currency'] as String? ?? 'BOB',
      balance: (json['balance'] as num).toDouble(),
      isSavingsVault: json['isSavingsVault'] as bool? ?? false,
      targetAmount: json['targetAmount'] != null ? (json['targetAmount'] as num).toDouble() : null,
      colorHex: json['colorHex'] as String? ?? '#3366D6',
      iconName: json['iconName'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }
}
