import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_clone/screens/home/search_users_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://dswzykuijbtwivmbopqi.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd3p5a3VpamJ0d2l2bWJvcHFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0MjE2NjQsImV4cCI6MjA3ODk5NzY2NH0.SnKTGJaNEqKK64Nmnf7XcbvoP3FcVQ-HKAeq72aqtn4',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Chat em Tempo Real',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0EA5E9), // Vibrant sky blue
            primary: const Color(0xFF0EA5E9),
            secondary: const Color(0xFF06B6D4), // Cyan accent
            tertiary: const Color(0xFF8B5CF6), // Soft purple
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF06B6D4),
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0EA5E9),
            primary: const Color(0xFF0EA5E9),
            secondary: const Color(0xFF06B6D4),
            tertiary: const Color(0xFF8B5CF6),
            brightness: Brightness.dark,
            surface: const Color(0xFF1E293B),
            background: const Color(0xFF0F172A),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF06B6D4),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: const Color(0xFF334155),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authProvider = context.read<AuthProvider>();
    final presenceService = PresenceService();

    if (authProvider.currentUser != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          // App voltou para o foreground
          presenceService.setOnlineStatus(true);
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          // App foi para o background
          presenceService.setOnlineStatus(false);
          break;
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  void _initializeAuth() {
    final authProvider = context.read<AuthProvider>();

    // Se o usuário estiver autenticado, atualiza presença
    if (authProvider.currentUser != null) {
      final presenceService = PresenceService();
      presenceService.setOnlineStatus(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.currentUser != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
