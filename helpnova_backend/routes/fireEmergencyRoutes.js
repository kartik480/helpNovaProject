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
    const { fireType, severityLevel, photo, location } = req.body;

    // Validation
    if (!fireType || !severityLevel || !location) {
      return res.status(400).json({
        message: "Please provide all required fields",
        success: false,
      });
    }

    if (!location.latitude || !location.longitude) {
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

    await fireEmergencyRequest.save();

    // Populate user details
    await fireEmergencyRequest.populate('userId', 'name email phone');

    res.status(201).json({
      message: "Fire emergency request created successfully",
      success: true,
      request: fireEmergencyRequest,
    });
  } catch (error) {
    console.error("Fire emergency request creation error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
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
