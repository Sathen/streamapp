import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/providers/download_manager.dart';
import 'package:stream_flutter/routes.dart';

import 'client/auth_jellyfin_server.dart';
import 'providers/auth_provider.dart';
import 'screens/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.init();

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider(authService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DownloadManager>(
          create: (_) => DownloadManager(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = createRouter(context.read<AuthProvider>());

          return MaterialApp.router(
            title: 'Jellyfin App',
            theme: AppTheme.darkTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
