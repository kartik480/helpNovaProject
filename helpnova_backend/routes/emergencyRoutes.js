const express = require("express");
const User = require("../models/User");
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

    // Find nearby users (within 5km radius) who have FCM tokens
    const nearbyUsers = await User.find({
      _id: { $ne: req.userId }, // Exclude the sender
      fcmToken: { $ne: null, $exists: true }, // Only users with FCM tokens
      locationAllowed: true, // Only users who allow location sharing
      'location.latitude': { $ne: null, $exists: true }, // Only users with location data
      'location.longitude': { $ne: null, $exists: true },
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

    const notificationPromises = usersToNotify.map(async (user) => {
      try {
        const result = await sendFCMNotification(
          user.fcmToken,
          notificationPayload,
          dataPayload
        );

        if (result.success) {
          successCount++;
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

    res.status(200).json({
      success: true,
      message: `Emergency alert sent to ${successCount} nearby helpers`,
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

module.exports = router;
