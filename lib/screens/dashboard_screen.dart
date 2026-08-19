import 'dart:async';
import 'package:flutter/material.dart';
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
          builder: (_) => DashboardScreen(user: null, classId: null),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
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
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.access_time_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Klok',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),

                  // Archive button — only available when signed in (has classId)
                  if (!_isOffline)
                    IconButton(
                      icon: const Icon(Icons.archive_rounded),
                      tooltip: 'Archive',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArchiveScreen(
                              user: widget.user!,
                              classId: widget.classId!,
                              isAdmin: _isAdmin,
                            ),
                          ),
                        );
                      },
                    ),

                  // Account menu
                  _isOffline
                      ? _OfflineMenu(onSignIn: _signInForClass)
                      : _OnlineMenu(
                          user: widget.user!,
                          classGroup: _classGroup,
                          onSignOut: _signOut,
                          onShowCode: () =>
                              _showClassCode(context, _classGroup!.classCode),
                          onGoOffline: _goOffline,
                        ),

                  const SizedBox(width: 4),
                ],
              ),
            ),

            // ── Tab Bar ───────────────────────────────────────────────
            if (!_isOffline)
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5),
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: _classGroup?.name ?? 'Class'),
                  const Tab(text: 'Personal'),
                ],
              )
            else
              // Offline: show a slim banner explaining state
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline mode — personal events only',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _signInForClass,
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Category Filter ────────────────────────────────────────
            const SizedBox(height: 12),
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
                      emptyMessage: 'No personal events.\nAdd one!',
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
                          emptyMessage: 'No upcoming class events.\nAdd one!',
                        ),
                        _EventFeed(
                          stream: _firestoreService
                              .personalEventsStream(widget.user!.uid),
                          category: _selectedCategory,
                          isAdmin: true,
                          onDelete: (event) =>
                              _firestoreService.deletePersonalEvent(
                                  widget.user!.uid, event.id),
                          emptyMessage: 'No personal events.\nAdd one!',
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
          // Refresh local events if offline after returning from add screen
          if (_isOffline) _refreshLocalEvents();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Event',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showClassCode(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Class Join Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code with your classmates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
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
      icon: const CircleAvatar(
        radius: 16,
        child: Icon(Icons.person_rounded, size: 18),
      ),
      onSelected: (val) {
        if (val == 'signin') onSignIn();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'signin',
          child: Row(children: [
            Icon(Icons.login_rounded, size: 18),
            SizedBox(width: 8),
            Text('Sign in for class access'),
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
  final VoidCallback onShowCode;
  final VoidCallback onGoOffline;
  const _OnlineMenu({
    required this.user,
    required this.classGroup,
    required this.onSignOut,
    required this.onShowCode,
    required this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundImage:
            user.photoURL != null ? NetworkImage(user.photoURL!) : null,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: user.photoURL == null
            ? Text(
                user.displayName?.substring(0, 1) ?? 'U',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      onSelected: (val) {
        if (val == 'signout') onSignOut();
        if (val == 'code' && classGroup != null) onShowCode();
        if (val == 'offline') onGoOffline();
      },
      itemBuilder: (_) => [
        if (classGroup != null)
          PopupMenuItem(
            value: 'code',
            child: Row(children: [
              const Icon(Icons.key_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Join Code: ${classGroup!.classCode}'),
            ]),
          ),
        const PopupMenuItem(
          value: 'offline',
          child: Row(children: [
            Icon(Icons.wifi_off_rounded, size: 18),
            SizedBox(width: 8),
            Text('Switch to offline mode'),
          ]),
        ),
        const PopupMenuItem(
          value: 'signout',
          child: Row(children: [
            Icon(Icons.logout_rounded, size: 18),
            SizedBox(width: 8),
            Text('Sign out'),
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
    if (category == 'All') return upcoming;
    final cat = category == 'Exams'
        ? 'exam'
        : category == 'Submissions'
            ? 'submission'
            : 'fest';
    return upcoming.where((e) => e.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
