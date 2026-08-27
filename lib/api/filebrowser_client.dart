import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/file_entry.dart';

class FileBrowserClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  FileBrowserClient({required String baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  String get baseUrl => _dio.options.baseUrl;

  Future<void> login(String username, String password) async {
    final response = await _dio.post(
      '/api/login',
      data: {'username': username, 'password': password},
    );
    final token = response.data as String;
    _dio.options.headers['X-Auth'] = token;
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'server_url', value: baseUrl);
  }

  Future<bool> restoreSession() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return false;
    _dio.options.headers['X-Auth'] = token;
    return true;
  }

  Future<void> logout() async {
    _dio.options.headers.remove('X-Auth');
    await _storage.delete(key: 'auth_token');
  }

  Future<List<FileEntry>> listDirectory(String path) async {
    final normalized = path.startsWith('/') ? path : '/$path';
    final response = await _dio.get('/api/resources$normalized');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
