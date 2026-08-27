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
    } catch (e) {
      error = 'Login failed: could not authenticate with server';
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
