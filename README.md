# Bruno USDT Miner

A sleek and modern Flutter app for USDT mining with professional crypto design, smooth animations, and Google Firebase authentication.

## Features

- 🎨 **Modern UI/UX**: Professional crypto design with dark theme and smooth animations
- 🔐 **Google Authentication**: Login with Firebase Auth
- ⛏️ **Automatic Mining**: Continuous mining 24/7 even when the app is closed
- 🚀 **Boost System**: Watch ads to double mining speed
- 🎁 **Daily Rewards**: 2 reward cards with a limit of 10 clicks each
- 💰 **Wallet**: Manage mining and referral balance with withdrawal option
- 📊 **Leaderboard**: Top 10 users with top 3 highlighted
- 🔗 **Referral System**: Share the app and earn 0.02 USDT per referral

## Firebase Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add an Android and/or iOS app

### 2. Configure Android

1. Download the `google-services.json` file
2. Place it in `android/app/`
3. Add the plugin in `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

3. Configure iOS

Download the GoogleService-Info.plist file

Add it to the Xcode project

Configure OAuth authentication in Firebase console

4. Enable Google Sign-In

Go to Authentication > Sign-in method

Enable "Google" as a sign-in provider

Add SHA-1 fingerprint for Android (optional but recommended)

Installation
flutter pub get
flutter run

Important Notes

Mining is configured to be very slow (0.00001 USDT/second)

Withdrawal requires a minimum of 100 USDT

Daily rewards have a limit of 10 clicks each

Boost mining lasts 1 hour and requires 2 ads

Rewards open in Chrome custom tabs

Project Structure
lib/
├── main.dart                 # Entry point
├── theme/
│   └── app_theme.dart       # Crypto theme
├── services/
│   ├── auth_service.dart    # Authentication service
│   ├── mining_service.dart  # Mining logic
│   └── storage_service.dart # Local storage
├── screens/
│   ├── intro_screen.dart    # Intro screen
│   ├── login_screen.dart    # Google login
│   ├── main_tabs.dart       # Main navigation
│   ├── home_screen.dart     # Home with mining card
│   ├── boost_screen.dart    # Boost mining
│   ├── wallet_screen.dart   # Wallet (mining + referral)
│   ├── withdraw_screen.dart # USDT withdrawal
│   ├── settings_screen.dart # Settings
│   └── leaderboard_screen.dart # Leaderboard
└── widgets/
    ├── mining_card.dart     # Mining card
    └── reward_card.dart     # Daily reward card

License

This project is for educational purposes only.

