import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forui/forui.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell.dart';
import 'config/app_config.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize app config from environment
    // Run with: flutter run --dart-define=MOCK_MODE=true
    AppConfig.initializeFromEnvironment();
    
    if (AppConfig.isMockMode) {
      // Skip Supabase in mock mode
      print('🧪 Running in MOCK MODE - no Supabase connection');
    } else {
      // Production mode - initialize Supabase
      await dotenv.load(fileName: ".env");
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      );
    }

    runApp(const MyApp());
  } catch (e, stack) {
    print('CRITICAL ERROR: $e');
    print(stack);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetter',
      debugShowCheckedModeBanner: false,
      // Wrap in FAnimatedTheme for ForUI support
      builder: (context, child) => FAnimatedTheme(
        data: FThemes.zinc.light,
        child: child!,
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // In mock mode, skip Supabase auth and go directly to home
    if (AppConfig.isMockMode) {
      return const AppShell();
    }

    // Production mode - use Supabase auth state
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session != null) {
          return const AppShell();
        }

        return const LoginScreen();
      },
    );
  }
}
