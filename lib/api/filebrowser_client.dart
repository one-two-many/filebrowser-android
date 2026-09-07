import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/file_entry.dart';

class FileBrowserClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // FileBrowser Quantum supports multiple named "sources" (storage
  // backends); every /api/resources call must say which one. The web UI
  // picks the user's first scope as the default, so we mirror that.
  String? _defaultSource;
  String? _username;

  FileBrowserClient({required String baseUrl})
    : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  String get baseUrl => _dio.options.baseUrl;

  Future<void> login(String username, String password) async {
    // FileBrowser Quantum takes the username as a query param and the
    // password in an X-Password header (URL-encoded), not a JSON body.
    final response = await _dio.post(
      '/api/auth/login',
      queryParameters: {'username': username},
      options: Options(headers: {'X-Password': Uri.encodeComponent(password)}),
    );
    final token = response.data as String;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _username = username;
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'server_url', value: baseUrl);
    await _storage.write(key: 'username', value: username);
    await _loadDefaultSource();
  }

  Future<bool> restoreSession() async {
    final token = await _storage.read(key: 'auth_token');
    final username = await _storage.read(key: 'username');
    if (token == null || username == null) return false;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _username = username;
    // Also confirms the saved token still works, not just that one exists.
    await _loadDefaultSource();
    return true;
  }

  Future<void> _loadDefaultSource() async {
    final response = await _dio.get(
      '/api/users',
      queryParameters: {'username': _username},
    );
    // This server wraps the result in a one-item list rather than returning
    // the user object directly — handle both shapes rather than assume one.
    final Map<String, dynamic> data;
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      data = list.isNotEmpty ? list.first as Map<String, dynamic> : {};
    } else {
      data = response.data as Map<String, dynamic>;
    }
    final scopes = data['scopes'] as List<dynamic>? ?? [];
    if (scopes.isNotEmpty) {
      _defaultSource = (scopes.first as Map<String, dynamic>)['name'] as String?;
    }
  }

  Future<void> logout() async {
    _dio.options.headers.remove('Authorization');
    await _storage.delete(key: 'auth_token');
  }

  Future<List<FileEntry>> listDirectory(String path) async {
    late final Response response;
    try {
      response = await _dio.get(
        '/api/resources',
        queryParameters: {
          'path': path,
          if (_defaultSource != null) 'source': _defaultSource,
        },
      );
    } on DioException catch (e) {
      // Surface the server's actual error body (if any), not just the
      // status code, so a 500 tells us *why* instead of just *that*.
      throw Exception(
        'GET /api/resources?path=$path failed: '
        '${e.response?.statusCode} ${e.response?.data ?? e.message}',
      );
    }
    final data = response.data as Map<String, dynamic>;
    final currentPath = data['path'] as String? ?? path;
    final folders = (data['folders'] as List<dynamic>? ?? [])
        .map(
          (e) => FileEntry.fromJson(
            e as Map<String, dynamic>,
            isDir: true,
            parentPath: currentPath,
          ),
        )
        .toList();
    final files = (data['files'] as List<dynamic>? ?? [])
        .map(
          (e) => FileEntry.fromJson(
            e as Map<String, dynamic>,
            isDir: false,
            parentPath: currentPath,
          ),
        )
        .toList();
    return [...folders, ...files];
  }
}
