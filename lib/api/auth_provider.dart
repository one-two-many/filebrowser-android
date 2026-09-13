import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'filebrowser_client.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  FileBrowserClient? _client;
  bool isAuthenticated = false;
  bool isLoading = true;
  String? error;

  FileBrowserClient get client {
    final c = _client;
    if (c == null) {
      throw StateError('Not authenticated');
    }
    return c;
  }

  AuthProvider() {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    try {
      final serverUrl = await _storage.read(key: 'server_url');
      if (serverUrl != null) {
        final client = FileBrowserClient(baseUrl: serverUrl);
        final restored = await client.restoreSession();
        if (restored) {
          _client = client;
          isAuthenticated = true;
        }
      }
    } catch (_) {
      // No usable stored session; fall through to the login screen.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String serverUrl, String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final client = FileBrowserClient(baseUrl: serverUrl);
      await client.login(username, password);
      _client = client;
      isAuthenticated = true;
    } on DioException catch (e) {
      // Surface the real cause instead of a generic message, so we can
      // actually tell a wrong password apart from a network/server problem.
      if (e.response != null) {
        error = 'Login failed: server responded with ${e.response?.statusCode}';
      } else {
        error = 'Login failed: ${e.type.name} — ${e.message}';
      }
      debugPrint(
        'Login error: status=${e.response?.statusCode} '
        'body=${e.response?.data} message=${e.message}',
      );
    } catch (e) {
      error = 'Login failed: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _client?.logout();
    _client = null;
    isAuthenticated = false;
    notifyListeners();
  }
}
