const express = require("express");
const FireEmergencyRequest = require("../models/FireEmergencyRequest");
const User = require("../models/User");
const jwt = require("jsonwebtoken");

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

// Create a new fire emergency request
router.post("/create", authenticateToken, async (req, res) => {
  try {
    // Check database connection
    const mongoose = require("mongoose");
    if (mongoose.connection.readyState !== 1) {
      console.error(`[Fire Emergency Request] ❌ Database not connected!`);
      return res.status(503).json({
        message: "Database connection unavailable. Please try again later.",
        success: false,
      });
    }
    
    console.log(`[Fire Emergency Request] Creating request for user ${req.userId}`);
    console.log(`[Fire Emergency Request] Request body:`, JSON.stringify(req.body, null, 2));
    
    const { fireType, severityLevel, photo, location } = req.body;

    // Validation
    if (!fireType || !severityLevel || !location) {
      console.log(`[Fire Emergency Request] Validation failed - missing fields`);
      return res.status(400).json({
        message: "Please provide all required fields",
        success: false,
      });
    }

    if (!location.latitude || !location.longitude) {
      console.log(`[Fire Emergency Request] Validation failed - invalid location`);
      return res.status(400).json({
        message: "Please provide valid location coordinates",
        success: false,
      });
    }

    // Create fire emergency request
    const fireEmergencyRequest = new FireEmergencyRequest({
      userId: req.userId,
      fireType,
      severityLevel,
      photo: photo || null,
      location: {
        latitude: parseFloat(location.latitude),
        longitude: parseFloat(location.longitude),
      },
      status: 'pending',
    });

    console.log(`[Fire Emergency Request] Attempting to save request to database...`);
    const savedRequest = await fireEmergencyRequest.save();
    console.log(`[Fire Emergency Request] ✅ Request saved successfully with ID: ${savedRequest._id}`);

    // Populate user details
    await savedRequest.populate('userId', 'name email phone');
    console.log(`[Fire Emergency Request] ✅ Request populated with user details`);

    res.status(201).json({
      message: "Fire emergency request created successfully",
      success: true,
      request: savedRequest,
    });
  } catch (error) {
    console.error("❌ Fire emergency request creation error:", error);
    console.error("❌ Error stack:", error.stack);
    
    // More detailed error information
    let errorMessage = "Server error. Please try again later.";
    if (error.name === 'ValidationError') {
      errorMessage = `Validation error: ${Object.values(error.errors).map(e => e.message).join(', ')}`;
    } else if (error.name === 'MongoServerError') {
      errorMessage = `Database error: ${error.message}`;
    } else if (error.message) {
      errorMessage = error.message;
    }
    
    res.status(500).json({
      message: errorMessage,
      success: false,
      error: error.message,
      errorName: error.name,
    });
  }
});

// Get all fire emergency requests (for nearby helpers/fire services)
router.get("/all", authenticateToken, async (req, res) => {
  try {
    const requests = await FireEmergencyRequest.find({ status: 'pending' })
      .populate('userId', 'name email phone')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get fire emergency requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get user's own fire emergency requests
router.get("/my-requests", authenticateToken, async (req, res) => {
  try {
    const requests = await FireEmergencyRequest.find({ userId: req.userId })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get my fire emergency requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Accept a fire emergency request (for helpers/fire services)
router.post("/:requestId/accept", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const fireEmergencyRequest = await FireEmergencyRequest.findById(requestId);

    if (!fireEmergencyRequest) {
      return res.status(404).json({
        message: "Fire emergency request not found",
        success: false,
      });
    }

    // Check if already accepted by this user
    if (fireEmergencyRequest.acceptedBy.includes(req.userId)) {
      return res.status(400).json({
        message: "You have already accepted this request",
        success: false,
      });
    }

    // Add user to acceptedBy array
    fireEmergencyRequest.acceptedBy.push(req.userId);
    
    // Update status if first acceptance
    if (fireEmergencyRequest.status === 'pending') {
      fireEmergencyRequest.status = 'accepted';
    }

    await fireEmergencyRequest.save();

    res.status(200).json({
      message: "Fire emergency request accepted successfully",
      success: true,
      request: fireEmergencyRequest,
    });
  } catch (error) {
    console.error("Accept fire emergency request error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
