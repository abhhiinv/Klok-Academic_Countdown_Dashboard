import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';

import '../utils/date_utils.dart' as du;

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
    final theme = Theme.of(context);
    final firestoreService = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Archive',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 14),
            tabs: const [
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
              stream:
                  firestoreService.personalEventsStream(user.uid),
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
    final theme = Theme.of(context);

    return StreamBuilder<List<Event>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No past events yet.',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _categoryIcon(event.category),
            color: Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            du.formatEventDate(event.date),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        trailing: isAdmin
            ? IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: Colors.grey.shade400, size: 20),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete?'),
                      content: const Text(
                          'Remove this event from archive?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Delete'),
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
