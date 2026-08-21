import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import '../utils/date_utils.dart' as du;

// ── Design tokens ────────────────────────────────────────────────────────
const _bg = Color(0xFF1A1714);
const _surfaceHigh = Color(0xFF2C2820);
const _border = Color(0xFF3A3328);
const _primary = Color(0xFFF0A500);
// const _onPrimary = Color(0xFF1A1714);
const _onSurface = Color(0xFFF5EFE6);
const _muted = Color(0xFF9C8E7E);
const _terracotta = Color(0xFFE8956D);
// const _primaryContainer = Color(0xFF3D2E00);

class ArchiveScreen extends StatelessWidget {
  final User user;
  final String classId;
  final bool isAdmin;

  const ArchiveScreen({
    super.key,
    required this.user,
    required this.classId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: _onSurface),
          title: const Text(
            'Archive',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: _onSurface,
            ),
          ),
          bottom: const TabBar(
            labelColor: _primary,
            unselectedLabelColor: _muted,
            indicatorColor: _primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: _border,
            labelStyle: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'Class'),
              Tab(text: 'Personal'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Class archive
            _ArchiveFeed(
              stream: firestoreService.classEventsStream(classId),
              isAdmin: isAdmin,
              onDelete: (event) =>
                  firestoreService.deleteClassEvent(classId, event.id),
            ),
            // Personal archive
            _ArchiveFeed(
              stream: firestoreService.personalEventsStream(user.uid),
              isAdmin: true,
              onDelete: (event) =>
                  firestoreService.deletePersonalEvent(user.uid, event.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveFeed extends StatelessWidget {
  final Stream<List<Event>> stream;
  final bool isAdmin;
  final Future<void> Function(Event) onDelete;

  const _ArchiveFeed({
    required this.stream,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading archive',
              style: const TextStyle(fontFamily: 'Inter', color: _terracotta),
            ),
          );
        }

        final pastEvents = (snapshot.data ?? [])
            .where((e) => e.isPast)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (pastEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_rounded,
                  size: 64,
                  color: _muted.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No past events yet.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: _muted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: pastEvents.length,
          itemBuilder: (context, index) {
            final event = pastEvents[index];
            return _ArchiveCard(
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

class _ArchiveCard extends StatelessWidget {
  final Event event;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _ArchiveCard({
    required this.event,
    required this.isAdmin,
    required this.onDelete,
  });

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'exam':
        return Icons.school_rounded;
      case 'submission':
        return Icons.assignment_rounded;
      case 'fest':
        return Icons.celebration_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Icon(
            _categoryIcon(event.category),
            color: _muted,
            size: 30,
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: _onSurface.withValues(alpha: 0.9),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            du.formatEventDate(event.date),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _muted,
            ),
          ),
        ),
        trailing: isAdmin
            ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: _terracotta, size: 22),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: _surfaceHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: _border),
                      ),
                      title: const Text(
                        'Delete?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: _onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: const Text(
                        'Remove this event from archive?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: _muted,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: _terracotta,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) onDelete();
                },
              )
            : null,
      ),
    );
  }
}