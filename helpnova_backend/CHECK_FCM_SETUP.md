# How to Check Firebase Service Account Configuration

## Quick Check Methods

### Method 1: Test API Endpoint (Easiest)

1. **Start your backend server**
2. **Make a GET request** to test the configuration:
   ```bash
   # Using curl
   curl -X GET http://localhost:5000/api/emergency/test-fcm-config \
     -H "Authorization: Bearer YOUR_AUTH_TOKEN"
   
   # Or open in browser (if you're logged in via the app)
   # The endpoint will check everything automatically
   ```

3. **Response will tell you:**
   - ✅ If FIREBASE_SERVICE_ACCOUNT is set
   - ✅ If the JSON is valid
   - ✅ If the credentials work (can get access token)
   - ❌ Any errors with detailed messages

### Method 2: Check Environment Variable Directly

**For Local Development:**
1. Go to `helpnova_backend/` folder
2. Check if `.env` file exists
3. Open `.env` file and look for:
   ```
   FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
   ```

**For Production (Render.com):**
1. Go to Render.com dashboard
2. Select your backend service
3. Go to **Environment** tab
4. Look for `FIREBASE_SERVICE_ACCOUNT` variable
5. Check if it's set (should show "Set" or the value)

### Method 3: Check Backend Logs

When you send an emergency alert, check the backend console logs:
- ✅ If you see: `📤 Sending notifications to X users...` → FCM is working
- ❌ If you see: `FIREBASE_SERVICE_ACCOUNT not set` → Not configured
- ❌ If you see: `Error getting access token` → Invalid credentials

## How to Get Firebase Service Account JSON

### Step-by-Step:

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Service Accounts:**
   - Click the ⚙️ (gear icon) → **Project Settings**
   - Go to **Service Accounts** tab

3. **Generate Private Key:**
   - Click **"Generate new private key"** button
   - A JSON file will download (e.g., `your-project-firebase-adminsdk-xxxxx.json`)

4. **Save the JSON:**
   - The file contains your service account credentials
   - **DO NOT** share this file publicly
   - **DO NOT** commit it to Git

## How to Set It Up

### Option A: Using the Setup Script (Recommended)

1. **Save the downloaded JSON:**
   ```bash
   # Copy the downloaded JSON file to:
   helpnova_backend/service-account.json
   ```

2. **Run the setup script:**
   ```bash
   cd helpnova_backend
   node setup-env.js
   ```

3. **Done!** The script will automatically add it to `.env`

### Option B: Manual Setup

1. **Open the downloaded JSON file** in a text editor

2. **Copy the entire JSON content**

3. **Create or edit `.env` file** in `helpnova_backend/` folder:
   ```
   FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"your-project-id",...}
   ```
   ⚠️ **Important:** The entire JSON must be on **ONE LINE** with no line breaks!

4. **Save the file**

### Option C: For Render.com (Production)

1. **Copy the entire JSON** from the downloaded file

2. **Go to Render.com:**
   - Dashboard → Your backend service → **Environment** tab

3. **Add Environment Variable:**
   - **Key:** `FIREBASE_SERVICE_ACCOUNT`
   - **Value:** Paste the entire JSON (as one line)
   - Click **Save Changes**

4. **Redeploy** your service

## Verify It's Working

After setting up, test it:

1. **Restart your backend server**

2. **Send a test emergency alert** from the app

3. **Check the logs:**
   - Should see: `✅ Notification sent successfully to [user name]`
   - Should NOT see: `FIREBASE_SERVICE_ACCOUNT not set`

4. **Or use the test endpoint:**
   ```bash
   GET /api/emergency/test-fcm-config
   ```

## Common Issues

### Issue 1: "FIREBASE_SERVICE_ACCOUNT not set"
**Solution:** Add it to `.env` file or Render.com environment variables

### Issue 2: "Invalid FIREBASE_SERVICE_ACCOUNT JSON format"
**Solution:** Make sure the JSON is on one line with no line breaks

### Issue 3: "Failed to obtain access token"
**Solution:** 
- Check if the service account JSON is correct
- Make sure you downloaded the right file from Firebase
- Verify the project ID matches your Firebase project

### Issue 4: "Error sending FCM notification"
**Solution:**
- Check if Cloud Messaging API is enabled in Google Cloud Console
- Verify the service account has proper permissions

## Security Reminder ⚠️

- ✅ `.env` is in `.gitignore` (won't be committed)
- ✅ `service-account.json` is in `.gitignore` (won't be committed)
- ❌ **NEVER** commit these files to Git
- ❌ **NEVER** share these credentials publicly
- ❌ **NEVER** post them in chat or forums
