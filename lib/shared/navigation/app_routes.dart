import 'package:flutter/material.dart';

// AUTH
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/profile_screen.dart';

// DASHBOARD
import '../../features/dashboard/screens/dashboard_screen.dart';

// PRODUCTS
import '../../features/products/screens/product_list_screen.dart';
import '../../features/products/screens/product_form_screen.dart';

// STOCK
import '../../features/stock/screens/stock_history_screen.dart';

// ADMIN
import '../../features/admin/screens/admin_dashboard_screen.dart';

// REPORTS
import '../../features/reports/screens/reports_screen.dart';

// EXPORT
import '../../features/export/screens/export_screen.dart';

// PROFILE
import '../../features/profile/screens/settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String productList = '/products';
  static const String productForm = '/products/form';
  static const String stockHistory = '/stock/history';
  static const String profile = '/profile';
  static const String adminDashboard = '/admin';
  static const String reports = '/reports';
  static const String export = '/export';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    dashboard: (context) => const DashboardScreen(),
    productList: (context) => const ProductListScreen(),
    productForm: (context) => const ProductFormScreen(),
    stockHistory: (context) => const StockHistoryScreen(),
    profile: (context) => const ProfileScreen(),
    adminDashboard: (context) => const AdminDashboardScreen(),
    reports: (context) => const ReportsScreen(),
    export: (context) => const ExportScreen(),
    settings: (context) => const SettingsScreen(),
  };
}
