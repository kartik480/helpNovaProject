# Multiple Google Maps API Keys Setup Guide

This guide will help you create **3 separate API keys** for better security and organization:
1. **Android API Key** - For Android app maps
2. **Web API Key** - For web/Chrome debug maps
3. **Backend API Key** - For server-side API calls (Distance Matrix, Geocoding, Places)

---

## Step 1: Create API Keys in Google Cloud Console

### Go to Google Cloud Console
1. Visit: https://console.cloud.google.com/
2. Select your project (or create a new one)
3. Go to **APIs & Services** → **Credentials**

### Create Key #1: Android API Key
1. Click **"+ CREATE CREDENTIALS"** → **"API key"**
2. Name it: `HelpNova Android Key`
3. Copy the key (starts with `AIzaSy...`)
4. Click **"RESTRICT KEY"**:
   - **Application restrictions**: Select **"Android apps"**
   - Click **"+ ADD AN ITEM"**
   - **Package name**: `com.example.helpnovaproject` (or your actual package name)
   - **SHA-1 certificate fingerprint**: Get from your keystore (see below)
   - **API restrictions**: Select **"Restrict key"**
   - Enable these APIs:
     - ✅ Maps SDK for Android
   - Click **"SAVE"**

### Create Key #2: Web API Key
1. Click **"+ CREATE CREDENTIALS"** → **"API key"**
2. Name it: `HelpNova Web Key`
3. Copy the key
4. Click **"RESTRICT KEY"**:
   - **Application restrictions**: Select **"HTTP referrers (web sites)"**
   - Click **"+ ADD AN ITEM"**
   - Add these referrers:
     - `http://localhost:*/*`
     - `http://127.0.0.1:*/*`
     - `https://yourdomain.com/*` (if you have a production domain)
   - **API restrictions**: Select **"Restrict key"**
   - Enable these APIs:
     - ✅ Maps JavaScript API
     - ✅ Places API
   - Click **"SAVE"**

### Create Key #3: Backend API Key
1. Click **"+ CREATE CREDENTIALS"** → **"API key"**
2. Name it: `HelpNova Backend Key`
3. Copy the key
4. Click **"RESTRICT KEY"**:
   - **Application restrictions**: Select **"IP addresses (web servers)"**
   - Click **"+ ADD AN ITEM"**
   - Add your backend server IP (or `0.0.0.0/0` for development - **NOT recommended for production**)
   - **API restrictions**: Select **"Restrict key"**
   - Enable these APIs:
     - ✅ Geocoding API
     - ✅ Places API
     - ✅ Distance Matrix API
   - Click **"SAVE"**

---

## Step 2: Get SHA-1 Fingerprint (For Android Key)

### For Debug Build:
```bash
# Windows (PowerShell)
cd android
.\gradlew signingReport

# Look for SHA1 in the output under "Variant: debug"
```

### For Release Build:
```bash
# If you have a keystore file
keytool -list -v -keystore android/app/keystore.jks -alias your-alias
```

Copy the SHA-1 fingerprint (looks like: `AA:BB:CC:DD:EE:FF:...`)

---

## Step 3: Enable Required APIs

Make sure these APIs are enabled in your Google Cloud project:
1. Go to **APIs & Services** → **Library**
2. Search and enable:
   - ✅ Maps SDK for Android
   - ✅ Maps JavaScript API
   - ✅ Geocoding API
   - ✅ Places API
   - ✅ Distance Matrix API

---

## Step 4: Update Your Project Files

### File 1: `android/app/src/main/AndroidManifest.xml`
Replace the API key with your **Android API Key**:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY_HERE" />
```

### File 2: `web/index.html`
Replace the API key with your **Web API Key**:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY_HERE&libraries=places"></script>
```

### File 3: `lib/services/geocoding_service.dart`
Replace the API key with your **Backend API Key**:
```dart
static const String _apiKey = 'YOUR_BACKEND_API_KEY_HERE';
```

---

## Step 5: Update Backend (If Applicable)

If your backend makes direct API calls to Google Maps APIs, update it to use the **Backend API Key**.

---

## Security Best Practices

✅ **DO:**
- Use separate keys for each platform
- Restrict keys to specific APIs
- Use IP restrictions for backend keys
- Use package name restrictions for Android keys
- Use HTTP referrer restrictions for web keys
- Rotate keys if compromised

❌ **DON'T:**
- Use unrestricted keys in production
- Commit keys to public repositories
- Share keys between different platforms
- Use the same key for everything

---

## Testing

After updating all keys:

1. **Test Android**: Build and run on Android device/emulator
2. **Test Web**: Run `flutter run -d chrome` and check browser console
3. **Test Backend**: Make a test API call from your backend

---

## Troubleshooting

### "This API key is not authorized"
- Check API restrictions in Google Cloud Console
- Ensure correct APIs are enabled
- Verify restrictions match your app/domain/IP

### "RefererNotAllowedMapError" (Web)
- Add your domain to HTTP referrer restrictions
- Include `http://localhost:*` for local development

### "Android app not authorized" (Android)
- Verify package name matches exactly
- Check SHA-1 fingerprint is correct
- Ensure Maps SDK for Android is enabled

---

## Quick Reference

| Platform | Key Type | Used In | APIs Needed |
|----------|----------|---------|-------------|
| Android | Android Key | `AndroidManifest.xml` | Maps SDK for Android |
| Web | Web Key | `web/index.html` | Maps JavaScript API, Places API |
| Backend | Backend Key | `geocoding_service.dart` | Geocoding API, Places API, Distance Matrix API |

---

## Next Steps

1. ✅ Create 3 API keys in Google Cloud Console
2. ✅ Get SHA-1 fingerprint for Android key
3. ✅ Enable all required APIs
4. ✅ Update `AndroidManifest.xml` with Android key
5. ✅ Update `web/index.html` with Web key
6. ✅ Update `geocoding_service.dart` with Backend key
7. ✅ Test on all platforms
