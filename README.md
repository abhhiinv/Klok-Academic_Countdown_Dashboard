# Klok
### Academic Countdown Dashboard

**Klok** is a modern, responsive Flutter application designed for college students (specifically tailored for KTU engineering batches) to track upcoming academic deadlines — exams, project submissions, lab evaluations, and fests — through an intuitive, urgency-based countdown dashboard.

---

## Features

- **Urgency-Based Countdown Cards**: Real-time remaining time (days, hours, minutes) with visual traffic-light indicators:
  - 🔴 **Red (< 3 days)**: High urgency with subtle pulse animation.
  - 🟡 **Orange (< 7 days)**: Moderate urgency.
  - 🟢 **Green (14+ days)**: Safe / upcoming.
- **100% Offline Capable**: Use the app completely offline out-of-the-box. No mandatory accounts or logins required for personal countdowns.
- **Shared Class Groups (Online)**:
  - Create or join class groups via unique 6-character join codes.
  - Batch-wide event feeds where classmates can collaborate.
  - Creator/Admin moderation tools.
- **Private Personal Feed**: Maintain personal study schedules and individual tasks privately (stored locally or in user cloud).
- **Category Filtering**: Instant sorting across **All**, **Exams**, **Submissions**, and **Fests**.
- **Archive Feed**: Automatically categorizes past events with date-ordered history.
- **Milestone Notifications**: Local reminder alerts delivered 1 day and 3 hours before deadlines.
- **Modern Material 3 UI**: Clean typography (Inter font family), adaptive light and dark themes, and buttery-smooth animations.

---

## Tech Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter (Dart SDK `>=3.12.2`) |
| **Authentication** | Firebase Auth (Google Sign-In) |
| **Cloud Database** | Cloud Firestore |
| **Local Persistence** | `shared_preferences` |
| **Notifications** | `flutter_local_notifications` + `timezone` |
| **Home Widgets** | `home_widget` |
| **Architecture** | Service-oriented Flutter state architecture |

---

## 📁 Project Architecture

```
lib/
├── main.dart                   # Application bootstrap, theming & offline/online router
├── firebase_options.dart       # Dynamic Firebase options injected via dart-defines
├── models/
│   ├── event.dart              # Event model with urgency logic & serialization
│   └── class_group.dart        # Class group entity
├── services/
│   ├── auth_service.dart       # Google Sign-In & Firebase Auth
│   ├── firestore_service.dart  # Cloud Firestore read/write streams
│   ├── local_storage_service.dart # Local offline event storage & state
│   └── notification_service.dart # Scheduled local notification engine
├── screens/
│   ├── onboarding_screen.dart  # Welcome, sign-in, class setup & offline mode entry
│   ├── dashboard_screen.dart   # Main countdown dashboard (hybrid offline/online)
│   ├── add_event_screen.dart   # Event creation form with date-time picker
│   └── archive_screen.dart     # Past events view
├── widgets/
│   ├── event_card.dart         # Countdown card with isolated animation boundaries
│   ├── category_tab_bar.dart   # Category filter chips
│   └── urgency_badge.dart      # Urgency level indicator badge
└── utils/
    └── date_utils.dart         # Date formatting & urgency helpers
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.12.0 or higher)
- Android Studio / VS Code with Flutter extension
- A Firebase project (if using online class collaboration features)

### 1. Clone the repository
```bash
git clone https://github.com/abhhiinv/Klok-Academic_Countdown_Dashboard.git
cd Klok-Academic_Countdown_Dashboard
```

### 2. Environment Configuration
Create a `.env.json` file in the root directory (this file is excluded by `.gitignore`):

```json
{
  "PROJECT_ID": "your-firebase-project-id",
  "MESSAGING_SENDER_ID": "your-messaging-sender-id",
  "ANDROID_API_KEY": "your-android-api-key",
  "ANDROID_APP_ID": "your-android-app-id",
  "IOS_API_KEY": "your-ios-api-key",
  "IOS_APP_ID": "your-ios-app-id",
  "WEB_API_KEY": "your-web-api-key",
  "WEB_APP_ID": "your-web-app-id"
}
```

### 3. Run the Application

#### Option A - Terminal (Windows Batch Script)
```cmd
.\run.bat
```
*(You can pass additional flags like `.\run.bat -d chrome` or `.\run.bat -d <device-id>`)*

#### Option B - VS Code
Press **`F5`** or navigate to **Run and Debug** -> Select **Klok**.

#### Option C - Standard Flutter CLI
```bash
flutter run --dart-define-from-file=.env.json
```

---

## Security & Firestore Rules

To secure the cloud database, apply the following Firestore security rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📱 Google Sign-In Setup (Android)

If using Google Authentication for class groups on Android:
1. Generate your SHA-1 key:
   ```cmd
   cd android
   .\gradlew signingReport
   ```
2. Add the SHA-1 fingerprint to **Firebase Console** -> **Project Settings** -> **Your Android App**.
3. Set your **Support email** in Project Settings.
4. Download the updated `google-services.json` and place it in `android/app/`.

---

## License
This project is licensed under the MIT License - see the LICENSE file for details.
