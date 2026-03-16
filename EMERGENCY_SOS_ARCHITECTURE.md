# Emergency SOS System Architecture

## Overview
This document describes the complete flow of the Emergency SOS feature in HelpNova app, following Firebase Cloud Messaging (FCM) best practices.

## System Flow

### 1️⃣ User Presses SOS (Mobile 1)

```
User presses "Send Alert to Nearby Helpers" button
        ↓
App gets current location (latitude, longitude)
        ↓
API Call: POST /api/emergency/send-alert
        ↓
Backend saves SOS request to MongoDB (EmergencyRequest collection)
        ↓
Backend finds nearby users (within 5km radius)
        ↓
Backend sends FCM notifications to nearby users
        ↓
Mobile 2 receives notification
```

### 2️⃣ Database Storage (MongoDB - Equivalent to Firestore)

**EmergencyRequest Model** stores:
- `userId`: User who sent the SOS
- `userName`: Name of the requester
- `userPhone`: Phone number
- `type`: "emergency_sos"
- `location`: { latitude, longitude, address }
- `description`: Emergency description
- `status`: "active" | "resolved" | "cancelled"
- `acceptedHelpers`: Array of helpers who accepted
- `notifiedUsers`: Array of users who were notified
- `createdAt`: Timestamp
- `resolvedAt`: Timestamp (when resolved)

### 3️⃣ Nearby User Filtering

**Backend Logic:**
1. Find all users with:
   - FCM token registered
   - Location sharing enabled
   - Valid location data
2. Calculate distance using Haversine formula
3. Filter users within 5km radius
4. Send notifications only to filtered users

### 4️⃣ FCM Notification Payload

**Notification:**
```json
{
  "title": "🚨 Emergency SOS Alert",
  "body": "Karthik needs immediate help! Emergency assistance required."
}
```

**Data Payload:**
```json
{
  "type": "emergency_sos",
  "requestId": "507f1f77bcf86cd799439011",
  "userId": "507f191e810c19729de860ea",
  "userName": "Karthik",
  "userPhone": "+1234567890",
  "latitude": "17.3850",
  "longitude": "78.4867",
  "description": "Emergency SOS request",
  "click_action": "FLUTTER_NOTIFICATION_CLICK"
}
```

### 5️⃣ Mobile 2 Receives Notification

**Foreground (App Open):**
- `FirebaseMessaging.onMessage` listener triggers
- `EmergencyNotificationDialog` appears immediately
- User can see: Name, Phone, Location, Description
- Actions: Accept Help, Decline, Call, Navigate

**Background/Terminated:**
- System notification appears
- User taps notification
- `FirebaseMessaging.onMessageOpenedApp` triggers
- App opens and shows `EmergencyNotificationDialog`

### 6️⃣ Helper Accepts Request

```
User taps "Accept Help" button
        ↓
API Call: POST /api/emergency/accept-request/:requestId
        ↓
Backend adds helper to acceptedHelpers array
        ↓
Backend calculates distance between helper and requester
        ↓
Backend saves updated request
        ↓
Helper appears in "Accepted Requests" panel on Mobile 1
```

### 7️⃣ Accepted Helpers Display

**Mobile 1 (Requester):**
- Calls: `GET /api/helpers/my-latest-request/helpers`
- Shows list of helpers who accepted
- Displays: Name, Phone, Distance, Accept Time
- Can call or navigate to each helper

## Technical Components

### Frontend (Flutter)

**Packages:**
- `firebase_core`: Firebase initialization
- `firebase_messaging`: FCM notifications
- `geolocator`: Location services
- `shared_preferences`: Local storage

**Key Files:**
- `lib/services/notification_service.dart`: FCM handling
- `lib/widgets/emergency_notification_dialog.dart`: Notification popup
- `lib/emergency_sos_screen.dart`: SOS screen
- `lib/home_screen.dart`: Home screen with notification listener

### Backend (Node.js + MongoDB)

**Key Files:**
- `helpnova_backend/models/EmergencyRequest.js`: Request model
- `helpnova_backend/models/User.js`: User model (with FCM token)
- `helpnova_backend/routes/emergencyRoutes.js`: Emergency endpoints
- `helpnova_backend/utils/fcmV1Service.js`: FCM V1 API service
- `helpnova_backend/utils/distanceCalculator.js`: Distance calculation

**Endpoints:**
- `POST /api/emergency/send-alert`: Send SOS alert
- `POST /api/emergency/accept-request/:requestId`: Accept request
- `GET /api/emergency/request/:requestId/helpers`: Get accepted helpers
- `POST /api/auth/update-fcm-token`: Update FCM token
- `POST /api/auth/update-location`: Update user location

## FCM Token Management

1. **App Initialization:**
   - Request notification permissions
   - Get FCM token
   - Save token to backend

2. **Token Refresh:**
   - Listen for token refresh events
   - Automatically update backend when token changes

3. **Token Storage:**
   - Stored in MongoDB User model
   - Updated whenever user logs in or token refreshes

## Location Updates

- Home screen automatically gets user location
- Location sent to backend every time app opens
- Backend stores: `{ latitude, longitude, lastUpdated }`
- Used for filtering nearby users (5km radius)

## Notification Flow Diagram

```
Mobile 1 (SOS)          Backend              Mobile 2
     │                     │                     │
     │── Send Alert ──────>│                     │
     │                     │── Save Request      │
     │                     │── Find Nearby (5km)  │
     │                     │── Send FCM ────────>│
     │                     │                     │── Show Dialog
     │                     │                     │── User Accepts
     │                     │<── Accept Request ──│
     │                     │── Update Request    │
     │<── Request ID ──────│                     │
     │── Refresh Helpers ──>│                     │
     │<── Helpers List ────│                     │
```

## Important Notes

1. **No API Key in Flutter Code**: Firebase automatically handles authentication via `google-services.json` and `firebase_options.dart`

2. **5km Radius**: Only users within 5km receive notifications

3. **Request Storage**: All SOS requests are stored in MongoDB for tracking and history

4. **Real-time Updates**: Accepted helpers appear in real-time on requester's screen

5. **FCM V1 API**: Using modern FCM V1 API (not Legacy) for better reliability

## Testing Checklist

- [ ] Mobile 1 sends SOS alert
- [ ] Request saved to database
- [ ] Mobile 2 receives notification (within 5km)
- [ ] Dialog appears on Mobile 2 home screen
- [ ] Mobile 2 can accept request
- [ ] Accepted helper appears on Mobile 1
- [ ] Location filtering works correctly (5km)
- [ ] FCM token updates automatically
- [ ] Background notifications work
- [ ] Terminated app notifications work
