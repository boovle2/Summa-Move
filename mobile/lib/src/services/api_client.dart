import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    FlutterSecureStorage? storage,
  })  : _http = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final http.Client _http;
  final FlutterSecureStorage _storage;

  Future<bool> get isAuthenticated async =>
      (await _storage.read(key: 'token')) != null;
  Future<String?> get currentUserName => _storage.read(key: 'user_name');
  Future<String?> get currentUserRole => _storage.read(key: 'user_role');

  Future<String> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final response = await _request(
      'POST',
      '/auth/login',
      authenticated: false,
      body: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    final userName = user['name'] as String;
    final userRole = user['role'] as String? ?? 'user';
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'user_name', value: userName);
    await _storage.write(key: 'user_role', value: userRole);
    return userName;
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final response = await _request(
      'POST',
      '/auth/register',
      authenticated: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'device_name': deviceName,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    final userName = user['name'] as String;
    final userRole = user['role'] as String? ?? 'user';
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'user_name', value: userName);
    await _storage.write(key: 'user_role', value: userRole);
    return userName;
  }

  Future<void> logout() async {
    try {
      await _request('DELETE', '/auth/logout');
    } finally {
      await clearLocalSession();
    }
  }

  Future<void> clearLocalSession() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_role');
  }

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) =>
      _request('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _request('DELETE', path);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final token = authenticated ? await _storage.read(key: 'token') : null;
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
        if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
      });

    if (body != null) request.body = jsonEncode(body);

    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, decoded);
    }

    return decoded;
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  String toString() => 'API request failed ($statusCode): $body';
}
