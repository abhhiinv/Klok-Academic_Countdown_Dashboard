import 'package:flutter/material.dart';

/// Returns urgency color based on days until event.
/// Red < 3 days, Orange < 7 days, Green otherwise.
Color getUrgencyColor(DateTime eventDate) {
  final diff = eventDate.difference(DateTime.now()).inDays;
  if (diff < 3) return const Color(0xFFE53935); // Red
  if (diff < 7) return const Color(0xFFFB8C00); // Orange
  return const Color(0xFF43A047); // Green
}

/// Returns urgency label text.
String getUrgencyLabel(DateTime eventDate) {
  final diff = eventDate.difference(DateTime.now()).inDays;
  if (diff < 1) return 'Today';
  if (diff < 2) return 'Tomorrow';
  if (diff < 3) return 'In 2 days';
  if (diff < 7) return 'This week';
  return 'Upcoming';
}

/// Formats a Duration into a human-readable countdown string.
String formatCountdown(DateTime eventDate) {
  final now = DateTime.now();
  final diff = eventDate.difference(now);

  if (diff.isNegative) return 'Ended';

  final days = diff.inDays;
  final hours = diff.inHours % 24;
  final minutes = diff.inMinutes % 60;

  if (days > 0) return '${days}d ${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

/// Formats a DateTime to a readable date string.
String formatEventDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final weekday = weekdays[date.weekday - 1];
  return '$weekday, ${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Generates a random 6-character alphanumeric join code.
String generateJoinCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = List.generate(6, (_) {
    final idx = DateTime.now().millisecondsSinceEpoch % chars.length;
    return chars[idx];
  });
  return random.join();
}
