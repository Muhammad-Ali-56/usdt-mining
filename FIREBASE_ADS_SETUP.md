# Firebase Remote Config for AdMob - Setup Guide

This guide explains how to configure AdMob Ad IDs and App ID through Firebase Remote Config.

## 📋 Firebase Console Configuration

### 1. Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **usdtmining-35ad7**

### 2. Navigate to Remote Config
1. In the left sidebar, click on **"Remote Config"** (under "Build")
2. If you don't have parameters yet, click **"Add parameter"**

### 3. Add Ad ID Parameters

**⚠️ IMPORTANT**: The App ID MUST be hardcoded in `AndroidManifest.xml` (Android) and `Info.plist` (iOS). Firebase Remote Config is used ONLY for Ad Unit IDs, not for the App ID.

Add the following parameters (Ad Unit IDs only):

#### Ad Unit IDs (for different ad types):
```
Parameter: admob_banner_id
Type: String
Default value: ca-app-pub-3940256099942544/6300978111
```

```
Parameter: admob_native_id
Type: String
Default value: ca-app-pub-3940256099942544/2247696110
```

```
Parameter: admob_interstitial_id
Type: String
Default value: ca-app-pub-3940256099942544/1033173712
```

```
Parameter: admob_rewarded_id
Type: String
Default value: ca-app-pub-3940256099942544/5224354917
```

### 4. Use Your Real IDs from AdMob

**App ID** (MUST be in AndroidManifest.xml and Info.plist - NOT in Remote Config):
- Find it in AdMob → App → Select your app → App settings
  - Android format: `ca-app-pub-XXXXXXXXXX~YYYYYYYYYY`
  - iOS format: `ca-app-pub-XXXXXXXXXX~ZZZZZZZZZZ`
- **Update manually** in `AndroidManifest.xml` and `Info.plist` (see sections below)

**Ad Unit IDs** (These go in Firebase Remote Config):
- Find them in AdMob → App → Select your app → Ad units
  - Banner: `ca-app-pub-XXXXXXXXXX/1234567890`
  - Native: `ca-app-pub-XXXXXXXXXX/0987654321`
  - Interstitial: `ca-app-pub-XXXXXXXXXX/1122334455`
  - Rewarded: `ca-app-pub-XXXXXXXXXX/5544332211`

### 5. Publish Changes
After adding all parameters:
1. Click **"Publish changes"**
2. Changes will be applied within a few minutes

## 🔧 Android Configuration

### ⚠️ CRITICAL: App ID Must Be in AndroidManifest.xml

**The App ID CANNOT be loaded from Firebase Remote Config.** It MUST be hardcoded in `AndroidManifest.xml` because:
- MobileAds SDK requires the App ID at initialization time
- The manifest is read before the app code runs
- Remote Config is loaded after app initialization

### 1. Update AndroidManifest.xml

The file `android/app/src/main/AndroidManifest.xml` currently contains:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713" />
```

**Replace with your real App ID from AdMob:**

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXX~YYYYYYYYYY" />
```

