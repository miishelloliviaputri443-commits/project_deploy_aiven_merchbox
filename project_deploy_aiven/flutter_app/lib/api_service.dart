import 'dart:convert';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

final apiService = ApiService();

class ApiService {
  ApiService({http.Client? client})
      : _client = client ??
            (BrowserClient()..withCredentials = true);

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  final http.Client _client;

  Uri _uri(String path) {
    if (_configuredBaseUrl.isNotEmpty) {
      return Uri.parse(
        '${_configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '')}$path',
      );
    }
    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      return Uri.parse('http://localhost:3000$path');
    }
    return Uri.base.resolve(path);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, _uri(path))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw ApiException(
        'Server mengembalikan respons yang tidak valid.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Format respons server tidak valid.');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] == false) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Permintaan gagal.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  Future<User?> currentUser() async {
    final result = await _request('GET', '/api/auth/me');
    final data = result['data'];
    return data is Map<String, dynamic> ? User.fromJson(data) : null;
  }

  Future<void> login(String email, String password) async {
    await _request('POST', '/api/auth/login', body: {
      'email': email,
      'password': password,
    });
  }

  Future<void> register(String name, String email, String password) async {
    await _request('POST', '/api/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<void> logout() async {
    await _request('POST', '/api/auth/logout');
  }

  Future<List<Product>> products({bool admin = false}) async {
    final result = await _request(
      'GET',
      admin ? '/api/products?admin=1' : '/api/products',
    );
    return _list(result['data'], Product.fromJson);
  }

  Future<void> saveProduct(Product product, {int? id}) async {
    await _request(
      id == null ? 'POST' : 'PUT',
      id == null ? '/api/products' : '/api/products/$id',
      body: product.toJson(),
    );
  }

  Future<void> deleteProduct(int id) async {
    await _request('DELETE', '/api/products/$id');
  }

  Future<List<CartItem>> cart() async {
    final result = await _request('GET', '/api/cart');
    return _list(result['data'], CartItem.fromJson);
  }

  Future<void> setCartQuantity(int productId, int quantity) async {
    await _request('POST', '/api/cart', body: {
      'productId': productId,
      'quantity': quantity,
    });
  }

  Future<void> removeCartItem(int productId) async {
    await _request('DELETE', '/api/cart?productId=$productId');
  }

  Future<void> clearCart() async {
    await _request('DELETE', '/api/cart');
  }

  Future<void> createOrder({
    required int productId,
    required int quantity,
  }) async {
    await _request('POST', '/api/orders', body: {
      'productId': productId,
      'quantity': quantity,
    });
  }

  Future<void> checkout(List<CartItem> items) async {
    await _request('POST', '/api/orders', body: {
      'items': items
          .map((item) => {
                'productId': item.productId,
                'quantity': item.quantity,
              })
          .toList(),
    });
  }

  Future<String?> sendRequest(String message) async {
    final result = await _request('POST', '/api/requests', body: {
      'message': message,
    });
    final data = result['data'];
    return data is Map<String, dynamic>
        ? data['adminEmail']?.toString()
        : null;
  }

  Future<List<ProductRequest>> requests() async {
    final result = await _request('GET', '/api/requests');
    return _list(result['data'], ProductRequest.fromJson);
  }

  Future<void> markRequestRead(int id) async {
    await _request('PATCH', '/api/requests/$id');
  }

  Future<void> deleteRequest(int id) async {
    await _request('DELETE', '/api/requests/$id');
  }

  List<T> _list<T>(
    Object? data,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(parse)
        .toList(growable: false);
  }
}
