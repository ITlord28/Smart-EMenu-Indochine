import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'screens/auth/login_screen.dart';
import 'core/utils/dummy_data_generator.dart';

import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'screens/e-menu/emenu_screen.dart';
import 'screens/cashier/cashier_dashboard.dart';
import 'screens/chef/chef_dashboard.dart';
import 'screens/manager/manager_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Gọi hàm seedData (chạy nền, không block UI)
  DummyDataGenerator.seedData().catchError((e) => print('Seed data error: $e'));

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (e) {
    debugPrint('Lỗi xoay màn hình (thường gặp trên iPad Simulator): $e');
  }

  // Đọc SharedPreferences để auto-login
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString('role');
  final userId = prefs.getString('userId');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: SmartEMenuApp(initialRole: role, initialUserId: userId),
    ),
  );
}

class SmartEMenuApp extends StatelessWidget {
  final String? initialRole;
  final String? initialUserId;

  const SmartEMenuApp({super.key, this.initialRole, this.initialUserId});

  @override
  Widget build(BuildContext context) {
    Widget homeScreen = const LoginScreen();
    
    if (initialRole != null && initialUserId != null) {
      switch (initialRole) {
        case 'customer':
          homeScreen = EMenuScreen(tableInfo: initialUserId!);
          break;
        case 'cashier':
          homeScreen = const CashierDashboard();
          break;
        case 'chef':
          homeScreen = const ChefDashboard();
          break;
        case 'manager':
          homeScreen = const ManagerDashboard();
          break;
      }
    }

    return MaterialApp(
      title: 'Smart E-Menu Indochine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Playfair Display',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: AppColors.text),
        ),
      ),
      home: homeScreen,
    );
  }
}
