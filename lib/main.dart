import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/classes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The google-services Gradle plugin can pre-initialize Firebase natively.
  // Wrap in try-catch so we gracefully re-use the existing app.
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    // App already initialized by google-services native plugin — safe to continue.
  }

  await NotificationService.init();
  runApp(const KlokApp());
}

class KlokApp extends StatelessWidget {
  const KlokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klok',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const _AppRoot(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    // Exact design tokens used across all screens
    const bg = Color(0xFF1A1714);
    const surfaceHigh = Color(0xFF2C2820);
    const primary = Color(0xFFF0A500);
    const onPrimary = Color(0xFF1A1714);
    const onSurface = Color(0xFFF5EFE6);
    const muted = Color(0xFF9C8E7E);
    const border = Color(0xFF3A3328);
    const terracotta = Color(0xFFE8956D);
    const primaryContainer = Color(0xFF3D2E00);

    final colorScheme = ColorScheme.dark(
      surface: bg,
      onSurface: onSurface,
      primary: primary,
      onPrimary: onPrimary,
      secondary: terracotta,
      onSecondary: bg,
      error: terracotta,
      onError: onSurface,
      surfaceContainerHighest: surfaceHigh,
      outlineVariant: border,
      primaryContainer: primaryContainer,
      onPrimaryContainer: primary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: -0.3,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        labelStyle: const TextStyle(color: muted, fontFamily: 'Inter'),
        hintStyle: TextStyle(
            color: muted.withValues(alpha: 0.6), fontFamily: 'Inter'),
        prefixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracotta),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracotta, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        textStyle: const TextStyle(
            color: onSurface, fontFamily: 'Inter', fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final _authService = AuthService();
  final _localService = LocalStorageService();

  // null = still loading
  bool? _offlineMode;

  @override
  void initState() {
    super.initState();
    _checkOfflineMode();
  }

  Future<void> _checkOfflineMode() async {
    final offline = await _localService.isOfflineMode();
    if (mounted) setState(() => _offlineMode = offline);
  }

  @override
  Widget build(BuildContext context) {
    // Still reading prefs
    if (_offlineMode == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // User chose offline/guest mode — go straight to dashboard with no account
    if (_offlineMode == true) {
      return const DashboardScreen(user: null, classId: null);
    }

    // Otherwise check Firebase auth state
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const OnboardingScreen();
        }

        // Signed-in — show class list (ClassesScreen handles empty state)
        return ClassesScreen(user: user);
      },
    );
  }
}