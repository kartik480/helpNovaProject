const express = require("express");
const BloodRequest = require("../models/BloodRequest");
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

// Create a new blood donation request
router.post("/create", authenticateToken, async (req, res) => {
  try {
    const { bloodGroup, hospitalName, patientName, unitsRequired, urgencyLevel, location } = req.body;

    // Validation
    if (!bloodGroup || !hospitalName || !patientName || !unitsRequired || !urgencyLevel || !location) {
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

    // Create blood request
    const bloodRequest = new BloodRequest({
      userId: req.userId,
      bloodGroup,
      hospitalName,
      patientName,
      unitsRequired: parseInt(unitsRequired),
      urgencyLevel,
      location: {
        latitude: parseFloat(location.latitude),
        longitude: parseFloat(location.longitude),
      },
      status: 'pending',
    });

    await bloodRequest.save();

    // Populate user details
    await bloodRequest.populate('userId', 'name email phone');

    res.status(201).json({
      message: "Blood donation request created successfully",
      success: true,
      request: bloodRequest,
    });
  } catch (error) {
    console.error("Blood request creation error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get all blood requests (for nearby blood donors)
router.get("/all", authenticateToken, async (req, res) => {
  try {
    const requests = await BloodRequest.find({ status: 'pending' })
      .populate('userId', 'name email phone bloodGroup skill')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get blood requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get user's own blood requests
router.get("/my-requests", authenticateToken, async (req, res) => {
  try {
    const requests = await BloodRequest.find({ userId: req.userId })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get my blood requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Accept a blood request (for blood donors)
router.post("/:requestId/accept", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const bloodRequest = await BloodRequest.findById(requestId);

    if (!bloodRequest) {
      return res.status(404).json({
        message: "Blood request not found",
        success: false,
      });
    }

    // Check if already accepted by this user
    if (bloodRequest.acceptedBy.includes(req.userId)) {
      return res.status(400).json({
        message: "You have already accepted this request",
        success: false,
      });
    }

    // Add user to acceptedBy array
    bloodRequest.acceptedBy.push(req.userId);
    
    // Update status if first acceptance
    if (bloodRequest.status === 'pending') {
      bloodRequest.status = 'accepted';
    }

    await bloodRequest.save();

    res.status(200).json({
      message: "Blood request accepted successfully",
      success: true,
      request: bloodRequest,
    });
  } catch (error) {
    console.error("Accept blood request error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
