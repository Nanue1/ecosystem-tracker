import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/location_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储
  final storage = StorageService();
  await storage.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<StorageService>(create: (_) => storage),
        Provider<LocationService>(create: (_) => LocationService()),
      ],
      child: const EcosystemTrackerApp(),
    ),
  );
}

class EcosystemTrackerApp extends StatelessWidget {
  const EcosystemTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '路亚生态追踪',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5016), // 丛林绿
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F0E8),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 3,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
