import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/master_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Create state providers
  final authProvider = AuthProvider();
  
  // Try auto-login before rendering the app to prevent screen flickering
  try {
    await authProvider.tryAutoLogin();
  } catch (e) {
    // Catch any startup exception to prevent app crash
    debugPrint("Error trying auto login: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<MasterProvider>(create: (_) => MasterProvider()),
        ChangeNotifierProvider<EntryProvider>(create: (_) => EntryProvider()),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'BHQ HEMM Logs',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      home: authProvider.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
