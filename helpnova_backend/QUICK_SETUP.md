# Quick Setup Guide for Firebase Service Account

## Option 1: Using the Helper Script (Recommended)

1. **Save your Service Account JSON:**
   - Create a file named `service-account.json` in the `helpnova_backend/` folder
   - Paste your entire Service Account JSON into that file
   - Save it

2. **Run the setup script:**
   ```bash
   cd helpnova_backend
   node setup-env.js
   ```

3. **Done!** The script will automatically format and add it to your `.env` file.

## Option 2: Manual Setup

1. **Create or edit `.env` file** in `helpnova_backend/` directory

2. **Add this line** (paste your entire JSON as a single-line string):
   ```
   FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"your-project-id","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"...","universe_domain":"googleapis.com"}
   ```
   
   **Note:** Replace the placeholder values (`...`) with your actual service account JSON values from Firebase Console.

3. **Important:** Make sure the entire JSON is on **one line** with no line breaks.

## For Render.com (Production)

1. Go to Render.com dashboard → Your backend service → **Environment** tab
2. Add new environment variable:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: Paste your entire JSON (as a single-line string, same as above)
3. Save and redeploy

## Security Reminder ⚠️

- ✅ `.env` file is already in `.gitignore` (won't be committed)
- ✅ `service-account.json` is in `.gitignore` (won't be committed)
- ❌ **NEVER** commit these files to Git
- ❌ **NEVER** share these credentials publicly

## Test It

After setting up, restart your backend server and test the emergency alert feature!
