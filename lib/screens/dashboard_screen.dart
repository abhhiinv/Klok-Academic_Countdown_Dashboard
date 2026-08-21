import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/class_group.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/event_card.dart';
import '../widgets/category_tab_bar.dart';
import 'add_event_screen.dart';
import 'archive_screen.dart';
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

class DashboardScreen extends StatefulWidget {
  /// null when in offline/guest mode
  final User? user;

  /// null when in offline/guest mode
  final String? classId;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.classId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _localService = LocalStorageService();

  late TabController _tabController;
  String _selectedCategory = 'All';
  ClassGroup? _classGroup;

  // For offline personal events we use a StreamController so deletes/adds
  // can trigger a refresh without Firestore.
  final _localEventsController = StreamController<List<Event>>.broadcast();

  bool get _isOffline => widget.user == null;

  @override
  void initState() {
    super.initState();
    // Online: 2 tabs (Class + Personal). Offline: 1 tab (Personal only).
    _tabController = TabController(length: _isOffline ? 1 : 2, vsync: this);
    if (!_isOffline) {
      _loadClassGroup();
    } else {
      _refreshLocalEvents();
    }
  }

  Future<void> _loadClassGroup() async {
    final group = await _firestoreService.getClass(widget.classId!);
    if (mounted) setState(() => _classGroup = group);
  }

  Future<void> _refreshLocalEvents() async {
    final events = await _localService.getPersonalEvents();
    if (!_localEventsController.isClosed) {
      _localEventsController.add(events);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _localEventsController.close();
    super.dispose();
  }

  bool get _isAdmin => _classGroup?.isAdmin(widget.user?.uid ?? '') ?? false;

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
    // Switch from signed-in to offline/guest mode
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

  Future<void> _signInForClass() async {
    // Clear offline flag and go back to onboarding so user can sign in
    await _localService.setOfflineMode(false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isOffline ? 'Personal' : (_classGroup?.name ?? 'Klok'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.5,
                      color: _onSurface,
                    ),
                  ),
                  const Spacer(),

                  // Archive
                  if (!_isOffline)
                    IconButton(
                      icon: const Icon(Icons.archive_outlined,
                          color: _muted, size: 32),
                      tooltip: 'Archive',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchiveScreen(
                            user: widget.user!,
                            classId: widget.classId!,
                            isAdmin: _isAdmin,
                          ),
                        ),
                      ),
                    ),

                  // Account menu
                  _isOffline
                      ? _OfflineMenu(onSignIn: _signInForClass)
                      : _OnlineMenu(
                          user: widget.user!,
                          classGroup: _classGroup,
                          onSignOut: _signOut,
                          onGoOffline: _goOffline,
                        ),

                  const SizedBox(width: 4),
                ],
              ),
            ),

            // ── Tab Bar (online) / Offline banner ─────────────────────
            if (!_isOffline)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: _primary,
                  unselectedLabelColor: _muted,
                  indicatorColor: _primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: _border,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: _classGroup?.name ?? 'Class'),
                    const Tab(text: 'Personal'),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 30, color: _terracotta),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Offline-Mode : Privacy first mode',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13, color: _onSurface),
                      ),
                    ),
                    GestureDetector(
                      onTap: _signInForClass,
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Join code chip (class tab only) ───────────────────────
            if (!_isOffline && _classGroup != null)
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final onClassTab = _tabController.index == 0;
                  return AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: onClassTab
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _JoinCodeChip(code: _classGroup!.classCode),
                    ),
                    secondChild: const SizedBox.shrink(),
                  );
                },
              ),

            const SizedBox(height: 14),

            // ── Category filter ────────────────────────────────────────
            CategoryTabBar(
              selected: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 12),

            // ── Feeds ─────────────────────────────────────────────────
            Expanded(
              child: _isOffline
                  ? _EventFeed(
                      stream: _localEventsController.stream,
                      category: _selectedCategory,
                      isAdmin: true,
                      onDelete: (event) async {
                        await _localService.deletePersonalEvent(event.id);
                        _refreshLocalEvents();
                      },
                      emptyMessage: 'No personal events.\nTap + to add one.',
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _EventFeed(
                          stream: _firestoreService
                              .classEventsStream(widget.classId!),
                          category: _selectedCategory,
                          isAdmin: _isAdmin,
                          onDelete: (event) => _firestoreService
                              .deleteClassEvent(widget.classId!, event.id),
                          emptyMessage:
                              'No upcoming class events.\nTap + to add one.',
                        ),
                        _EventFeed(
                          stream: _firestoreService
                              .personalEventsStream(widget.user!.uid),
                          category: _selectedCategory,
                          isAdmin: true,
                          onDelete: (event) =>
                              _firestoreService.deletePersonalEvent(
                                  widget.user!.uid, event.id),
                          emptyMessage:
                              'No personal events.\nTap + to add one.',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEventScreen(
                user: widget.user,
                classId: widget.classId,
                initialFeedIndex: _tabController.index,
                onLocalEventAdded: _isOffline ? _refreshLocalEvents : null,
              ),
            ),
          );
          if (_isOffline) _refreshLocalEvents();
        },
        icon: const Icon(Icons.add_rounded, color: _onPrimary),
        label: const Text('Add Event',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: _onPrimary,
                letterSpacing: 0.1)),
        backgroundColor: _primary,
        elevation: 0,
      ),
    );
  }
}

