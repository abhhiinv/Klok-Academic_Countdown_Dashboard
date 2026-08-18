# Klok
### Academic Countdown Dashboard

---

## Overview

Klok is a Flutter-based mobile application that helps college students track upcoming academic events through a visual countdown dashboard. Events are color-coded by urgency and organized into a shared class feed and a private personal feed.

---

## Problem Statement

College students manage multiple deadlines — exams, lab submissions, internal assessments, and fests — spread across different sources like WhatsApp groups, notice boards, and verbal announcements. There is no single, clean place to see everything that is coming up and how much time is left.

---

## Solution

Klok provides a shared class dashboard where one batch can collectively maintain upcoming events, alongside a private personal space for individual deadlines. Every event is displayed as a countdown card with urgency-based color coding so the most critical events are always visible at a glance.

---

## Target Users

MCA / B.Tech students at engineering colleges under KTU (APJ Abdul Kalam Technological University), Kerala.

---

## Features

### Core
- Countdown cards with live time remaining (days, hours, minutes)
- Traffic light urgency system
  - Red — under 3 days
  - Yellow — under 7 days
  - Green — 14+ days
- Category tabs — All, Exams, Submissions, Fests
- Archive tab for past events

### Class Feed
- Join or create a class group using a unique join code
- Any member can add events to the class feed
- Admin (class creator) can silently remove incorrect or false events
- Events sync every 30 minutes (no real-time sync required)

### Personal Feed
- Private events visible only to the logged-in user
- Same card UI as class feed, isolated from class data

### Platform
- Home screen widget via `home_widget` package for at-a-glance countdown without opening the app
- Local notifications at 1 day and 3 hours before each event

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Authentication | Firebase Auth (Google Sign-In) |
| Database | Cloud Firestore |
| Local Storage | SharedPreferences |
| Notifications | flutter_local_notifications |
| Home Widget | home_widget |

---

## Screens

1. **Onboarding** — Google Sign-In, then create or join a class via code
2. **Dashboard** — Two tabs: Class feed and Personal feed, sorted by urgency
3. **Add Event** — Form with title, category, date picker, and feed selector (Class / Personal)
4. **Archive** — Past events listed in reverse chronological order

---

## Data Model

### Firestore Structure

```
/classes/{classId}
  - classCode: string
  - name: string
  - adminUID: string
  - members: [UID, ...]

/classes/{classId}/events/{eventId}
  - title: string
  - category: string        // exam | submission | fest | other
  - date: timestamp
  - createdBy: UID
  - createdAt: timestamp

/users/{userId}
  - name: string
  - email: string
  - classId: string

/users/{userId}/personalEvents/{eventId}
  - title: string
  - category: string
  - date: timestamp
  - createdAt: timestamp
```

---

## Urgency Logic

```dart
Color getUrgencyColor(DateTime eventDate) {
  final diff = eventDate.difference(DateTime.now()).inDays;
  if (diff < 3) return Colors.red;
  if (diff < 7) return Colors.orange;
  return Colors.green;
}
```

---

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── event.dart
│   └── class_group.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── notification_service.dart
├── screens/
│   ├── onboarding_screen.dart
│   ├── dashboard_screen.dart
│   ├── add_event_screen.dart
│   └── archive_screen.dart
├── widgets/
│   ├── event_card.dart
│   ├── urgency_badge.dart
│   └── category_tab_bar.dart
└── utils/
    └── date_utils.dart
```

---

## Scope Boundaries

**In scope**
- Event creation, listing, and deletion
- Class group creation and joining via code
- Admin moderation (silent delete)
- Personal private feed
- Home screen widget
- Local notifications

**Out of scope**
- Real-time sync
- Push notifications
- Admin approval queue
- PDF/syllabus parsing
- Multi-admin roles

---

## Timeline Estimate

| Phase | Tasks | Duration |
|---|---|---|
| Setup | Firebase config, auth, project structure | 2 days |
| Core UI | Dashboard, cards, urgency logic | 3 days |
| Firestore | Class feed CRUD, join code logic | 3 days |
| Personal feed | Private event CRUD | 1 day |
| Notifications + Widget | local_notifications, home_widget | 2 days |
| Polish + Testing | Edge cases, UI cleanup | 2 days |

**Total — ~13 days**

---

## Team

| Role | Responsibility |
|---|---|
| Lead | Architecture, Firestore, Auth |
| UI Dev | Screens, widgets, theming |

*(Adjust based on actual team size)*
