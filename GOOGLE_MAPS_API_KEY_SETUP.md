# How to Get a Google Maps API Key

## Step-by-Step Guide

### Step 1: Go to Google Cloud Console

1. Visit: **https://console.cloud.google.com/**
2. **Sign in** with your Google account
3. **Select your project** (or create a new one)

### Step 2: Enable Required APIs

1. Go to **APIs & Services** → **Library**
2. Search and **Enable** these APIs:
   - ✅ **Maps SDK for Android**
   - ✅ **Maps SDK for iOS** (if you plan to support iOS)
   - ✅ **Geocoding API** (for converting coordinates to addresses)
   - ✅ **Places API** (optional, for future features)

### Step 3: Create API Key

1. Go to **APIs & Services** → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **"API key"**
3. A new API key will be created
4. **Copy the API key** (it will look like: `AIzaSy...`)

### Step 4: Restrict the API Key (Important for Security)

1. Click on the newly created API key to edit it
2. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Choose these APIs:
     - Maps SDK for Android
     - Maps SDK for iOS
     - Geocoding API
3. Under **"Application restrictions"**:
   - For Android: Select **"Android apps"**
     - Click **"Add an item"**
     - Enter your **Package name**: `com.example.helpnovaproject`
     - Enter your **SHA-1 certificate fingerprint** (get it using the command below)
   - For iOS: Select **"iOS apps"** (if needed)
     - Enter your **Bundle ID**
4. Click **"SAVE"**

### Step 5: Get SHA-1 Certificate Fingerprint (For Android)

Run this command in your terminal:

**For Debug (Development):**
```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 value under `Variant: debug` → `SHA1:`

**Or use keytool:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the **SHA-1** value (it looks like: `AA:BB:CC:DD:...`)

### Step 6: Update the API Key in Your Project

After getting your new API key, update it in these files:

#### File 1: `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_NEW_API_KEY_HERE" />
```

#### File 2: `lib/services/geocoding_service.dart`
```dart
static const String _apiKey = 'YOUR_NEW_API_KEY_HERE';
```

### Step 7: For iOS (if needed)

If you plan to support iOS, also add it to:
- `ios/Runner/AppDelegate.swift` or
- `ios/Runner/Info.plist`

---

## Quick Checklist

- [ ] Created Google Cloud Project
- [ ] Enabled Maps SDK for Android
- [ ] Enabled Geocoding API
- [ ] Created API Key
- [ ] Restricted API Key to required APIs
- [ ] Added Android app restrictions (Package name + SHA-1)
- [ ] Updated API key in `AndroidManifest.xml`
- [ ] Updated API key in `geocoding_service.dart`
- [ ] Tested the app (maps should load)

---

## Important Notes

1. **Billing**: Google Maps API requires a billing account, but they give $200 free credit per month
2. **Quotas**: Free tier includes:
   - 28,000 map loads per month
   - 40,000 geocoding requests per month
3. **Security**: Always restrict your API keys to prevent unauthorized use
4. **Testing**: Test with the new key before deploying to production

---

## Need Help?

If you encounter issues:
- Check Google Cloud Console → APIs & Services → Credentials for any errors
- Verify the APIs are enabled
- Check the API key restrictions match your app's package name
- Review the Google Maps Platform documentation: https://developers.google.com/maps/documentation
