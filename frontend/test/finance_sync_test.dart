import 'dart:convert';

import 'package:finanzas_app/core/services/finance_api_service.dart';
import 'package:finanzas_app/features/accounts/models/account.dart';
import 'package:finanzas_app/features/accounts/providers/accounts_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A cached account is retried until the cloud accepts it', () async {
    final account = Account(
      id: 'acc_bcp',
      name: 'BCP',
      type: AccountType.bank,
      balance: 0,
      createdAt: DateTime(2026, 11, 25),
    );
    const key = 'kpital_accounts_test-user_v2';
    SharedPreferences.setMockInitialValues({
      key: jsonEncode([account.toJson()]),
    });
    var reachable = false;
    final requests = <String>[];
    final cloud = <dynamic>[];
    final provider = AccountsProvider();
    addTearDown(provider.dispose);

    await http.runWithClient(() async {
      await provider.setAuthSession(userId: 'test-user', token: 'test-token');
      expect(provider.accounts.single.id, account.id);
      expect(provider.syncError, isNotNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${key}_imported'), isNull);

      reachable = true;
      await provider.synchronize();
      expect(provider.syncError, isNull);
      expect(prefs.getBool('${key}_imported'), isTrue);
      expect(cloud.single['id'], account.id);

      await provider.synchronize();
      expect(requests, ['/api/accounts/sync', '/api/accounts/sync', '/api/accounts']);

      SharedPreferences.setMockInitialValues({});
      final otherDevice = AccountsProvider();
      addTearDown(otherDevice.dispose);
      await otherDevice.setAuthSession(userId: 'test-user', token: 'other-token');
      expect(otherDevice.accounts.single.id, account.id);
    }, () => MockClient((request) async {
      requests.add(request.url.path);
      if (!reachable) return http.Response('', 503);
      if (request.method == 'POST') {
        cloud.addAll(jsonDecode(request.body)['accounts'] as List);
      }
      return http.Response(jsonEncode(cloud), 200);
    }));
  });

  test('A new account appears after the server confirms it', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AccountsProvider();
    addTearDown(provider.dispose);
    final sentIds = <String>[];
    var reachable = false;

    await http.runWithClient(() async {
      await provider.setAuthSession(userId: 'test-user', token: 'test-token');
      Future<void> save() => provider.addAccount(
            accountId: 'acc_draft',
            name: 'BCP',
            type: AccountType.bank,
            initialBalance: 0,
          );

      await expectLater(save(), throwsA(isA<FinanceSyncException>()));
      expect(provider.accounts, isEmpty);

      reachable = true;
      await save();
      expect(provider.accounts.single.id, 'acc_draft');
      expect(sentIds, ['acc_draft', 'acc_draft']);
    }, () => MockClient((request) async {
      if (request.method == 'GET') return http.Response('[]', 200);
      final account = jsonDecode(request.body) as Map<String, dynamic>;
      sentIds.add(account['id'] as String);
      if (!reachable) return http.Response('', 503);
      return http.Response(jsonEncode(account), 200);
    }));
  });
}
