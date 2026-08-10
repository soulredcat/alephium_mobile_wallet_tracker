import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

import '../models/alephium_snapshot.dart';
import '../models/alephium_transaction.dart';
import '../utils/constants.dart';

class AlephiumApiRepository {
  AlephiumApiRepository({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? defaultExplorerBaseUrl,
        _client = client ?? _createDefaultClient();

  final String _baseUrl;
  final http.Client _client;

  static http.Client _createDefaultClient() {
    return RetryClient(
      http.Client(),
      retries: 1,
      when: (response) => response.statusCode >= 500,
    );
  }

  static const Duration _requestTimeout = Duration(seconds: 15);

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(uri).timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'HTTP ${response.statusCode} - Failed to call ${uri.toString()}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      return body;
    }

    throw Exception('Invalid API response format');
  }

  Future<List<dynamic>> _getList(Uri uri) async {
    final response = await _client.get(uri).timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'HTTP ${response.statusCode} - Failed to call ${uri.toString()}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is List<dynamic>) {
      return body;
    }

    throw Exception('Invalid transaction API response format');
  }

  Future<WalletSnapshot> fetchAddressSummary(String address) async {
    final payload = await _getJson(
      _uri('/addresses/${Uri.encodeComponent(address)}'),
    );
    return WalletSnapshot.fromJson({
      ...payload,
      'fetchedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AlephiumTransaction>> fetchAddressTransactions({
    required String address,
    int page = 1,
    int limit = defaultTransactionPageSize,
  }) async {
    final payload = await _getList(
      _uri(
        '/addresses/${Uri.encodeComponent(address)}/transactions',
        <String, String>{'page': page.toString(), 'limit': limit.toString()},
      ),
    );

    return payload
        .whereType<Map<String, dynamic>>()
        .map((item) => AlephiumTransaction.fromJson(item, address))
        .toList(growable: false);
  }
}
