import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import 'classes_screen.dart';
import 'dashboard_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────
const _bg = Color(0xFF1A1714);
const _surfaceHigh = Color(0xFF2C2820);
const _border = Color(0xFF3A3328);
const _primary = Color(0xFFF0A500);
const _onPrimary = Color(0xFF1A1714);
const _onSurface = Color(0xFFF5EFE6);
const _muted = Color(0xFF9C8E7E);
const _terracotta = Color(0xFFE8956D);
const _primaryContainer = Color(0xFF3D2E00);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _localService = LocalStorageService();

  bool _isLoading = false;
  String? _errorMessage;

  // After sign-in, show class setup
  bool _showClassSetup = false;
  bool _isCreating = true; // true = create, false = join
  final _classNameController = TextEditingController();
  final _joinCodeController = TextEditingController();

  User? _signedInUser;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _classNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _useOffline() async {
    await _localService.setOfflineMode(true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(user: null, classId: null),
        ),
      );
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred == null) {
        setState(() {
          _errorMessage = 'Sign-in returned null — Google OAuth client is likely '
              'missing from google-services.json. Enable Google Sign-In in '
              'Firebase Console → Authentication → Sign-in method, re-download '
              'google-services.json, then do a full flutter clean + flutter run.';
          _isLoading = false;
        });
        return;
      }
      final user = cred.user!;
      await _firestoreService.createOrUpdateUser(user);

      // Check if user already has classes → go straight to ClassesScreen
      final classes = await _firestoreService.getUserClasses(user.uid);
      if (classes.isNotEmpty) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ClassesScreen(user: user)),
          );
        }
        return;
      }

      // No classes yet → show class setup step
      setState(() {
        _signedInUser = user;
        _showClassSetup = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // Show full error detail for debugging (type + message + code)
        _errorMessage = '[${e.runtimeType}] ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _createClass() async {
    final name = _classNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _firestoreService.createClass(name, _signedInUser!.uid);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClassesScreen(user: _signedInUser!),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinClass() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final group = await _firestoreService.joinClassByCode(
          code, _signedInUser!.uid);
      if (group == null) {
        setState(() {
          _errorMessage = 'No class found with that code.';
          _isLoading = false;
        });
        return;
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClassesScreen(user: _signedInUser!),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo area
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      color: _onPrimary, size: 30),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Klok',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Academic Countdown Dashboard',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: _muted.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                if (!_showClassSetup) ...[
                  _SignInSection(
                    isLoading: _isLoading,
                    onSignIn: _signIn,
                    onUseOffline: _useOffline,
                  ),
                ] else ...[
                  _ClassSetupSection(
                    isCreating: _isCreating,
                    onToggle: (v) => setState(() => _isCreating = v),
                    classNameController: _classNameController,
                    joinCodeController: _joinCodeController,
                    isLoading: _isLoading,
                    onCreate: _createClass,
                    onJoin: _joinClass,
                    userName:
                        _signedInUser?.displayName?.split(' ').first ?? '',
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _terracotta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _terracotta.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: _terracotta, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: _terracotta,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onUseOffline;
  
  const _SignInSection({
    required this.isLoading,
    required this.onSignIn,
    required this.onUseOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FeatureRow(
            icon: Icons.timer_rounded, label: 'Live countdown for every event'),
        const SizedBox(height: 12),
        const _FeatureRow(
            icon: Icons.group_rounded,
            label: 'Shared class feed with join codes (requires sign-in)'),
        const SizedBox(height: 12),
        const _FeatureRow(
            icon: Icons.lock_rounded, label: 'Private personal event space'),
        const SizedBox(height: 12),
        const _FeatureRow(
            icon: Icons.notifications_rounded,
            label: 'Reminders at 1 day and 3 hours'),
        const SizedBox(height: 12),
        const _FeatureRow(
            icon: Icons.wifi_off_rounded,
            label: 'Separate Offline-Mode for privacy'),
        const SizedBox(height: 40),

        _GoogleSignInButton(isLoading: isLoading, onSignIn: onSignIn),
        
        const SizedBox(height: 14),

        // Offline / guest option
        TextButton(
          onPressed: isLoading ? null : onUseOffline,
          child: const Text(
            'Use without signing in (Offline-Mode)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSignIn;
  const _GoogleSignInButton({required this.isLoading, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: _onPrimary, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata_rounded, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ClassSetupSection extends StatelessWidget {
  final bool isCreating;
  final ValueChanged<bool> onToggle;
  final TextEditingController classNameController;
  final TextEditingController joinCodeController;
  final bool isLoading;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final String userName;

  const _ClassSetupSection({
    required this.isCreating,
    required this.onToggle,
    required this.classNameController,
    required this.joinCodeController,
    required this.isLoading,
    required this.onCreate,
    required this.onJoin,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hey $userName 👋',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _onSurface,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Set up your class to get started.',
          style: TextStyle(
            fontFamily: 'Inter',
            color: _muted,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 24),

        // Toggle
        Container(
          decoration: BoxDecoration(
            color: _surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Create class',
                  selected: isCreating,
                  onTap: () => onToggle(true),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'Join class',
                  selected: !isCreating,
                  onTap: () => onToggle(false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (isCreating) ...[
          _KlokTextField(
            controller: classNameController,
            label: 'Class name',
            hint: 'e.g. MCA 2026 Batch A',
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: _onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: _onPrimary, strokeWidth: 2))
                  : const Text(
                      'Create Class',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ] else ...[
          _KlokTextField(
            controller: joinCodeController,
            label: 'Join code',
            hint: 'e.g. XYZ123',
            icon: Icons.key_rounded,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: _onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: _onPrimary, strokeWidth: 2))
                  : const Text(
                      'Join Class',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _primary.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _primary : _muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _KlokTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextCapitalization textCapitalization;

  const _KlokTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.textCapitalization = TextCapitalization.words,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontFamily: 'Inter', color: _onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Inter', color: _muted),
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Inter', color: _muted.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, size: 30, color: _muted),
        filled: true,
        fillColor: _surfaceHigh,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}