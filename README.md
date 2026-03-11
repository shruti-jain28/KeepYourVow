# KeepYourVow

<p align="center">
  <img src="web/favicon.png" alt="KeepYourVow Logo" width="120" />
</p>

<p align="center">
  A habit-tracking Android app that helps you build commitment through identity-driven goals and daily habits.
</p>

---

## About

KeepYourVow encourages you to make vows — identity-driven commitments like _"I am becoming someone who exercises daily"_ — and track daily habits to stay accountable. Complete your habits, build streaks, and celebrate your progress.

## Features

- **Goals (Vows)** — Create identity-driven commitments with end dates. Track days remaining and attach multiple habits to each goal.
- **Habits** — Create habits with configurable frequencies (Daily, Weekly, Monthly, Weekdays, Weekends) and scheduled start times.
- **Daily Dashboard** — View today's completion progress, top goals as clickable tiles, and a sticky "Today's Plan" checklist.
- **Streaks** — Automatic current and longest streak tracking for each habit.
- **Celebrations** — Confetti animation and sound when all daily habits are completed.
- **Notifications** — Daily reminders to keep you on track.
- **Google Sign-In** — Firebase authentication with option to skip and use as guest.

## Screenshots

<!-- Add screenshots here -->

## Tech Stack

| Category         | Libraries                                    |
| ---------------- | -------------------------------------------- |
| Framework        | Flutter (Dart 3.2+)                          |
| State Management | flutter_riverpod                             |
| Database         | sqflite (SQLite)                             |
| Navigation       | go_router                                    |
| Auth             | firebase_auth, google_sign_in                |
| Notifications    | flutter_local_notifications, workmanager     |
| UI               | google_fonts (Plus Jakarta Sans), Material 3 |

## Project Structure

```
lib/
├── main.dart                          # App initialization
├── app.dart                           # GoRouter with 10 routes
├── features/
│   ├── today/                         # Dashboard, notifications
│   ├── goals/                         # Goal CRUD, detail screens
│   ├── habits/                        # Habit CRUD, streaks, detail screens
│   ├── onboarding/                    # 3-slide onboarding flow
│   ├── auth/                          # Firebase/Google sign-in
│   └── analytics/                     # Analytics (placeholder)
└── shared/
    ├── isar/isar_service.dart         # SQLite database wrapper
    ├── theme/app_theme.dart           # Colors, text styles, theme
    ├── widgets/                       # Reusable UI components
    └── copy.dart                      # Centralized app strings
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.2.0)
- Android Studio or VS Code with Flutter extension
- An Android device or emulator

### Clone & Run

```bash
# Clone the repository
git clone https://github.com/<your-username>/keepyourvow.git
cd keepyourvow

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup

This app uses Firebase for authentication. To run it locally:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with your package name
3. Download `google-services.json` and place it in `android/app/`
4. Enable **Google Sign-In** in Firebase Console > Authentication > Sign-in method
