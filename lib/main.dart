import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forui/forui.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/reset_password_screen.dart';
import 'config/app_config.dart';
import 'models/models.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _initialRoute;
  Map<String, String>? _initialRouteParams;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  void _checkInitialRoute() {
    // Check if app was opened via a deep link (for password reset)
    // This works for web by checking URL parameters
    try {
      final uri = Uri.base;
      if (uri.pathSegments.contains('reset-password') || 
          uri.queryParameters.containsKey('access_token')) {
        _initialRoute = '/reset-password';
        _initialRouteParams = uri.queryParameters;
      }
    } catch (e) {
      // If URI parsing fails, continue with default route
    }
  }

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
        '/reset-password': (context) {
          // Extract token and type from route parameters or URL
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          final token = args?['token'] ?? _initialRouteParams?['access_token'];
          final type = args?['type'] ?? _initialRouteParams?['type'];
          
          return ResetPasswordScreen(
            token: token,
            type: type,
          );
        },
      },
      home: _initialRoute != null 
          ? ResetPasswordScreen(
              token: _initialRouteParams?['access_token'],
              type: _initialRouteParams?['type'],
            )
          : const AuthGate(),
      onGenerateRoute: (settings) {
        // Handle deep links with query parameters
        if (settings.name == '/reset-password') {
          final uri = Uri.parse(settings.name ?? '');
          final token = uri.queryParameters['access_token'] ?? 
                       (settings.arguments as Map<String, String>?)?['token'];
          final type = uri.queryParameters['type'] ?? 
                      (settings.arguments as Map<String, String>?)?['type'];
          
          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: token,
              type: type,
            ),
          );
        }
        return null;
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkPasswordResetLink();
  }

  void _checkPasswordResetLink() {
    // Check if URL contains password reset parameters (for web)
    if (AppConfig.isMockMode) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final uri = Uri.base;
        if (uri.queryParameters.containsKey('access_token') && 
            uri.queryParameters['type'] == 'recovery') {
          // Navigate to reset password screen
          final token = uri.queryParameters['access_token'];
          final type = uri.queryParameters['type'];
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                token: token,
                type: type,
              ),
            ),
          );
        }
      } catch (e) {
        // Ignore errors in URI parsing
      }
    });
  }

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

        if (session == null) {
          return const LoginScreen();
        }

        // User is logged in - check if onboarding is complete
        return FutureBuilder<UserProfile?>(
          future: AppConfig.instance.authRepository.getCurrentProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final profile = profileSnapshot.data;

            // If no profile or onboarding not complete, show onboarding
            if (profile == null || !profile.onboardingCompleto) {
              return const OnboardingScreen();
            }

            // Onboarding complete, show main app
            return const AppShell();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando...'),
          ],
        ),
      ),
    );
  }
}
