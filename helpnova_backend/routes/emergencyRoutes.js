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

    // Step 2: Find nearby users (within 5km radius) who have FCM tokens and are active
    // Only include users with location updated within the last 5 minutes (active users)
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000); // 5 minutes ago
    
    const nearbyUsers = await User.find({
      _id: { $ne: req.userId }, // Exclude the sender
      fcmToken: { $ne: null, $exists: true }, // Only users with FCM tokens
      locationAllowed: true, // Only users who allow location sharing
      'location.latitude': { $ne: null, $exists: true }, // Only users with location data
      'location.longitude': { $ne: null, $exists: true },
      'location.lastUpdated': { $gte: fiveMinutesAgo }, // Only users with recent location updates (active)
    });

    // Filter users by distance (within 5km)
    const usersToNotify = [];
    const maxDistance = 5; // 5km radius

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

        // Only include users within 5km radius
        if (distance <= maxDistance) {
          usersToNotify.push({
            ...user.toObject(),
            distance: distance // Add distance for reference
          });
        }
      }
    }

    if (usersToNotify.length === 0) {
      return res.status(200).json({
        success: true,
        message: "No nearby helpers found with notification enabled",
        notifiedUsers: 0,
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
    const notificationPromises = usersToNotify.map(async (user) => {
      try {
        const result = await sendFCMNotification(
          user.fcmToken,
          notificationPayload,
          dataPayload
        );

        if (result.success) {
          successCount++;
          // Track notified user in the request
          savedRequest.notifiedUsers.push({
            userId: user._id,
            notifiedAt: new Date()
          });
          return { success: true, userId: user._id };
        } else {
          failCount++;
          console.error(`Failed to send notification to user ${user._id}:`, result.error);
          return { success: false, userId: user._id, error: result.error };
        }
      } catch (error) {
        failCount++;
        console.error(`Error sending notification to user ${user._id}:`, error.message);
        return { success: false, userId: user._id, error: error.message };
      }
    });

    await Promise.all(notificationPromises);

    // Save the updated request with notified users
    await savedRequest.save();

    // Step 4: Return response with request ID
    res.status(200).json({
      success: true,
      message: `Emergency alert sent to ${successCount} nearby helpers`,
      requestId: savedRequest._id.toString(),
      notifiedUsers: successCount,
      failedUsers: failCount,
      totalUsers: usersToNotify.length,
    });
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

    // Add helper to accepted helpers list
    emergencyRequest.acceptedHelpers.push({
      helperId: helper._id,
      helperName: helper.name,
      helperPhone: helper.phone,
      acceptedAt: new Date(),
      distance: distance,
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

module.exports = router;
