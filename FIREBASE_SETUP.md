# Firebase Setup Guide for Help Nova

This guide will help you set up Firebase for your Help Nova Flutter app.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Android Studio / Xcode (for platform-specific setup)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Enter project name: `helpnovaproject` (or your preferred name)
4. Follow the setup wizard:
   - Disable Google Analytics (optional, you can enable later)
   - Click "Create project"

## Step 2: Add Android App

1. In Firebase Console, click the Android icon (or "Add app" > Android)
2. Enter package name: `com.example.helpnovaproject` (check your `android/app/build.gradle` for the actual package name)
3. Enter app nickname (optional): "Help Nova Android"
4. Enter SHA-1 (optional for now, needed for Google Sign-In later)
5. Click "Register app"
6. Download `google-services.json`
7. Place the file in: `android/app/google-services.json`

## Step 3: Add iOS App (if developing for iOS)

1. In Firebase Console, click the iOS icon (or "Add app" > iOS)
2. Enter bundle ID: `com.example.helpnovaproject` (check your `ios/Runner/Info.plist` for the actual bundle ID)
3. Enter app nickname (optional): "Help Nova iOS"
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Place the file in: `ios/Runner/GoogleService-Info.plist`
7. Open `ios/Runner.xcworkspace` in Xcode
8. Right-click `Runner` folder > "Add Files to Runner"
9. Select `GoogleService-Info.plist` and ensure "Copy items if needed" is checked

## Step 4: Configure Android Build Files

1. Open `android/build.gradle` (project-level)
2. Add to the `dependencies` section:
   ```gradle
   classpath 'com.google.gms:google-services:4.4.0'
   ```

3. Open `android/app/build.gradle`
4. Add at the top (after other plugins):
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

## Step 5: Update Firebase Options

### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run configuration:
   ```bash
   flutterfire configure
   ```

3. Follow the prompts:
   - Select your Firebase project
   - Select platforms (Android, iOS, Web)
   - The CLI will automatically update `lib/firebase_options.dart`

### Option B: Manual Configuration

1. Open `lib/firebase_options.dart`
2. Go to Firebase Console > Project Settings > General
3. Scroll to "Your apps" section
4. Copy the configuration values for each platform
5. Replace the placeholder values in `firebase_options.dart`:
   - `YOUR_WEB_API_KEY` → Your Web API Key
   - `YOUR_ANDROID_API_KEY` → Your Android API Key
   - `YOUR_IOS_API_KEY` → Your iOS API Key
   - `YOUR_APP_ID` → Your App ID
   - `YOUR_MESSAGING_SENDER_ID` → Your Messaging Sender ID
   - Update `projectId` if different
   - Update `storageBucket` if different

## Step 6: Enable Firebase Services

### Cloud Messaging (FCM) - For Push Notifications

1. In Firebase Console, go to "Cloud Messaging"
2. Enable Cloud Messaging API (if not already enabled)
3. For Android, you may need to set up a server key (for backend notifications)

### Firebase Analytics (Optional)

1. In Firebase Console, go to "Analytics"
2. Enable Google Analytics if you want usage analytics

## Step 7: Test Firebase Connection

1. Run the app:
   ```bash
   flutter run
   ```

2. Check the console for Firebase initialization messages
3. If you see "Firebase initialization error", check:
   - `google-services.json` is in the correct location
   - `firebase_options.dart` has correct values
   - Build files are properly configured

## Step 8: Verify Setup

1. In Firebase Console, go to "Project Settings" > "General"
2. Check that your apps are listed under "Your apps"
3. The app should appear in Firebase Console after first run

## Troubleshooting

### Android Issues

- **Error: "google-services.json not found"**
  - Ensure `google-services.json` is in `android/app/` directory
  - Clean and rebuild: `flutter clean && flutter pub get && flutter run`

- **Error: "Default FirebaseApp is not initialized"**
  - Check that `Firebase.initializeApp()` is called in `main.dart`
  - Ensure `firebase_options.dart` has correct values

### iOS Issues

- **Error: "GoogleService-Info.plist not found"**
  - Ensure the file is added to Xcode project
  - Check that it's included in the target membership

- **Build errors**
  - Run `pod install` in `ios/` directory
  - Clean build: `flutter clean && flutter pub get`

### General Issues

- **Firebase not connecting**
  - Check internet connection
  - Verify API keys are correct
  - Check Firebase project is active
  - Review console logs for specific errors

## Next Steps

After Firebase is set up, you can:

1. **Implement Push Notifications**
   - Use `firebase_messaging` package
   - Set up notification handlers
   - Configure backend to send notifications

2. **Add Authentication**
   - Use `firebase_auth` package
   - Implement email/password, Google Sign-In, etc.

3. **Use Cloud Firestore**
   - Use `cloud_firestore` package
   - Store and sync data in real-time

4. **Use Cloud Storage**
   - Use `firebase_storage` package
   - Upload and download files

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Review Flutter console logs
3. Verify all configuration files are in place
4. Ensure all dependencies are installed (`flutter pub get`)