// ─── Join code chip ─────────────────────────────────────────────────────────

class _JoinCodeChip extends StatefulWidget {
  final String code;
  const _JoinCodeChip({required this.code});

  @override
  State<_JoinCodeChip> createState() => _JoinCodeChipState();
}

class _JoinCodeChipState extends State<_JoinCodeChip> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _copied ? _primaryContainer : _surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _copied ? _primary.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.key_rounded,
              size: 30,
              color: _copied ? _primary : _muted,
            ),
            const SizedBox(width: 6),
            Text(
              _copied ? 'Copied!' : 'Join code: ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: _copied ? _primary : _muted,
              ),
            ),
            if (!_copied)
              Text(
                widget.code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _onSurface.withValues(alpha: 0.75),
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Account menus ─────────────────────────────────────────────────────────

class _OfflineMenu extends StatelessWidget {
  final VoidCallback onSignIn;
  const _OfflineMenu({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: _surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      icon: const CircleAvatar(
        radius: 20,
        backgroundColor: _surfaceHigh,
        child: Icon(Icons.person_rounded, size: 24, color: _onSurface),
      ),
      onSelected: (val) {
        if (val == 'signin') onSignIn();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'signin',
          child: Row(children: [
            Icon(Icons.login_rounded, size: 24, color: _primary),
            SizedBox(width: 8),
            Text('Sign in for class access',
                style: TextStyle(fontFamily: 'Inter', color: _onSurface)),
          ]),
        ),
      ],
    );
  }
}

class _OnlineMenu extends StatelessWidget {
  final User user;
  final ClassGroup? classGroup;
  final VoidCallback onSignOut;
  final VoidCallback onGoOffline;
  
  const _OnlineMenu({
    required this.user,
    required this.classGroup,
    required this.onSignOut,
    required this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: _surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      icon: CircleAvatar(
        radius: 20,
        backgroundImage:
            user.photoURL != null ? NetworkImage(user.photoURL!) : null,
        backgroundColor: _primaryContainer,
        child: user.photoURL == null
            ? Text(
                user.displayName?.substring(0, 1) ?? 'U',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: _primary),
              )
            : null,
      ),
      onSelected: (val) {
        if (val == 'signout') onSignOut();
        if (val == 'offline') onGoOffline();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'offline',
          child: Row(children: [
            Icon(Icons.wifi_off_rounded, size: 18, color: _onSurface),
            SizedBox(width: 8),
            Text('Switch to offline mode',
                style: TextStyle(fontFamily: 'Inter', color: _onSurface)),
          ]),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'signout',
          child: Row(children: [
            Icon(Icons.logout_rounded, size: 18, color: _terracotta),
            SizedBox(width: 8),
            Text('Sign out',
                style: TextStyle(fontFamily: 'Inter', color: _terracotta)),
          ]),
        ),
      ],
    );
  }
}

// ─── Event feed ────────────────────────────────────────────────────────────

class _EventFeed extends StatelessWidget {
  final Stream<List<Event>> stream;
  final String category;
  final bool isAdmin;
  final Future<void> Function(Event) onDelete;
  final String emptyMessage;

  const _EventFeed({
    required this.stream,
    required this.category,
    required this.isAdmin,
    required this.onDelete,
    required this.emptyMessage,
  });

  List<Event> _filter(List<Event> events) {
    final upcoming = events.where((e) => !e.isPast).toList();
    final filtered = category == 'All'
        ? upcoming
        : upcoming.where((e) {
            final cat = category == 'Exams'
                ? 'exam'
                : category == 'Submissions'
                    ? 'submission'
                    : 'fest';
            return e.category == cat;
          }).toList();
          
    // Sort by date to maintain chronological urgency order
    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(fontFamily: 'Inter', color: _terracotta),
            ),
          );
        }

        final events = _filter(snapshot.data ?? []);

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 56,
                  color: _muted.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: _muted.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(
              event: event,
              isAdmin: isAdmin,
              onDelete: () => onDelete(event),
            );
          },
        );
      },
    );
  }
}