import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/class_group.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/event_card.dart';
import '../widgets/category_tab_bar.dart';
import 'add_event_screen.dart';
import 'archive_screen.dart';
import 'onboarding_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  final String classId;

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

  late TabController _tabController;
  String _selectedCategory = 'All';
  ClassGroup? _classGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClassGroup();
  }

  Future<void> _loadClassGroup() async {
    final group = await _firestoreService.getClass(widget.classId);
    if (mounted) setState(() => _classGroup = group);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  bool get _isAdmin =>
      _classGroup?.isAdmin(widget.user.uid) ?? false;

  Future<void> _signOut() async {
    await _authService.signOut();
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            title: Row(
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
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.archive_rounded),
                tooltip: 'Archive',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArchiveScreen(
                        user: widget.user,
                        classId: widget.classId,
                        isAdmin: _isAdmin,
                      ),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.user.photoURL != null
                      ? NetworkImage(widget.user.photoURL!)
                      : null,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: widget.user.photoURL == null
                      ? Text(
                          widget.user.displayName?.substring(0, 1) ?? 'U',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                onSelected: (val) {
                  if (val == 'signout') _signOut();
                  if (val == 'code' && _classGroup != null) {
                    _showClassCode(context, _classGroup!.classCode);
                  }
                },
                itemBuilder: (_) => [
                  if (_classGroup != null)
                    PopupMenuItem(
                      value: 'code',
                      child: Row(children: [
                        const Icon(Icons.key_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('Join Code: ${_classGroup!.classCode}'),
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
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
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
                  Tab(
                    text: _classGroup?.name ?? 'Class',
                  ),
                  const Tab(text: 'Personal'),
                ],
              ),
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
        ],
        body: Column(
          children: [
            const SizedBox(height: 12),
            CategoryTabBar(
              selected: _selectedCategory,
              onSelected: (cat) =>
                  setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Class feed
                  _EventFeed(
                    stream: _firestoreService
                        .classEventsStream(widget.classId),
                    category: _selectedCategory,
                    isAdmin: _isAdmin,
                    onDelete: (event) => _firestoreService.deleteClassEvent(
                        widget.classId, event.id),
                    emptyMessage: 'No upcoming class events.\nAdd one!',
                  ),
                  // Personal feed
                  _EventFeed(
                    stream: _firestoreService
                        .personalEventsStream(widget.user.uid),
                    category: _selectedCategory,
                    isAdmin: true, // user can always delete own events
                    onDelete: (event) =>
                        _firestoreService.deletePersonalEvent(
                            widget.user.uid, event.id),
                    emptyMessage: 'No personal events.\nAdd one!',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEventScreen(
                user: widget.user,
                classId: widget.classId,
                initialFeedIndex: _tabController.index,
              ),
            ),
          );
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
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
