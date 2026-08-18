// Event model
class Event {
  final String id;
  final String title;
  final String category; // exam | submission | fest | other
  final DateTime date;
  final String createdBy;
  final DateTime createdAt;
  final bool isPersonal;

  Event({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    this.isPersonal = false,
  });

  factory Event.fromFirestore(Map<String, dynamic> data, String id) {
    return Event(
      id: id,
      title: data['title'] as String,
      category: data['category'] as String,
      date: (data['date'] as dynamic).toDate() as DateTime,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as dynamic).toDate() as DateTime,
      isPersonal: data['isPersonal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'date': date,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  Duration get timeRemaining => date.difference(DateTime.now());

  bool get isPast => date.isBefore(DateTime.now());

  /// Returns urgency level: 0 = red (<3d), 1 = orange (<7d), 2 = green (14+d)
  int get urgencyLevel {
    final days = timeRemaining.inDays;
    if (days < 3) return 0;
    if (days < 7) return 1;
    return 2;
  }

  Event copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? date,
    String? createdBy,
    DateTime? createdAt,
    bool? isPersonal,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPersonal: isPersonal ?? this.isPersonal,
    );
  }
}
