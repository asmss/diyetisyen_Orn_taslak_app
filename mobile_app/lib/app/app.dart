import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/app_bootstrap.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/main_shell.dart';

class DietitianDemoApp extends StatelessWidget {
  const DietitianDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppBootstrap.providers,
      child: Consumer<AppSessionProvider>(
        builder: (context, session, _) {
          return MaterialApp(
            title: 'Diyetisyen Demo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: session.isAuthenticated
                ? const MainShell()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
