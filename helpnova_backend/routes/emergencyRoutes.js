const express = require("express");
const User = require("../models/User");
const EmergencyRequest = require("../models/EmergencyRequest");
const jwt = require("jsonwebtoken");
const { calculateDistance } = require("../utils/distanceCalculator");
const { sendFCMNotification } = require("../utils/fcmV1Service");

const router = express.Router();

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      message: "Access denied. No token provided.",
      success: false,
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key");
    req.userId = decoded.userId;
    next();
  } catch (error) {
    return res.status(403).json({
      message: "Invalid or expired token.",
      success: false,
    });
  }
};

// Send emergency alert to nearby users
router.post("/send-alert", authenticateToken, async (req, res) => {
  try {
    const { latitude, longitude, description } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        message: "Latitude and longitude are required",
        success: false,
      });
    }

    // Get the user who is sending the alert
    const sender = await User.findById(req.userId);
    if (!sender) {
      return res.status(404).json({
        message: "User not found",
        success: false,
      });
    }

    // Step 1: Save SOS request to database (Firestore equivalent in MongoDB)
    const emergencyRequest = new EmergencyRequest({
      userId: sender._id,
      userName: sender.name,
      userPhone: sender.phone,
      type: "emergency_sos",
      location: {
        latitude: latitude,
        longitude: longitude,
        address: null // Can be populated later with geocoding
      },
      description: description || "Emergency SOS request",
      status: "active"
    });

    const savedRequest = await emergencyRequest.save();
    console.log(`✅ SOS Request saved to database: ${savedRequest._id}`);

    // Step 2: Find nearby users (within 10km radius) who are active
    // Include users with location updated within the last 1 hour (active users)
    // Also include users who just enabled location (lastUpdated might be null or very recent)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000); // 1 hour ago
    
    console.log(`🔍 Searching for nearby helpers...`);
    console.log(`📍 Sender location: ${latitude}, ${longitude}`);
    console.log(`⏰ Looking for users active within last 1 hour`);
    
    // First, find ALL active users with location enabled (like active-users endpoint)
    // We'll check for FCM tokens later when sending notifications
    const allPotentialUsers = await User.find({
      _id: { $ne: req.userId }, // Exclude the sender
      locationAllowed: true, // Only users who allow location sharing
      'location.latitude': { $ne: null, $exists: true }, // Only users with location data
      'location.longitude': { $ne: null, $exists: true },
    });

    console.log(`👥 Found ${allPotentialUsers.length} total active users with location enabled`);

    // Filter by time window (but be lenient - include if lastUpdated is null or recent)
    const nearbyUsers = allPotentialUsers.filter(user => {
      if (!user.location || !user.location.lastUpdated) {
        // Include users without lastUpdated (just enabled location)
        console.log(`✅ Including ${user.name} - location just enabled (no lastUpdated)`);
        return true;
      }
      const lastUpdated = new Date(user.location.lastUpdated);
      const isRecent = lastUpdated >= oneHourAgo;
      if (isRecent) {
        console.log(`✅ Including ${user.name} - location updated ${Math.round((Date.now() - lastUpdated.getTime()) / 60000)} minutes ago`);
      } else {
        console.log(`⚠️ Excluding ${user.name} - location updated ${Math.round((Date.now() - lastUpdated.getTime()) / 60000)} minutes ago (too old)`);
      }
      return isRecent;
    });

    console.log(`👥 After time filter: ${nearbyUsers.length} active users`);

    // Filter users by distance (within 10km - increased for better coverage)
    const usersToNotify = [];
    const maxDistance = 10; // 10km radius (increased from 5km for better coverage)

    for (const user of nearbyUsers) {
      // Check if user has valid location data
      if (user.location && user.location.latitude && user.location.longitude) {
        // Calculate distance between sender and potential helper
        const distance = calculateDistance(
          latitude,
          longitude,
          user.location.latitude,
          user.location.longitude
        );

        const hasFcmToken = user.fcmToken && user.fcmToken.trim() !== '';
        console.log(`📏 User ${user.name} (${user._id}): Distance = ${distance.toFixed(2)}km, FCM Token: ${hasFcmToken ? 'Yes' : 'No'}, Last Updated: ${user.location.lastUpdated || 'Never'}`);

        // Include users within maxDistance radius (we'll filter by FCM token when sending)
        if (distance <= maxDistance) {
          usersToNotify.push({
            ...user.toObject(),
            distance: distance // Add distance for reference
          });
          if (hasFcmToken) {
            console.log(`✅ Added ${user.name} to notification list (${distance.toFixed(2)}km away, has FCM token)`);
          } else {
            console.log(`⚠️ Added ${user.name} to notification list (${distance.toFixed(2)}km away, but NO FCM token - will skip notification)`);
          }
        } else {
          console.log(`❌ ${user.name} is too far (${distance.toFixed(2)}km > ${maxDistance}km)`);
        }
      } else {
        console.log(`⚠️ User ${user.name} has invalid location data`);
      }
    }

    console.log(`📬 Total users to notify: ${usersToNotify.length}`);
    console.log(`📊 Detailed breakdown:`);
    console.log(`   - Total active users with location: ${allPotentialUsers.length}`);
    console.log(`   - Active users after time filter: ${nearbyUsers.length}`);
    console.log(`   - Users within ${maxDistance}km: ${usersToNotify.length}`);
    
    // Log each user's details
    usersToNotify.forEach(user => {
      const hasFcm = user.fcmToken && user.fcmToken.trim() !== '';
      console.log(`   📍 ${user.name} (${user._id}): ${user.distance?.toFixed(2)}km away, FCM: ${hasFcm ? '✅' : '❌'}`);
    });

    if (usersToNotify.length === 0) {
      console.log(`⚠️ No nearby helpers found. Reasons could be:`);
      console.log(`   - No users with location enabled`);
      console.log(`   - All users are more than ${maxDistance}km away`);
      console.log(`   - Users haven't updated location recently`);
      console.log(`   - Sender location: ${latitude}, ${longitude}`);
      
      return res.status(200).json({
        success: true,
        message: "No nearby helpers found",
        notifiedUsers: 0,
        requestId: savedRequest._id.toString(),
        debug: {
          totalActiveUsers: allPotentialUsers.length,
          activeUsers: nearbyUsers.length,
          maxDistance: maxDistance,
          timeWindow: "1 hour",
          senderLocation: { latitude, longitude }
        }
      });
    }

    // Check if Firebase Service Account is configured
    if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
      console.error("FIREBASE_SERVICE_ACCOUNT not set in environment variables");
      return res.status(500).json({
        message: "Server configuration error. Firebase service account not set.",
        success: false,
      });
    }

    // Prepare notification payload
    const notificationPayload = {
      title: "🚨 Emergency SOS Alert",
      body: `${sender.name} needs immediate help! ${description || 'Emergency assistance required.'}`,
    };

    const dataPayload = {
      type: "emergency_sos",
      requestId: savedRequest._id.toString(), // Include request ID for reference
      userId: sender._id.toString(),
      userName: sender.name,
      userPhone: sender.phone,
      latitude: latitude.toString(),
      longitude: longitude.toString(),
      description: description || "Emergency SOS request",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    };

    // Send notifications to all nearby users using V1 API
    let successCount = 0;
    let failCount = 0;

    // Step 3: Send notifications to nearby users and track who was notified
    // Filter out users without FCM tokens before sending
    const usersWithFcmTokens = usersToNotify.filter(user => {
      const hasToken = user.fcmToken && user.fcmToken.trim() !== '';
      if (!hasToken) {
        console.log(`⚠️ Skipping ${user.name} (${user._id}) - No FCM token registered. They need to enable notifications in the app.`);
      }
      return hasToken;
    });

    const usersWithoutFcmCount = usersToNotify.length - usersWithFcmTokens.length;
    
    if (usersWithoutFcmCount > 0) {
      console.log(`⚠️ Warning: ${usersWithoutFcmCount} nearby helpers don't have FCM tokens and won't receive notifications.`);
      console.log(`   They need to enable notifications in the app to receive emergency alerts.`);
    }
    
    console.log(`📤 Sending notifications to ${usersWithFcmTokens.length} users (${usersWithoutFcmCount} users skipped due to missing FCM tokens)...`);
    
    const notificationPromises = usersWithFcmTokens.map(async (user) => {
      try {
        const tokenPreview = user.fcmToken ? `${user.fcmToken.substring(0, 20)}...` : 'MISSING';
        console.log(`📲 Sending notification to ${user.name} (${user._id})`);
        console.log(`   Token: ${tokenPreview}`);
        console.log(`   Distance: ${user.distance?.toFixed(2)}km`);
        console.log(`   Payload: ${JSON.stringify(notificationPayload)}`);
        
        const result = await sendFCMNotification(
          user.fcmToken,
          notificationPayload,
          dataPayload
        );

        if (result.success) {
          successCount++;
          console.log(`✅ Notification sent successfully to ${user.name} (${user._id})`);
          console.log(`   FCM Response: ${JSON.stringify(result.response)}`);
          // Track notified user in the request
          savedRequest.notifiedUsers.push({
            userId: user._id,
            notifiedAt: new Date()
          });
          return { success: true, userId: user._id, userName: user.name };
        } else {
          failCount++;
          console.error(`❌ Failed to send notification to ${user.name} (${user._id})`);
          console.error(`   Error: ${result.error}`);
          console.error(`   Status: ${result.status || 'N/A'}`);
          if (result.error && result.error.includes('invalid') || result.error.includes('not found')) {
            console.error(`   ⚠️ FCM token may be invalid or expired. User needs to re-enable notifications.`);
          }
          return { success: false, userId: user._id, userName: user.name, error: result.error };
        }
      } catch (error) {
        failCount++;
        console.error(`❌ Exception sending notification to ${user.name} (${user._id}):`, error.message);
        console.error(`   Stack: ${error.stack}`);
        return { success: false, userId: user._id, userName: user.name, error: error.message };
      }
    });

    await Promise.all(notificationPromises);

    // Save the updated request with notified users
    await savedRequest.save();
    
    console.log(`✅ Emergency alert completed:`);
    console.log(`   - Successfully notified: ${successCount} users`);
    console.log(`   - Failed notifications: ${failCount} users`);
    console.log(`   - Total nearby users: ${usersToNotify.length}`);
    console.log(`   - Users without FCM tokens (skipped): ${usersWithoutFcmCount}`);

    // Step 4: Return response with request ID
    
    // Prepare detailed response
    const response = {
      success: true,
      message: successCount > 0 
        ? `Emergency alert sent to ${successCount} nearby helper${successCount > 1 ? 's' : ''}`
        : `No helpers were notified. ${usersWithoutFcmCount > 0 ? `${usersWithoutFcmCount} helper${usersWithoutFcmCount > 1 ? 's' : ''} nearby but missing FCM tokens.` : 'No nearby helpers found.'}`,
      requestId: savedRequest._id.toString(),
      notifiedUsers: successCount,
      failedUsers: failCount,
      totalNearbyUsers: usersToNotify.length,
      usersWithoutFcmTokens: usersWithoutFcmCount,
      debug: {
        totalActiveUsers: allPotentialUsers.length,
        activeUsersAfterTimeFilter: nearbyUsers.length,
        nearbyUsersWithinDistance: usersToNotify.length,
        usersWithFcmTokens: usersWithFcmTokens.length,
        maxDistance: maxDistance,
        timeWindow: "1 hour",
        senderLocation: { latitude, longitude }
      }
    };
    
    console.log(`📤 Final response:`, JSON.stringify(response, null, 2));
    
    res.status(200).json(response);
  } catch (error) {
    console.error("Send emergency alert error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Accept emergency request (when a helper accepts the SOS)
router.post("/accept-request/:requestId", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    // Get the helper who is accepting
    const helper = await User.findById(req.userId);
    if (!helper) {
      return res.status(404).json({
        message: "User not found",
        success: false,
      });
    }

    // Find the emergency request
    const emergencyRequest = await EmergencyRequest.findById(requestId);
    if (!emergencyRequest) {
      return res.status(404).json({
        message: "Emergency request not found",
        success: false,
      });
    }

    // Check if request is still active
    if (emergencyRequest.status !== "active") {
      return res.status(400).json({
        message: "This emergency request is no longer active",
        success: false,
      });
    }

    // Check if helper already accepted
    const alreadyAccepted = emergencyRequest.acceptedHelpers.some(
      (h) => h.helperId.toString() === req.userId.toString()
    );

    if (alreadyAccepted) {
      return res.status(400).json({
        message: "You have already accepted this request",
        success: false,
      });
    }

    // Calculate distance between helper and requester
    let distance = null;
    if (helper.location && helper.location.latitude && helper.location.longitude) {
      distance = calculateDistance(
        emergencyRequest.location.latitude,
        emergencyRequest.location.longitude,
        helper.location.latitude,
        helper.location.longitude
      );
    }

    // Add helper to accepted helpers list with current location
    emergencyRequest.acceptedHelpers.push({
      helperId: helper._id,
      helperName: helper.name,
      helperPhone: helper.phone,
      acceptedAt: new Date(),
      distance: distance,
      location: helper.location && helper.location.latitude && helper.location.longitude ? {
        latitude: helper.location.latitude,
        longitude: helper.location.longitude,
        lastUpdated: new Date()
      } : null
    });

    await emergencyRequest.save();

    console.log(`✅ Helper ${helper.name} accepted emergency request ${requestId}`);

    res.status(200).json({
      success: true,
      message: "Emergency request accepted successfully",
      request: emergencyRequest,
    });
  } catch (error) {
    console.error("Accept emergency request error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get accepted helpers for a specific emergency request
router.get("/request/:requestId/helpers", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const emergencyRequest = await EmergencyRequest.findById(requestId)
      .populate('userId', 'name phone')
      .populate('acceptedHelpers.helperId', 'name phone location');

    if (!emergencyRequest) {
      return res.status(404).json({
        message: "Emergency request not found",
        success: false,
      });
    }

    res.status(200).json({
      success: true,
      request: emergencyRequest,
      helpers: emergencyRequest.acceptedHelpers || [],
      message: "Accepted helpers fetched successfully",
    });
  } catch (error) {
    console.error("Get accepted helpers error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Update helper location for an active emergency request
router.post("/update-helper-location/:requestId", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        message: "Latitude and longitude are required",
        success: false,
      });
    }

    // Find the emergency request
    const emergencyRequest = await EmergencyRequest.findById(requestId);
    if (!emergencyRequest) {
      return res.status(404).json({
        message: "Emergency request not found",
        success: false,
      });
    }

    // Check if request is still active
    if (emergencyRequest.status !== "active") {
      return res.status(400).json({
        message: "This emergency request is no longer active",
        success: false,
      });
    }

    // Find the helper in acceptedHelpers array
    const helperIndex = emergencyRequest.acceptedHelpers.findIndex(
      (h) => h.helperId.toString() === req.userId.toString()
    );

    if (helperIndex === -1) {
      return res.status(404).json({
        message: "You have not accepted this emergency request",
        success: false,
      });
    }

    // Update helper location
    emergencyRequest.acceptedHelpers[helperIndex].location = {
      latitude: latitude,
      longitude: longitude,
      lastUpdated: new Date()
    };

    // Recalculate distance
    const distance = calculateDistance(
      emergencyRequest.location.latitude,
      emergencyRequest.location.longitude,
      latitude,
      longitude
    );
    emergencyRequest.acceptedHelpers[helperIndex].distance = distance;

    await emergencyRequest.save();

    console.log(`📍 Helper ${req.userId} updated location for request ${requestId}: ${latitude}, ${longitude}`);

    res.status(200).json({
      success: true,
      message: "Location updated successfully",
      distance: distance,
    });
  } catch (error) {
    console.error("Update helper location error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get real-time helper locations for victim's active emergency request
router.get("/my-active-request/helpers-locations", authenticateToken, async (req, res) => {
  try {
    // Find the user's latest active emergency request
    const activeRequest = await EmergencyRequest.findOne({
      userId: req.userId,
      status: "active"
    }).sort({ createdAt: -1 });

    if (!activeRequest) {
      return res.status(200).json({
        success: true,
        message: "No active emergency request found",
        helpers: [],
        requestId: null,
      });
    }

    // Format helpers with their locations
    const helpersWithLocations = activeRequest.acceptedHelpers
      .filter(helper => helper.location && helper.location.latitude && helper.location.longitude)
      .map(helper => ({
        helperId: helper.helperId.toString(),
        name: helper.helperName,
        phone: helper.helperPhone,
        latitude: helper.location.latitude,
        longitude: helper.location.longitude,
        distance: helper.distance,
        lastUpdated: helper.location.lastUpdated,
        acceptedAt: helper.acceptedAt
      }));

    console.log(`📍 Fetched ${helpersWithLocations.length} helpers with locations for request ${activeRequest._id}`);

    res.status(200).json({
      success: true,
      requestId: activeRequest._id.toString(),
      helpers: helpersWithLocations,
      count: helpersWithLocations.length,
      message: "Helper locations fetched successfully",
    });
  } catch (error) {
    console.error("Get helper locations error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Test endpoint to check Firebase Service Account configuration
router.get("/test-fcm-config", authenticateToken, async (req, res) => {
  try {
    const { getAccessToken, getProjectId } = require("../utils/fcmV1Service");
    
    // Check if environment variable is set
    const hasServiceAccount = !!process.env.FIREBASE_SERVICE_ACCOUNT;
    
    if (!hasServiceAccount) {
      return res.status(500).json({
        success: false,
        message: "❌ FIREBASE_SERVICE_ACCOUNT environment variable is NOT set",
        configured: false,
        instructions: {
          step1: "Go to Firebase Console: https://console.firebase.google.com/",
          step2: "Select your project → Project Settings → Service Accounts",
          step3: "Click 'Generate new private key' and download the JSON file",
          step4: "Save the JSON content to helpnova_backend/.env as: FIREBASE_SERVICE_ACCOUNT={your-json-here}",
          step5: "Or use the setup script: node helpnova_backend/setup-env.js"
        }
      });
    }

    // Try to parse and get project ID
    let projectId = null;
    let isValid = false;
    let errorMessage = null;
    
    try {
      projectId = getProjectId();
      isValid = true;
    } catch (error) {
      isValid = false;
      errorMessage = error.message;
    }

    // Try to get access token (this will verify the credentials work)
    let tokenWorks = false;
    let tokenError = null;
    
    if (isValid) {
      try {
        await getAccessToken();
        tokenWorks = true;
      } catch (error) {
        tokenWorks = false;
        tokenError = error.message;
      }
    }

    res.status(200).json({
      success: true,
      configured: hasServiceAccount,
      isValid: isValid,
      tokenWorks: tokenWorks,
      projectId: projectId || "Unable to get project ID",
      status: tokenWorks ? "✅ FCM is properly configured and working!" : "⚠️ FCM is configured but has issues",
      errors: {
        parsing: errorMessage,
        token: tokenError
      },
      message: tokenWorks 
        ? "Firebase Service Account is properly configured and ready to send notifications!"
        : "Firebase Service Account is set but there are issues. Check the errors above."
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error checking FCM configuration",
      error: error.message
    });
  }
});

module.exports = router;
