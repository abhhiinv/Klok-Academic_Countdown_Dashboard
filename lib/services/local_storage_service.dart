import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

/// Persists personal events locally using shared_preferences.
/// Used when the user is in offline/guest mode (no Firebase account).
class LocalStorageService {
  static const _eventsKey = 'local_personal_events';
  static const _offlineModeKey = 'is_offline_mode';

  // ─── Offline mode flag ─────────────────────────────────────────────────────

  Future<void> setOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, value);
  }

  Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineModeKey) ?? false;
  }

  // ─── Local events ──────────────────────────────────────────────────────────

  Future<List<Event>> getPersonalEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_eventsKey) ?? [];
    return raw.map((json) => _eventFromJson(jsonDecode(json))).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> addPersonalEvent(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_eventsKey) ?? [];
    raw.add(jsonEncode(_eventToJson(event)));
    await prefs.setStringList(_eventsKey, raw);
  }

  Future<void> deletePersonalEvent(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_eventsKey) ?? [];
    raw.removeWhere((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['id'] == id;
    });
    await prefs.setStringList(_eventsKey, raw);
  }

  /// Returns a stream that emits once; wrap in StreamController for live updates.
  Stream<List<Event>> personalEventsStream() async* {
    yield await getPersonalEvents();
  }

  // ─── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> _eventToJson(Event e) => {
        'id': e.id,
        'title': e.title,
        'category': e.category,
        'date': e.date.toIso8601String(),
        'createdBy': e.createdBy,
        'createdAt': e.createdAt.toIso8601String(),
        'isPersonal': true,
      };

  Event _eventFromJson(Map<String, dynamic> m) => Event(
        id: m['id'] as String,
        title: m['title'] as String,
        category: m['category'] as String,
        date: DateTime.parse(m['date'] as String),
        createdBy: m['createdBy'] as String? ?? '',
        createdAt: DateTime.parse(m['createdAt'] as String),
        isPersonal: true,
      );
}
