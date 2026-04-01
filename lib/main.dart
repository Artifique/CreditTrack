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
    url: 'https://dcirsmtvrtiekfxhjtvo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjaXJzbXR2cnRpZWtmeGhqdHZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwNDQ5OTcsImV4cCI6MjA5MDYyMDk5N30.asGxG9RsACj_mLzl782dk8EBST5QAIavlHVWnOrQ64I',
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
      home: const AuthWrapper(),
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session != null) {
          return const DashboardPage();
        }
        return const LoginPage();
      },
    );
  }
}
