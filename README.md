# Bruno USDT Miner

A sleek and modern Flutter app for USDT mining with professional crypto design, smooth animations, and Google Firebase authentication.

![Flutter](https://img.shields.io/badge/Flutter-2.10-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Authentication-orange?logo=firebase)
![Dart](https://img.shields.io/badge/Dart-2.19-blue?logo=dart)

---

## Features

- 🎨 **Modern UI/UX**: Professional crypto-themed design with dark mode and smooth animations  
- 🔐 **Google Authentication**: Login using Firebase Auth  
- ⛏️ **Automatic Mining**: Continuous mining 24/7, even when the app is closed  
- 🚀 **Boost System**: Watch ads to double mining speed  
- 🎁 **Daily Rewards**: 2 reward cards with a limit of 10 clicks each  
- 💰 **Wallet**: Manage mining balance and referrals with withdrawal capability  
- 📊 **Leaderboard**: Top 10 users, top 3 highlighted  
- 🔗 **Referral System**: Share the app and earn 0.02 USDT per referral  

---

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
