import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/accounts/models/account.dart';
import '../../features/transactions/models/transaction.dart';

class FinanceApiService {
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://kpital-api.onrender.com',
  );

  static const Duration _timeout = Duration(seconds: 10);

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // =========================================================================
  // CUENTAS
  // =========================================================================

  static Future<List<Account>?> fetchAccounts(String token) async {
    try {
      final url = Uri.parse('$_backendUrl/api/accounts');
      final res = await http.get(url, headers: _headers(token)).timeout(_timeout);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => Account.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[FinanceApiService] Error fetching accounts: $e');
    }
    return null;
  }

  static Future<Account?> saveAccount(String token, Account account) async {
    try {
      final url = Uri.parse('$_backendUrl/api/accounts');
      final res = await http
          .post(url, headers: _headers(token), body: jsonEncode(account.toJson()))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return Account.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[FinanceApiService] Error saving account: $e');
    }
    return null;
  }

  static Future<bool> deleteAccount(String token, String accountId) async {
    try {
      final url = Uri.parse('$_backendUrl/api/accounts/$accountId');
      final res = await http.delete(url, headers: _headers(token)).timeout(_timeout);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('[FinanceApiService] Error deleting account: $e');
      return false;
    }
  }

  static Future<List<Account>?> syncAccounts(String token, List<Account> localAccounts) async {
    try {
      final url = Uri.parse('$_backendUrl/api/accounts/sync');
      final body = jsonEncode({
        'accounts': localAccounts.map((a) => a.toJson()).toList(),
      });
      final res = await http.post(url, headers: _headers(token), body: body).timeout(_timeout);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => Account.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[FinanceApiService] Error syncing accounts: $e');
    }
    return null;
  }

  // =========================================================================
  // TRANSACCIONES
  // =========================================================================

  static Future<List<TransactionModel>?> fetchTransactions(String token) async {
    try {
      final url = Uri.parse('$_backendUrl/api/transactions');
      final res = await http.get(url, headers: _headers(token)).timeout(_timeout);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[FinanceApiService] Error fetching transactions: $e');
    }
    return null;
  }

  static Future<TransactionModel?> saveTransaction(String token, TransactionModel tx) async {
    try {
      final url = Uri.parse('$_backendUrl/api/transactions');
      final res = await http
          .post(url, headers: _headers(token), body: jsonEncode(tx.toJson()))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return TransactionModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[FinanceApiService] Error saving transaction: $e');
    }
    return null;
  }

  static Future<bool> deleteTransaction(String token, String transactionId) async {
    try {
      final url = Uri.parse('$_backendUrl/api/transactions/$transactionId');
      final res = await http.delete(url, headers: _headers(token)).timeout(_timeout);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('[FinanceApiService] Error deleting transaction: $e');
      return false;
    }
  }

  static Future<List<TransactionModel>?> syncTransactions(
      String token, List<TransactionModel> localTxs) async {
    try {
      final url = Uri.parse('$_backendUrl/api/transactions/sync');
      final body = jsonEncode({
        'transactions': localTxs.map((t) => t.toJson()).toList(),
      });
      final res = await http.post(url, headers: _headers(token), body: body).timeout(_timeout);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[FinanceApiService] Error syncing transactions: $e');
    }
    return null;
  }
}
