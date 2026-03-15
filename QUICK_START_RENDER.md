# Quick Start: Deploy to Render.com

## 🚀 Quick Deployment Steps

### 1. Get MongoDB Atlas Connection String
- Go to https://www.mongodb.com/cloud/atlas
- Create free cluster → Create database user → Get connection string
- Example: `mongodb+srv://user:pass@cluster.mongodb.net/helpnova`

### 2. Deploy to Render.com

1. **Go to**: https://dashboard.render.com
2. **Click**: "New +" → "Web Service"
3. **Connect**: Your GitHub repository (`helpNovaProject`)
4. **Configure**:
   - **Name**: `helpnova-backend`
   - **Root Directory**: `helpnova_backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`

5. **Add Environment Variables**:
   ```
   NODE_ENV=production
   PORT=10000
   MONGO_URI=mongodb+srv://your-connection-string
   JWT_SECRET=generate-a-random-secret-key-here
   ```

6. **Deploy** → Wait 2-5 minutes

7. **Get Your URL**: `https://helpnova-backend.onrender.com`

### 3. Update Flutter App

Open `lib/services/api_service.dart` and update:
```dart
static const String baseUrl = 'https://helpnova-backend.onrender.com/api';
```
(Replace `helpnova-backend` with your actual service name)

### 4. Build APK

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

## ✅ Done!

Your app is now live and ready to use!

## 📝 Notes

- **Free tier**: Service sleeps after 15 min inactivity (first request may be slow)
- **Always-on**: Upgrade to paid plan for instant responses
- **Testing**: Visit `https://your-service.onrender.com` to verify it's running
