# Fix Chrome Debug Location Issues

If Chrome debug is showing a wrong location, follow these steps:

## 1. Disable Chrome DevTools Location Override

Chrome DevTools can override your location. To fix this:

1. **Open Chrome DevTools** (F12 or Right-click → Inspect)
2. **Click the three dots (⋮)** in the top-right corner of DevTools
3. **Go to "More tools" → "Sensors"**
4. **In the "Location" section:**
   - **Uncheck "Override geolocation"** if it's checked
   - Or select **"No override"** from the dropdown
   - Make sure no custom coordinates are set

## 2. Clear Chrome Location Cache

Chrome might be using cached location data:

1. **Open Chrome Settings** (chrome://settings/)
2. **Go to "Privacy and security" → "Site Settings"**
3. **Click "Location"**
4. **Find your app's URL** (usually `localhost:XXXXX` or your domain)
5. **Click the trash icon** to remove it
6. **Refresh the page** and allow location access again

## 3. Allow Location Permission

Make sure Chrome has permission to access your location:

1. **Click the lock icon** in the address bar
2. **Set "Location" to "Allow"**
3. **Refresh the page**

## 4. Use HTTPS (if possible)

For more accurate location on web:
- Location accuracy is better on HTTPS connections
- If testing locally, use `flutter run -d chrome --web-port=8080` with HTTPS enabled

## 5. Check Browser Location Settings

1. **Chrome Settings** → **Privacy and security** → **Site Settings** → **Location**
2. Make sure **"Ask before accessing"** is enabled
3. Make sure your site is **not blocked**

## 6. Test Location Accuracy

After making these changes:
1. **Close and reopen Chrome**
2. **Clear browser cache** (Ctrl+Shift+Delete)
3. **Run the app again** (`flutter run -d chrome`)
4. **Allow location access** when prompted
5. The app should now show your **actual current location**

## Code Changes Made

The code has been updated to:
- **Force fresh location** instead of using cached data (`timeLimit` parameter)
- **Use highest accuracy** for web platform
- **Request location with shorter timeout** on web for better responsiveness

## Still Having Issues?

If location is still wrong:
1. Check your **system location settings** (Windows Location Services)
2. Make sure **GPS/Location Services** are enabled on your computer
3. Try opening **Google Maps** in Chrome to verify Chrome can get your location
4. Check if other websites can access your location correctly