**Where to find your App ID:**
1. Go to [AdMob Console](https://apps.admob.com/)
2. Select your app → App settings
3. Copy the Android App ID (format: `ca-app-pub-XXXXXXXXXX~YYYYYYYYYY`)
4. Paste it in AndroidManifest.xml

## 🍎 iOS Configuration

### ⚠️ CRITICAL: App ID Must Be in Info.plist

**The App ID CANNOT be loaded from Firebase Remote Config.** It MUST be hardcoded in `Info.plist` because:
- MobileAds SDK requires the App ID at initialization time
- Info.plist is read before the app code runs
- Remote Config is loaded after app initialization

### 1. Update Info.plist

The file `ios/Runner/Info.plist` must contain:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

**Replace with your real iOS App ID:**

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXX~ZZZZZZZZZZ</string>
```

**Where to find your App ID:**
1. Go to [AdMob Console](https://apps.admob.com/)
2. Select your app → App settings
3. Copy the iOS App ID (format: `ca-app-pub-XXXXXXXXXX~ZZZZZZZZZZ`)
4. Paste it in Info.plist

## 📱 How It Works in the Code

### Loading Flow:

1. **On app startup** (`AdService.initialize()`):
   - Loads Firebase Remote Config
   - Reads Ad IDs from Remote Config
   - If Remote Config is not available, uses default values (test IDs)

2. **Values read from Remote Config** (Ad Unit IDs only):
   - `admob_banner_id` - Banner Ad Unit ID
   - `admob_native_id` - Native Ad Unit ID
   - `admob_interstitial_id` - Interstitial Ad Unit ID
   - `admob_rewarded_id` - Rewarded Ad Unit ID
   
   **Note**: App ID is NOT read from Remote Config. It must be in AndroidManifest.xml (Android) and Info.plist (iOS).

3. **Fallback**:
   - If a value in Remote Config is empty, uses the default value (test ID)
   - This ensures the app works even if Remote Config is not configured

## ✅ Benefits of Using Firebase Remote Config

1. **Updates without publishing new version**: You can change **Ad Unit IDs** without updating the app
2. **A/B Testing**: You can test different Ad Unit IDs for different users
3. **Centralized configuration**: All Ad Unit IDs in one place
4. **Quick rollback**: If there's a problem, you can revert to old values instantly

**Note**: The App ID still requires an app update (must be in manifest/Info.plist), but Ad Unit IDs can be changed remotely.

## 🔍 Verify Configuration

### Test in app:

1. Launch the app in debug mode
2. Check logs to see which Ad IDs are loaded:
   ```dart
   debugPrint('Banner ID: ${adService.bannerUnitId}');
   debugPrint('Rewarded ID: ${adService.rewardedUnitId}');
   ```

### Verify Remote Config:

1. Firebase Console → Remote Config
2. Check that all parameters are published
3. Verify that values are correct

## 📝 Important Notes

- **App ID MUST be in manifest/Info.plist**: The App ID cannot be loaded from Remote Config. It must be hardcoded in `AndroidManifest.xml` (Android) and `Info.plist` (iOS) because MobileAds SDK needs it at initialization time, before Remote Config is loaded.

- **Ad Unit IDs can be in Remote Config**: Only Ad Unit IDs (banner, native, interstitial, rewarded) can be loaded from Firebase Remote Config.

- **Test IDs**: The IDs `ca-app-pub-3940256099942544~...` are Google's test IDs. Use them only during development.

- **Production IDs**: Replace with your real IDs before publishing.

- **Cache**: Remote Config has a 1-hour cache (`minimumFetchInterval`). You can reduce it for testing.

## 🚀 Complete Configuration Example

### Firebase Remote Config (Ad Unit IDs only):
```
admob_banner_id: ca-app-pub-1234567890123456/1111111111
admob_native_id: ca-app-pub-1234567890123456/2222222222
admob_interstitial_id: ca-app-pub-1234567890123456/3333333333
admob_rewarded_id: ca-app-pub-1234567890123456/4444444444
```

**Note**: App IDs are NOT in Remote Config - they must be in AndroidManifest.xml and Info.plist.

### AndroidManifest.xml:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-1234567890123456~7890123456" />
```

### Info.plist:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-1234567890123456~3456789012</string>
```

## ❓ Frequently Asked Questions

**Q: Do I need to update both AndroidManifest/Info.plist and Remote Config?**
A: Yes, but for different things:
- **App ID**: MUST be in AndroidManifest.xml (Android) and Info.plist (iOS) - CANNOT be in Remote Config
- **Ad Unit IDs**: Can be in Firebase Remote Config (recommended) or hardcoded

**Q: Can I put the App ID in Remote Config?**
A: **NO**. The App ID MUST be hardcoded in AndroidManifest.xml (Android) and Info.plist (iOS) because:
- MobileAds SDK requires it at initialization time (before app code runs)
- Remote Config is loaded after app initialization
- The manifest/Info.plist are read by the OS before your app code executes

**Q: Can I use only Remote Config for Ad Unit IDs?**
A: Yes! Ad Unit IDs can be loaded from Firebase Remote Config. This is recommended because you can change them without updating the app.

**Q: How do I change Ad IDs after publishing?**
A: Update the values in Firebase Remote Config and publish. Users will receive the new values within 1 hour (cache time).

**Q: Will test IDs work in production?**
A: No, test IDs only work during development. You must use your real IDs in production.
