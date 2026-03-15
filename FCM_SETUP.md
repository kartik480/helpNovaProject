# Firebase Cloud Messaging (FCM) Setup Guide

## ⚠️ DEPRECATED - This guide is for Legacy API

**This app now uses FCM V1 API (recommended).**  
Please see **[FCM_V1_SETUP.md](./FCM_V1_SETUP.md)** for the current setup instructions.

---

## Legacy API Setup (Deprecated)

The following instructions are for the Legacy API which is deprecated and will be removed on June 20, 2024.

## Required: Firebase Server Key

To send push notifications from the backend using Legacy API, you need to get your Firebase Server Key:

### Steps to Get Firebase Server Key:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **helpnovaproject**
3. Click on the **⚙️ Settings (gear icon)** in the top left
4. Select **Project settings**
5. Go to the **Cloud Messaging** tab
6. Under **Cloud Messaging API (Legacy)**, you'll find:
   - **Server key** (this is what you need)
   - **Sender ID**

### Setting the Server Key in Backend:

#### For Local Development:
1. Create or edit `.env` file in `helpnova_backend/` directory
2. Add the following line:
   ```
   FIREBASE_SERVER_KEY=your-server-key-here
   ```

#### For Production (Render.com):
1. Go to your Render.com dashboard
2. Select your backend service
3. Go to **Environment** tab
4. Add a new environment variable:
   - **Key**: `FIREBASE_SERVER_KEY`
   - **Value**: Your Firebase Server Key (from step 6 above)
5. Save and redeploy

## How It Works

1. **User location is updated** → When user opens the app, their location is automatically sent to backend
2. **User presses Emergency SOS** → Opens Emergency SOS screen
3. **User presses "Send Alert" button** → 
   - Finds nearby users (within **5km radius**) who have:
     - FCM tokens registered
     - Location sharing enabled
     - Valid location data in database
   - Calculates distance using Haversine formula
   - Sends push notifications to users within 5km
4. **Nearby users receive notification** → 
   - If app is in foreground: Shows popup dialog immediately
   - If app is in background: Shows notification in notification tray
   - If app is closed: Shows notification in notification tray
5. **User taps notification** → 
   - Opens emergency dialog with user details
   - User can accept or decline
   - If accepted: User appears in "Accepted Requests" list

## Important Notes

- **5km Radius**: Only users within 5 kilometers will receive notifications
- **Location Updates**: User location is automatically updated when they open the app
- **Location Required**: Users must have location sharing enabled and valid location data to receive notifications
- **Distance Calculation**: Uses Haversine formula for accurate distance calculation

## Testing

1. Make sure both devices have the app installed
2. Both users should be logged in
3. Both users should have location permissions enabled
4. Press Emergency SOS on one device
5. Press "Send Alert to Nearby Helpers"
6. The other device should receive a notification

## Troubleshooting

- **No notifications received**: 
  - Check if FIREBASE_SERVER_KEY is set correctly
  - Check if users have FCM tokens (check backend logs)
  - Check if users are within 10km radius
  - Check Firebase Console for notification delivery status

- **Notifications not showing dialog**:
  - Make sure app has notification permissions
  - Check if Firebase is properly initialized
  - Check console logs for errors

## Important Notes

- FCM tokens are automatically saved when users log in
- FCM tokens are refreshed automatically when they change
- Only users with `locationAllowed: true` will receive notifications
- Notifications are sent to all users with FCM tokens (within system)
- In production, you should filter by actual location distance
