import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/file_entry.dart';

/// Thrown when the server refuses to create/overwrite something because a
/// file or folder already exists at that path (HTTP 409).
class ResourceConflictException implements Exception {
  final String message;
  ResourceConflictException(this.message);
  @override
  String toString() => message;
}

class FileBrowserClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // FileBrowser Quantum supports multiple named "sources" (storage
  // backends); every /api/resources call must say which one. The web UI
  // picks the user's first scope as the default, so we mirror that.
  String? _defaultSource;
  String? _username;

  FileBrowserClient({required String baseUrl})
    : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    // Some Android devices/networks fail plain DNS lookups for hostnames
    // that resolve fine in Chrome (which falls back gracefully between
    // IPv4/IPv6). Forcing an IPv4 lookup here sidesteps that gap instead of
    // relying on Dart's default resolution behavior.
    //
    // Setting connectionFactory bypasses HttpClient's own https handling
    // entirely — it hands back whatever Socket we return as-is, so for an
    // https:// URL we must perform the TLS handshake ourselves, connecting
    // to the resolved IP but verifying/SNI-ing against the real hostname.
    // Skipping this sent plaintext HTTP to the TLS port, which Cloudflare
    // rejected with "The plain HTTP request was sent to HTTPS port".
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.connectionFactory = (uri, proxyHost, proxyPort) async {
        final addresses = await InternetAddress.lookup(
          uri.host,
          type: InternetAddressType.IPv4,
        );
        if (addresses.isEmpty) {
          throw SocketException("Failed host lookup: '${uri.host}'");
        }
        final address = addresses.first;
        if (uri.scheme == 'https') {
          final Future<Socket> secureSocket = Socket.connect(
            address,
            uri.port,
          ).then((raw) => SecureSocket.secure(raw, host: uri.host));
          return ConnectionTask.fromSocket(secureSocket, () {});
        }
        return Socket.startConnect(address, uri.port);
      };
      return client;
    };
  }

  String get baseUrl => _dio.options.baseUrl;
  String? get authHeader => _dio.options.headers['Authorization'] as String?;
  String? get defaultSource => _defaultSource;

  String downloadUrl(String path) {
    final query = Uri(
      queryParameters: {
        if (_defaultSource != null) 'source': _defaultSource,
        'file': path,
      },
    ).query;
    return '$baseUrl/api/resources/download?$query';
  }

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

  Future<void> createFolder(String path, {bool override = false}) async {
    try {
      await _dio.post(
        '/api/resources',
        queryParameters: {
          'path': path,
          if (_defaultSource != null) 'source': _defaultSource,
          'isDir': 'true',
          if (override) 'override': 'true',
        },
        // The server returns an empty body on success — don't let Dio try
        // (and fail) to parse it as JSON, which would look like an error
        // even though the folder was created successfully.
        options: Options(responseType: ResponseType.plain),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw ResourceConflictException('A folder already exists at "$path"');
      }
      throw Exception(
        'POST /api/resources?path=$path failed: '
        '${e.response?.statusCode} ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> uploadFile(
    String path,
    Uint8List bytes, {
    bool override = false,
  }) async {
    try {
      await _dio.post(
        '/api/resources',
        queryParameters: {
          'path': path,
          if (_defaultSource != null) 'source': _defaultSource,
          'isDir': 'false',
          if (override) 'override': 'true',
        },
        data: Stream.fromIterable([bytes]),
        options: Options(
          contentType: 'application/octet-stream',
          headers: {Headers.contentLengthHeader: bytes.length},
          // Same empty-body-on-success issue as createFolder.
          responseType: ResponseType.plain,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw ResourceConflictException('A file already exists at "$path"');
      }
      throw Exception(
        'POST /api/resources?path=$path failed: '
        '${e.response?.statusCode} ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> deleteResource(String path) async {
    try {
      await _dio.delete(
        '/api/resources',
        queryParameters: {
          'path': path,
          if (_defaultSource != null) 'source': _defaultSource,
        },
        options: Options(responseType: ResponseType.plain),
      );
    } on DioException catch (e) {
      throw Exception(
        'DELETE /api/resources?path=$path failed: '
        '${e.response?.statusCode} ${e.response?.data ?? e.message}',
      );
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
