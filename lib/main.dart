import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/finance_view_model.dart';
import 'views/auth/auth_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/analysis/analysis_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
      ],
      child: const ControleFinanceiroApp(),
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
        fontFamily: 'Inter',
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
