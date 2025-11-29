# Aurora Wellness Tracker

A comprehensive health and fitness tracking app built with Flutter and Firebase.

## Features

- 📊 Track daily health metrics (steps, calories, water, sleep)
- 💉 Blood pressure and blood sugar monitoring
- 🏆 Social competition with leaderboards and challenges
- 📈 Beautiful charts and analytics
- 🎯 Customizable health goals
- 🔔 Smart reminders and notifications
- 🤖 AI-powered health insights

## Firebase Setup

### Prerequisites

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

### Configuration

1. Login to Firebase:
```bash
firebase login
```

2. Configure your Flutter app:
```bash
cd c:\Users\58him\tracker
flutterfire configure
```

3. Select your Firebase project and platforms

### Database Setup

1. **Realtime Database**: Enable in Firebase Console with test mode rules
2. **Firestore**: Enable with test mode rules
3. **Authentication**: Enable Email/Password and Google sign-in

### Testing Connection

1. Run the app and navigate to Settings
2. Scroll to "Developer" section
3. Tap "Test Firebase Connection"
4. Verify all services show "Connected" ✅

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase (see above)
4. Run `flutter run`

## Dependencies

- `firebase_core`: ^2.24.2
- `firebase_auth`: ^4.16.0
- `firebase_database`: ^10.4.0
- `cloud_firestore`: ^4.14.0
- `google_sign_in`: ^6.2.1
- `fl_chart`: ^0.66.0
- `google_fonts`: ^6.1.0
- `provider`: ^6.1.1

## Social Features

### Leaderboard
Compete with friends based on daily health scores calculated from:
- Steps (30 points)
- Water intake (20 points)
- Calorie balance (25 points)
- Sleep hours (25 points)

### Challenges
Create custom challenges for:
- Daily step goals
- Water intake targets
- Calorie tracking
- Sleep consistency

## Troubleshooting

### "Sign in to create challenges"
- Make sure you're logged in
- Check Firebase connection using test button
- Verify user ID is set (visible in Settings > Developer)

### Leaderboard not updating
- Test Firebase Realtime Database connection
- Check database rules allow read/write
- Verify user is authenticated

### Challenges not showing
- Test Firestore connection
- Verify authentication is working
- Check Firestore rules

## License

MIT License - see LICENSE file for details
