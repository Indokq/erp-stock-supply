import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/home/quick_access_page.dart';
import 'features/shared/services/auth_service.dart';

class RemoteErpStockApp extends StatelessWidget {
  const RemoteErpStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EOS - Stock Supply',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AuthGuard(
        child: const QuickAccessPage(),
        loginPage: const LoginPage(),
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => AuthGuard(
              child: const QuickAccessPage(),
              loginPage: const LoginPage(),
            ),
      },
    );
  }
}

