import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'api/auth_provider.dart';
import 'screens/file_list_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const FileBrowserApp(),
    ),
  );
}

class FileBrowserApp extends StatefulWidget {
  const FileBrowserApp({super.key});

  @override
  State<FileBrowserApp> createState() => _FileBrowserAppState();
}

class _FileBrowserAppState extends State<FileBrowserApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = GoRouter(
      refreshListenable: auth,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final auth = context.watch<AuthProvider>();
            // Only ever build the file list once we know for sure a session
            // is active. Otherwise briefly show a spinner while `redirect`
            // (below) sends us to /login.
            if (auth.isLoading || !auth.isAuthenticated) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const FileListScreen();
          },
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ],
      redirect: (context, state) {
        if (auth.isLoading) return null;
        final loggingIn = state.matchedLocation == '/login';
        if (!auth.isAuthenticated) return loggingIn ? null : '/login';
        if (loggingIn) return '/';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FileBrowser',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: _router,
    );
  }
}
