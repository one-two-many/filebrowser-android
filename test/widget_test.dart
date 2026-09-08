import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:filebrowser/api/auth_provider.dart';
import 'package:filebrowser/main.dart';
import 'package:filebrowser/theme/theme_controller.dart';

void main() {
  // flutter_secure_storage talks to the real device's secure storage over a
  // "platform channel". There's no real device in a widget test, so without
  // this fake responder the app would wait forever for an answer that never
  // comes. This tells it "nothing was saved" right away.
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('shows login screen when not authenticated', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const FileBrowserApp(),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Sign in'), findsWidgets);
  });
}
