import 'package:flutter/material.dart';
import '../models/event.dart';
import '../utils/date_utils.dart' as du;

// ── Design tokens ────────────────────────────────────────────────────────
const _bg = Color(0xFF1A1714);
const _surfaceHigh = Color(0xFF2C2820);
const _border = Color(0xFF3A3328);
const _primary = Color(0xFFF0A500);
const _onSurface = Color(0xFFF5EFE6);
const _muted = Color(0xFF9C8E7E);
const _terracotta = Color(0xFFE8956D);

class EventCard extends StatefulWidget {
  final Event event;
  final bool isAdmin;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.isAdmin = false,
    this.onDelete,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (widget.event.urgencyLevel == 0 && !widget.event.isPast) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event.urgencyLevel == 0 && !widget.event.isPast) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
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

  Color _getUrgencyColor() {
    if (widget.event.isPast) return _muted;
    switch (widget.event.urgencyLevel) {
      case 0:
        return const Color.fromARGB(255, 255, 91, 91); // Urgent (Red/Terracotta)
      case 1:
        return _primary; // Soon (Yellow/Amber)
      default:
        return const Color.fromARGB(255, 68, 191, 55); // Relaxed (Earthy Green)
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => RepaintBoundary(
        child: Transform.scale(
          scale: (widget.event.urgencyLevel == 0 && !widget.event.isPast)
              ? _scale.value
              : 1.0,
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored urgency stripe
              Container(
                width: 4,
                color: urgencyColor,
              ),
              
              // Main card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left side: Event info & Countdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                // Category icon dot
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _border),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(widget.event.category),
                                    size: 30,
                                    color: _muted,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title & Date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.event.title,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        du.formatEventDate(widget.event.date),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Countdown pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 16, color: urgencyColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.event.isPast
                                          ? 'Event has passed'
                                          : du.formatCountdown(widget.event.date),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: urgencyColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Right side: The Larger, Centered Delete Button
                      if (widget.isAdmin && widget.onDelete != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: _terracotta, size: 28),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: _surfaceHigh,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: _border),
                                  ),
                                  title: const Text('Delete Event',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: _onSurface,
                                          fontWeight: FontWeight.w700)),
                                  content: const Text(
                                      'Are you sure you want to delete this event?',
                                      style: TextStyle(
                                          fontFamily: 'Inter', color: _muted)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel',
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: _muted,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete',
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: _terracotta,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                widget.onDelete!();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}