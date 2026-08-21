import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_group.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

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

class ClassesScreen extends StatefulWidget {
  final User user;

  const ClassesScreen({super.key, required this.user});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _localService = LocalStorageService();

  List<ClassGroup>? _classes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final classes = await _firestoreService.getUserClasses(widget.user.uid);
    if (mounted) {
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _goOffline() async {
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

  void _openJoinCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: _border),
      ),
      builder: (ctx) => _JoinCreateSheet(
        user: widget.user,
        firestoreService: _firestoreService,
        onDone: _loadClasses,
      ),
    );
  }

  void _openClass(ClassGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          user: widget.user,
          classId: group.id,
        ),
      ),
    ).then((_) => _loadClasses()); // refresh in case events were added
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.access_time_rounded,
                        color: _onPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Klok',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      color: _onSurface,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    color: _surfaceHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: _border),
                    ),
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundImage: widget.user.photoURL != null
                          ? NetworkImage(widget.user.photoURL!)
                          : null,
                      backgroundColor: _primaryContainer,
                      child: widget.user.photoURL == null
                          ? Text(
                              widget.user.displayName?.substring(0, 1) ?? 'U',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: _primary,
                              ),
                            )
                          : null,
                    ),
                    onSelected: (val) {
                      if (val == 'signout') _signOut();
                      if (val == 'offline') _goOffline();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'offline',
                        child: Row(children: [
                          Icon(Icons.wifi_off_rounded, size: 18, color: _onSurface),
                          SizedBox(width: 8),
                          Text('Switch to offline mode',
                              style: TextStyle(
                                  fontFamily: 'Inter', color: _onSurface)),
                        ]),
                      ),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem(
                        value: 'signout',
                        child: Row(children: [
                          Icon(Icons.logout_rounded, size: 18, color: _terracotta),
                          SizedBox(width: 8),
                          Text('Sign out',
                              style: TextStyle(
                                  fontFamily: 'Inter', color: _terracotta)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            // ── Title ─────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Text(
                'My Classes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: _onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                widget.user.displayName?.split(' ').first ?? 'Student',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: _muted,
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary))
                  : (_classes == null || _classes!.isEmpty)
                      ? _EmptyState(onJoinCreate: _openJoinCreate)
                      : RefreshIndicator(
                          onRefresh: _loadClasses,
                          color: _primary,
                          backgroundColor: _surfaceHigh,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: _classes!.length,
                            itemBuilder: (context, index) {
                              final group = _classes![index];
                              return _ClassCard(
                                group: group,
                                uid: widget.user.uid,
                                onTap: () => _openClass(group),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openJoinCreate,
        icon: const Icon(Icons.add_rounded, color: _onPrimary),
        label: const Text('Join / Create',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: _onPrimary)),
        backgroundColor: _primary,
        elevation: 0,
      ),
    );
  }
}

// ─── Class card ─────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final ClassGroup group;
  final String uid;
  final VoidCallback onTap;

  const _ClassCard({
    required this.group,
    required this.uid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = group.isAdmin(uid);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.group_rounded,
                color: _primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAdmin ? _primaryContainer : _bg,
                          border: Border.all(
                            color: isAdmin ? _primary : _border,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAdmin ? 'Admin' : 'Member',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAdmin ? _primary : _muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        group.classCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: _muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onJoinCreate;
  const _EmptyState({required this.onJoinCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_rounded,
              size: 72,
              color: _muted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              "You're not in any class yet",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Join a class with a code your admin shared, or create one for your batch.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: _muted.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onJoinCreate,
                icon: const Icon(Icons.add_rounded, color: _onPrimary),
                label: const Text('Join or Create a Class',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: _onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Join / Create bottom sheet ─────────────────────────────────────────────

class _JoinCreateSheet extends StatefulWidget {
  final User user;
  final FirestoreService firestoreService;
  final VoidCallback onDone;

  const _JoinCreateSheet({
    required this.user,
    required this.firestoreService,
    required this.onDone,
  });

  @override
  State<_JoinCreateSheet> createState() => _JoinCreateSheetState();
}

class _JoinCreateSheetState extends State<_JoinCreateSheet> {
  bool _isCreating = true;
  bool _isLoading = false;
  String? _error;

  final _classNameController = TextEditingController();
  final _joinCodeController = TextEditingController();

  @override
  void dispose() {
    _classNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _classNameController.text.trim();
    if (name.isEmpty) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.firestoreService.createClass(name, widget.user.uid);
      widget.onDone();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  Future<void> _join() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final group = await widget.firestoreService
          .joinClassByCode(code, widget.user.uid);
      if (group == null) {
        if (mounted) {
          setState(() {
            _error = 'No class found with that code. Check and try again.';
            _isLoading = false;
          });
        }
        return;
      }
      widget.onDone();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Add a class',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // Create / Join toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SheetTabButton(
                    label: 'Create class',
                    selected: _isCreating,
                    onTap: () => setState(() { _isCreating = true; _error = null; }),
                  ),
                ),
                Expanded(
                  child: _SheetTabButton(
                    label: 'Join with code',
                    selected: !_isCreating,
                    onTap: () => setState(() { _isCreating = false; _error = null; }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isCreating
                ? TextField(
                    key: const ValueKey('create'),
                    controller: _classNameController,
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                    style: const TextStyle(fontFamily: 'Inter', color: _onSurface),
                    decoration: InputDecoration(
                      labelText: 'Class name',
                      labelStyle: const TextStyle(fontFamily: 'Inter', color: _muted),
                      hintText: 'e.g. MCA 2026 Batch A',
                      hintStyle: TextStyle(
                          fontFamily: 'Inter', color: _muted.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.school_rounded, size: 20, color: _muted),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  )
                : TextField(
                    key: const ValueKey('join'),
                    controller: _joinCodeController,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    style: const TextStyle(fontFamily: 'Inter', color: _onSurface),
                    decoration: InputDecoration(
                      labelText: 'Join code',
                      labelStyle: const TextStyle(fontFamily: 'Inter', color: _muted),
                      hintText: 'e.g. XYZ123',
                      hintStyle: TextStyle(
                          fontFamily: 'Inter', color: _muted.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.key_rounded, size: 20, color: _muted),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: _terracotta,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_isCreating ? _create : _join),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: _onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: _onPrimary, strokeWidth: 2),
                    )
                  : Text(
                      _isCreating ? 'Create Class' : 'Join Class',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  
  const _SheetTabButton({
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _primary : Colors.transparent,
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