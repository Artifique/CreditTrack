import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/dashboard/dashboard_page.dart';
import 'views/operations/new_transaction_page.dart';
import 'views/history/history_page.dart';
import 'views/settings/settings_page.dart';
import 'views/settings/business_profile_page.dart';
import 'views/settings/printer_settings_page.dart';
import 'views/reports/reports_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Supabase (remplacez par vos clés)
  await Supabase.initialize(
    url: 'https://VOTRE_PROJET.supabase.co',
    anonKey: 'VOTRE_ANON_KEY',
  );

  runApp(const CreditTrakApp());
}

class CreditTrakApp extends StatelessWidget {
  const CreditTrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CreditTrak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/dashboard',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/new-transaction': (context) => const NewTransactionPage(),
        '/history': (context) => const HistoryPage(),
        '/settings': (context) => const SettingsPage(),
        '/settings-business': (context) => const BusinessProfilePage(),
        '/settings-printer': (context) => const PrinterSettingsPage(),
        '/reports': (context) => const ReportsPage(),
      },
    );
  }
}
