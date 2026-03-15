# Firebase Cloud Messaging V1 API Setup Guide

## Overview
This app uses Firebase Cloud Messaging (FCM) **V1 API** to send push notifications. The V1 API is the recommended and modern approach, replacing the deprecated Legacy API.

## Required: Firebase Service Account JSON

To send push notifications from the backend using V1 API, you need a **Service Account JSON key**.

### Steps to Get Service Account JSON:

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/project/helpnovaproject/settings/serviceaccounts/adminsdk
   - Or: Firebase Console → Project Settings → Service Accounts tab

2. **Generate New Private Key**
   - Click on **"Generate new private key"** button
   - A dialog will appear warning you to keep the key secure
   - Click **"Generate key"**
   - A JSON file will be downloaded (e.g., `helpnovaproject-firebase-adminsdk-xxxxx.json`)

3. **Get the JSON Content**
   - Open the downloaded JSON file
   - Copy the **entire JSON content** (it should look like this):
   ```json
   {
     "type": "service_account",
     "project_id": "helpnovaproject",
     "private_key_id": "...",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "...",
     "client_id": "...",
     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
     "token_uri": "https://oauth2.googleapis.com/token",
     "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
     "client_x509_cert_url": "..."
   }
   ```

### Setting the Service Account in Backend:

#### For Local Development:
1. Create or edit `.env` file in `helpnova_backend/` directory
2. Add the following line (paste the entire JSON as a single line string):
   ```
   FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"helpnovaproject",...}
   ```
   **Important:** The entire JSON must be on one line, with all quotes properly escaped if needed.

#### For Production (Render.com):
1. Go to your Render.com dashboard
2. Select your backend service
3. Go to **Environment** tab
4. Add a new environment variable:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: Paste the entire JSON content (as a single line string)
5. Save and redeploy

**Alternative for Render.com (if single line is too long):**
You can also store it as a multi-line string, but make sure to:
- Remove all line breaks
- Escape quotes properly
- Or use Render's file upload feature if available

## Install Dependencies

Make sure to install the required package:

```bash
cd helpnova_backend
npm install google-auth-library
```

## How It Works

1. **User location is updated** → When user opens the app, their location is automatically sent to backend
2. **User presses Emergency SOS** → Opens Emergency SOS screen
3. **User presses "Send Alert" button** → 
   - Finds nearby users (within **5km radius**) who have:
     - FCM tokens registered
     - Location sharing enabled
     - Valid location data in database
   - Calculates distance using Haversine formula
   - Sends push notifications using **V1 API** to users within 5km
4. **Nearby users receive notification** → 
   - If app is in foreground: Shows popup dialog immediately
   - If app is in background: Shows notification in notification tray
   - If app is closed: Shows notification in notification tray
5. **User taps notification** → 
   - Opens emergency dialog with user details
   - User can accept or decline
   - If accepted: User appears in "Accepted Requests" list

## V1 API Benefits

✅ **Modern and Recommended**: Official Firebase recommendation  
✅ **Better Security**: Uses OAuth2 tokens instead of static keys  
✅ **More Features**: Supports advanced notification features  
✅ **Future-Proof**: Legacy API is deprecated and will be removed  

## Important Notes

- **5km Radius**: Only users within 5 kilometers will receive notifications
- **Location Updates**: User location is automatically updated when they open the app
- **Location Required**: Users must have location sharing enabled and valid location data to receive notifications
- **Distance Calculation**: Uses Haversine formula for accurate distance calculation
- **Service Account Security**: Keep the Service Account JSON secure and never commit it to version control

## Troubleshooting

- **"FIREBASE_SERVICE_ACCOUNT not set"**: 
  - Make sure you've added the environment variable
  - Check that the JSON is properly formatted (valid JSON)
  - For Render.com, ensure it's set as a single-line string

- **"Invalid FIREBASE_SERVICE_ACCOUNT JSON format"**:
  - Verify the JSON is valid
  - Make sure all quotes are properly escaped
  - Check that there are no line breaks in the environment variable

- **"Failed to obtain access token"**:
  - Verify the Service Account JSON is correct
  - Check that the service account has proper permissions
  - Ensure the project ID matches your Firebase project

- **No notifications received**: 
  - Check if users have FCM tokens (check backend logs)
  - Verify users are within 5km radius
  - Check Firebase Console for notification delivery status
  - Verify the Service Account has FCM permissions

## Security Best Practices

1. **Never commit** the Service Account JSON to Git
2. **Add to .gitignore**: Make sure `.env` and any JSON key files are in `.gitignore`
3. **Rotate keys**: Periodically regenerate Service Account keys
4. **Limit permissions**: Only grant necessary permissions to the Service Account
5. **Monitor usage**: Regularly check Firebase Console for unusual activity
