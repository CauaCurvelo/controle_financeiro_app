import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/auth/auth_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/analysis/analysis_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ControleFinanceiroApp(),
    ),
  );
}

class ControleFinanceiroApp extends StatelessWidget {
  const ControleFinanceiroApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EA),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthView(),
        '/dashboard': (context) => const DashboardView(),
        '/analysis': (context) => const AnalysisView(),
      },
    );
  }
}
