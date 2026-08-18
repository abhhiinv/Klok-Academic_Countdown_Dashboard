import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

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
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _classNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
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

      // Check if user already has a class
      final userData = await _firestoreService.getUser(user.uid);
      final classId = userData?['classId'] as String?;
      if (classId != null && classId.isNotEmpty) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DashboardScreen(user: user, classId: classId),
            ),
          );
        }
        return;
      }

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
      final group = await _firestoreService.createClass(
          name, _signedInUser!.uid);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(user: _signedInUser!, classId: group.id),
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
            builder: (_) =>
                DashboardScreen(user: _signedInUser!, classId: group.id),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo area
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 32),

                Text(
                  'Klok',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Academic Countdown Dashboard\nfor KTU students.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                if (!_showClassSetup) ...[
                  _SignInSection(
                    isLoading: _isLoading,
                    onSignIn: _signIn,
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
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13),
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
  const _SignInSection(
      {required this.isLoading, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeatureRow(
            icon: Icons.timer_rounded, label: 'Live countdown for every event'),
        const SizedBox(height: 12),
        _FeatureRow(
            icon: Icons.group_rounded, label: 'Shared class feed with join codes'),
        const SizedBox(height: 12),
        _FeatureRow(
            icon: Icons.lock_rounded, label: 'Private personal event space'),
        const SizedBox(height: 12),
        _FeatureRow(
            icon: Icons.notifications_rounded,
            label: 'Reminders at 1 day and 3 hours'),

        const SizedBox(height: 40),

        _GoogleSignInButton(isLoading: isLoading, onSignIn: onSignIn),
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
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.75),
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
  const _GoogleSignInButton(
      {required this.isLoading, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata_rounded, size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hey $userName 👋',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set up your class to get started.',
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 24),

        // Toggle
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(child: _TabButton(
                label: 'Create class',
                selected: isCreating,
                onTap: () => onToggle(true),
              )),
              Expanded(child: _TabButton(
                label: 'Join class',
                selected: !isCreating,
                onTap: () => onToggle(false),
              )),
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
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Create Class',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Join Class',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
  const _TabButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
