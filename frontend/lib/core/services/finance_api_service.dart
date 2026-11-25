import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/accounts/models/account.dart';
import '../../features/transactions/models/transaction.dart';

class FinanceSyncException implements Exception {
  const FinanceSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FinanceRecordChange {
  const FinanceRecordChange(this.collection, this.id, this.data, {this.previous});

  final String collection;
  final String id;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? previous;

  Map<String, Object?> toJson() => {
    'collection': collection, 'id': id, 'data': data, 'previous': previous,
  };
}

class FinanceApiService {
  static final _random = Random.secure();

  static String newId(String prefix) {
    final suffix = List.generate(16, (_) => _random.nextInt(256)
        .toRadixString(16).padLeft(2, '0')).join();
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$suffix';
  }

  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://kpital-api.onrender.com',
  );

  static const Duration _timeout = Duration(seconds: 65);

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<http.Response> _request(String token, String path,
      {String method = 'GET', Object? body}) async {
    try {
      final request = http.Request(method, Uri.parse('$_backendUrl/api/$path'));
      request.headers.addAll(_headers(token));
      if (body != null) request.body = jsonEncode(body);
      final response = await request.send()
          .then(http.Response.fromStream).timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      debugPrint('[Finanzas] $method $path: HTTP ${response.statusCode}');
      if (response.statusCode == 401) {
        throw const FinanceSyncException('Vuelve a iniciar sesión para sincronizar.');
      }
      if (response.statusCode == 409 || response.statusCode == 422) {
        final body = jsonDecode(response.body);
        final detail = body is Map ? body['detail'] : null;
        throw FinanceSyncException(detail is String
            ? detail
            : 'Revisa los datos ingresados antes de guardar.');
      }
    } on FinanceSyncException {
      rethrow;
    } catch (error) {
      debugPrint('[Finanzas] $method $path: ${error.runtimeType}');
    }
    throw const FinanceSyncException('No se pudo confirmar el guardado en la nube. Inténtalo de nuevo.');
  }

  static Future<List<Map<String, dynamic>>> syncRecords(
    String token,
    String collection,
    Iterable<Map<String, dynamic>> local,
  ) async {
    final response = await _request(token, 'finance/records/$collection/sync',
        method: 'POST', body: {
          'legacy': local.map((data) => {'id': data['id'], 'data': data}).toList(),
        });
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveRecords(String token, List<FinanceRecordChange> changes,
      {TransactionModel? transaction}) async {
    await _request(token, 'finance/records', method: 'POST', body: {
      'changes': changes.map((change) => change.toJson()).toList(),
      if (transaction != null) 'transaction': transaction.toJson(),
    });
  }

  static Future<List<Account>> syncAccounts(
    String token, List<Account> localAccounts,
  ) async {
    final response = localAccounts.isEmpty
        ? await _request(token, 'accounts')
        : await _request(token, 'accounts/sync', method: 'POST',
            body: {'accounts': localAccounts.map((a) => a.toJson()).toList()});
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>()
        .map(Account.fromJson).toList();
  }

  static Future<Account> saveAccount(String token, Account account,
      {bool createOnly = false, double? previousBalance}) async {
    final options = Uri(queryParameters: {
      if (createOnly) 'create_only': 'true',
      if (previousBalance == account.balance) 'preserve_balance': 'true',
      if (previousBalance != null && previousBalance != account.balance)
        'previous_balance': previousBalance.toString(),
    }).query;
    final path = options.isEmpty ? 'accounts' : 'accounts?$options';
    final response = await _request(token, path, method: 'POST',
        body: account.toJson());
    return Account.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteAccount(String token, String id) async {
    await _request(token, 'accounts/${Uri.encodeComponent(id)}', method: 'DELETE');
  }

  static Future<List<TransactionModel>> syncTransactions(
    String token, List<TransactionModel> localTransactions,
  ) async {
    final response = localTransactions.isEmpty
        ? await _request(token, 'transactions')
        : await _request(token, 'transactions/sync', method: 'POST',
            body: {'transactions': localTransactions.map((t) => t.toJson()).toList()});
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>()
        .map(TransactionModel.fromJson).toList();
  }

  static Future<TransactionModel> saveTransaction(String token, TransactionModel tx) async {
    final response = await _request(token, 'transactions', method: 'POST',
        body: tx.toJson());
    return TransactionModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteTransaction(String token, String id) async {
    await _request(token, 'transactions/${Uri.encodeComponent(id)}', method: 'DELETE');
  }

  static String requireSession(String? token) {
    if (token == null || token.isEmpty) {
      throw const FinanceSyncException('Inicia sesión para guardar en la nube.');
    }
    return token;
  }
}
