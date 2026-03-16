# API Keys Quick Reference

## 📋 Where to Put Each API Key

### 1. Android API Key
**File:** `android/app/src/main/AndroidManifest.xml`  
**Line:** ~47  
**Replace:** `YOUR_ANDROID_API_KEY_HERE`

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY_HERE" />
```

**Restrictions:**
- Application: Android apps
- Package name: `com.example.helpnovaproject`
- SHA-1: Get from `keytool` or `gradlew signingReport`
- APIs: Maps SDK for Android

---

### 2. Web API Key
**File:** `web/index.html`  
**Line:** ~36  
**Replace:** `YOUR_WEB_API_KEY_HERE`

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY_HERE&libraries=places"></script>
```

**Restrictions:**
- Application: HTTP referrers (web sites)
- Referrers: 
  - `http://localhost:*/*`
  - `http://127.0.0.1:*/*`
  - `https://yourdomain.com/*` (production)
- APIs: Maps JavaScript API, Places API

---

### 3. Backend API Key
**File:** `lib/services/geocoding_service.dart`  
**Line:** ~6  
**Replace:** `YOUR_BACKEND_API_KEY_HERE`

```dart
static const String _apiKey = 'YOUR_BACKEND_API_KEY_HERE';
```

**Restrictions:**
- Application: IP addresses (web servers)
- IP: Your backend server IP (or `0.0.0.0/0` for dev - NOT recommended)
- APIs: Geocoding API, Places API, Distance Matrix API

---

## 🔑 How to Create Keys

1. Go to: https://console.cloud.google.com/
2. Select your project
3. Go to: **APIs & Services** → **Credentials**
4. Click: **"+ CREATE CREDENTIALS"** → **"API key"**
5. Name it appropriately (e.g., "HelpNova Android Key")
6. Click **"RESTRICT KEY"** and set restrictions
7. Copy the key and paste it in the file above

---

## ✅ Checklist

- [ ] Created Android API Key
- [ ] Added Android key to `AndroidManifest.xml`
- [ ] Added package name + SHA-1 to Android key restrictions
- [ ] Created Web API Key
- [ ] Added Web key to `web/index.html`
- [ ] Added HTTP referrers to Web key restrictions
- [ ] Created Backend API Key
- [ ] Added Backend key to `geocoding_service.dart`
- [ ] Added IP address to Backend key restrictions
- [ ] Enabled all required APIs in Google Cloud Console
- [ ] Tested Android app
- [ ] Tested Web app (`flutter run -d chrome`)
- [ ] Tested backend API calls

---

## 📚 Full Guide

See `MULTIPLE_API_KEYS_SETUP.md` for detailed step-by-step instructions.
