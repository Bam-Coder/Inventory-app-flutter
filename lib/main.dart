import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/products/controllers/product_provider.dart';
import 'features/stock/controllers/stock_provider.dart';
import 'features/admin/controllers/admin_provider.dart';
import 'shared/themes/app_theme.dart'; // ✅ Chemin corrigé
import 'shared/navigation/app_routes.dart';
import 'features/auth/controllers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthProvider _authProvider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await _authProvider.tryAutoLogin();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Inventory Management',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: auth.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
