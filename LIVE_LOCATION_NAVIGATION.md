# Live Location Tracking & Navigation Guide

## ✅ What's Implemented

### 1. **Live Location Tracking**
- **Update Frequency:** Every **15 seconds** (changed from 2 minutes)
- **Active Users Refresh:** Every **15 seconds** (changed from 30 seconds)
- **Backend Updates:** Location automatically sent to backend when user moves
- **Map Markers:** Green markers update in real-time as helpers move

### 2. **Auto-Fit Camera**
- Automatically zooms and pans to show **all helpers** on the map
- Includes: Your location + All active helpers + Emergency alerts
- Triggers when active users are loaded

### 3. **Navigation/Routing**
- **Tap any green helper marker** → Shows route from your location to theirs
- **Tap any red emergency marker** → Shows route + opens emergency dialog
- **Route Display:** Blue polyline on map showing the driving route
- **Clear Route:** X button appears when route is displayed

### 4. **Google Maps Integration**
- If route can't be calculated, opens destination in **Google Maps app**
- Uses `url_launcher` package to open external maps

---

## 🔧 API Requirements

### **You Need to Enable ONE More API:**

#### **Directions API** (for navigation/routing)

**Steps:**
1. Go to: https://console.cloud.google.com/
2. Select your project
3. Go to: **APIs & Services** → **Library**
4. Search for: **"Directions API"**
5. Click **"Enable"**

**That's it!** The same API key in `geocoding_service.dart` will work for Directions API.

---

## 📱 How It Works

### **Live Location Flow:**
```
1. User opens app → Location permission granted
2. App gets GPS location → Updates every 15 seconds
3. Location sent to backend → Backend stores it
4. Other users' apps fetch active users → Every 15 seconds
5. Map markers update → Green dots move in real-time
```

### **Navigation Flow:**
```
1. User taps helper marker (green) or emergency marker (red)
2. App calls Google Directions API → Gets route polyline
3. Route displayed as blue line on map
4. Camera auto-fits to show entire route
5. User can tap X button to clear route
```

---

## 🎯 Features

### ✅ **Live Tracking**
- ✅ Location updates every 15 seconds
- ✅ Backend receives live updates
- ✅ Other users see your location in real-time
- ✅ Markers move as users move

### ✅ **Navigation**
- ✅ Tap marker → See route
- ✅ Blue polyline shows driving directions
- ✅ Auto-zoom to fit route
- ✅ Clear route button
- ✅ Fallback to Google Maps app

### ✅ **Auto-Fit Camera**
- ✅ Shows all helpers automatically
- ✅ Includes emergency alerts
- ✅ Smart zoom level
- ✅ Padding for better view

---

## 🚀 Testing

### **Test Live Location:**
1. Open app on **Device A** → Enable location
2. Open app on **Device B** (different account) → Enable location
3. Move **Device A** → Watch marker move on **Device B** (within 15 seconds)

### **Test Navigation:**
1. Tap any **green helper marker** → Route appears
2. Tap **red emergency marker** → Route + dialog appears
3. Tap **X button** → Route clears

### **Test Auto-Fit:**
1. Enable location on multiple devices
2. Open map → Camera should auto-fit to show all markers
3. Move devices → Camera adjusts automatically

---

## ⚙️ Configuration

### **Change Update Frequency:**

**File:** `lib/home_screen.dart`

```dart
// Line ~329: Location update frequency
_locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), ...);

// Line ~422: Active users refresh frequency  
_activeUsersRefreshTimer = Timer.periodic(const Duration(seconds: 15), ...);
```

**Recommended:**
- **15 seconds** = Good balance (live tracking, not too battery-intensive)
- **5 seconds** = Very live (more battery usage)
- **30 seconds** = Less frequent (saves battery)

---

## 🔍 Troubleshooting

### **Markers Not Moving:**
- ✅ Check location permission is granted
- ✅ Check backend is receiving updates (check logs)
- ✅ Check `locationAllowed: true` in database
- ✅ Wait 15 seconds for refresh

### **Route Not Showing:**
- ✅ Check Directions API is enabled in Google Cloud Console
- ✅ Check API key has Directions API enabled
- ✅ Check internet connection
- ✅ Check coordinates are valid

### **Auto-Fit Not Working:**
- ✅ Check multiple markers exist
- ✅ Check `_loadActiveUsers()` is being called
- ✅ Check map controller is initialized

---

## 📝 Code Locations

### **Live Location:**
- `lib/home_screen.dart` → `_startPeriodicLocationUpdates()`
- `lib/home_screen.dart` → `_startActiveUsersRefresh()`
- `lib/services/api_service.dart` → `updateUserLocation()`

### **Navigation:**
- `lib/services/geocoding_service.dart` → `getRoute()`
- `lib/home_screen.dart` → `_showRouteToDestination()`
- `lib/home_screen.dart` → `_buildMapMarkers()` → `onTap`

### **Auto-Fit:**
- `lib/home_screen.dart` → `_fitMapToShowAllMarkers()`
- `lib/home_screen.dart` → `_loadActiveUsers()` → calls `_fitMapToShowAllMarkers()`

---

## 🎉 Summary

**You now have:**
- ✅ Live location tracking (15-second updates)
- ✅ Real-time helper markers
- ✅ Navigation/routing with route display
- ✅ Auto-fit camera to show all helpers
- ✅ Google Maps fallback

**Just enable Directions API and you're done!** 🚀
