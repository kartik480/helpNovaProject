# How to Get SHA-1 Certificate Fingerprint

## For Debug Build (Testing)

Run this command in your project root:

**Windows (PowerShell):**
```powershell
cd android
.\gradlew signingReport
```

**Windows (CMD) or Mac/Linux:**
```bash
cd android
./gradlew signingReport
```

Look for output like:
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Copy the SHA1 value (without spaces or colons, or with colons - Google accepts both formats).

## Alternative: Using Keytool

If gradlew doesn't work, use keytool:

**Windows:**
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Mac/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## For Release Build (Production)

When you create a release keystore, get its SHA-1:
```bash
keytool -list -v -keystore path/to/your/release.keystore -alias your-key-alias
```

## Add to Google Cloud Console

1. In the "Android apps" restriction section
2. Click "Add an item"
3. Enter:
   - Package name: `com.example.helpnovaproject`
   - SHA-1 certificate fingerprint: (paste the SHA-1 you got above)
4. Click "Save" or "Create key"

## Note

- For development/testing: Use debug SHA-1
- For production: You'll need to add the release SHA-1 later
- You can add multiple SHA-1 fingerprints to the same API key
