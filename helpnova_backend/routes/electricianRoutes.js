const express = require("express");
const ElectricianRequest = require("../models/ElectricianRequest");
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

// Create a new electrician request
router.post("/create", authenticateToken, async (req, res) => {
  try {
    const { problemType, description, photo, location } = req.body;

    // Validation
    if (!problemType || !description || !location) {
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

    // Create electrician request
    const electricianRequest = new ElectricianRequest({
      userId: req.userId,
      problemType,
      description,
      photo: photo || null,
      location: {
        latitude: parseFloat(location.latitude),
        longitude: parseFloat(location.longitude),
      },
      status: 'pending',
    });

    await electricianRequest.save();

    // Populate user details
    await electricianRequest.populate('userId', 'name email phone');

    res.status(201).json({
      message: "Electrician request created successfully",
      success: true,
      request: electricianRequest,
    });
  } catch (error) {
    console.error("Electrician request creation error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get all electrician requests (for nearby electricians)
router.get("/all", authenticateToken, async (req, res) => {
  try {
    const requests = await ElectricianRequest.find({ status: 'pending' })
      .populate('userId', 'name email phone')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get electrician requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get user's own electrician requests
router.get("/my-requests", authenticateToken, async (req, res) => {
  try {
    const requests = await ElectricianRequest.find({ userId: req.userId })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get my electrician requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Accept an electrician request (for electricians)
router.post("/:requestId/accept", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const electricianRequest = await ElectricianRequest.findById(requestId);

    if (!electricianRequest) {
      return res.status(404).json({
        message: "Electrician request not found",
        success: false,
      });
    }

    // Check if already accepted by this user
    if (electricianRequest.acceptedBy.includes(req.userId)) {
      return res.status(400).json({
        message: "You have already accepted this request",
        success: false,
      });
    }

    // Add user to acceptedBy array
    electricianRequest.acceptedBy.push(req.userId);
    
    // Update status if first acceptance
    if (electricianRequest.status === 'pending') {
      electricianRequest.status = 'accepted';
    }

    await electricianRequest.save();

    res.status(200).json({
      message: "Electrician request accepted successfully",
      success: true,
      request: electricianRequest,
    });
  } catch (error) {
    console.error("Accept electrician request error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
