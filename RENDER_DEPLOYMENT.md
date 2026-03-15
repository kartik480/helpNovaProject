# Deploy Help Nova Backend to Render.com

This guide will help you deploy your Help Nova backend to Render.com so your Flutter app can connect to a live server.

## Prerequisites

1. A Render.com account (sign up at https://render.com)
2. MongoDB Atlas account (for cloud database) or use Render's MongoDB service
3. Your backend code pushed to GitHub

## Step 1: Set Up MongoDB Atlas (if not already done)

1. Go to https://www.mongodb.com/cloud/atlas
2. Create a free cluster
3. Create a database user
4. Whitelist your IP (or use `0.0.0.0/0` for all IPs - less secure but works for testing)
5. Get your connection string (looks like: `mongodb+srv://username:password@cluster.mongodb.net/helpnova`)

## Step 2: Deploy Backend to Render.com

### Option A: Using Render Dashboard

1. **Go to Render Dashboard**
   - Visit https://dashboard.render.com
   - Click "New +" → "Web Service"

2. **Connect Repository**
   - Connect your GitHub account
   - Select the `helpNovaProject` repository
   - Choose the branch (usually `main` or `master`)

3. **Configure Service**
   - **Name**: `helpnova-backend` (or any name you prefer)
   - **Root Directory**: `helpnova_backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`

4. **Set Environment Variables**
   Click "Advanced" → "Add Environment Variable" and add:
   ```
   NODE_ENV=production
   PORT=10000
   MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/helpnova
   JWT_SECRET=your-super-secret-jwt-key-change-this-to-something-random-and-secure
   ```
   
   **Important**: 
   - Replace `MONGO_URI` with your actual MongoDB Atlas connection string
   - Replace `JWT_SECRET` with a strong random string (you can generate one at https://randomkeygen.com/)

5. **Deploy**
   - Click "Create Web Service"
   - Render will build and deploy your service
   - Wait for deployment to complete (usually 2-5 minutes)
   - Your service URL will be: `https://helpnova-backend.onrender.com` (or your custom name)

### Option B: Using render.yaml (Automated)

If you prefer automated setup, the `render.yaml` file is already created. However, you'll still need to:
1. Set environment variables in Render dashboard
2. Connect your GitHub repository

## Step 3: Update Flutter App

1. **Open** `lib/services/api_service.dart`

2. **Update the baseUrl** to your Render.com URL:
   ```dart
   static const String baseUrl = 'https://helpnova-backend.onrender.com/api';
   ```
   Replace `helpnova-backend` with your actual Render service name.

3. **For Production Build** (Optional - Better approach):
   You can also use build-time configuration:
   ```dart
   static const String baseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://helpnova-backend.onrender.com/api',
   );
   ```
   
   Then build with:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://helpnova-backend.onrender.com/api
   ```

## Step 4: Test Your Deployment

1. **Test the API** in your browser:
   - Visit: `https://helpnova-backend.onrender.com`
   - You should see: `{"message":"Help Nova Backend API is running!"}`

2. **Test from Flutter App**:
   - Build your APK: `flutter build apk`
   - Install on your device
   - Try to sign up or login
   - Check if it connects to your Render.com backend

## Step 5: Build Production APK

```bash
# Build APK with production API URL
flutter build apk --release

# Or if using environment variable
flutter build apk --release --dart-define=API_BASE_URL=https://helpnova-backend.onrender.com/api
```

The APK will be in: `build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

### Issue: "Cannot connect to server"
- **Solution**: Make sure your Render.com service is running (check dashboard)
- Verify the URL in `api_service.dart` matches your Render service URL
- Check that CORS is enabled (already done in `index.js`)

### Issue: "MongoDB connection error"
- **Solution**: 
  - Verify your MongoDB Atlas connection string
  - Make sure IP whitelist includes Render.com IPs (or use `0.0.0.0/0`)
  - Check database user credentials

### Issue: "401 Unauthorized" or JWT errors
- **Solution**: Make sure `JWT_SECRET` is set in Render.com environment variables

### Issue: Render.com service goes to sleep
- **Free tier**: Services sleep after 15 minutes of inactivity
- **Solution**: 
  - Upgrade to paid plan (always-on)
  - Or use a service like UptimeRobot to ping your service every 10 minutes

## Environment Variables Summary

Required in Render.com:
- `NODE_ENV=production`
- `PORT=10000` (Render uses port 10000)
- `MONGO_URI=your-mongodb-atlas-connection-string`
- `JWT_SECRET=your-secret-key`

## Next Steps

1. ✅ Deploy backend to Render.com
2. ✅ Update Flutter app with Render.com URL
3. ✅ Test the connection
4. ✅ Build production APK
5. 🎉 Your app is now live!

## Support

If you encounter issues:
- Check Render.com logs in the dashboard
- Verify all environment variables are set
- Test API endpoints using Postman or curl
- Check MongoDB Atlas connection
