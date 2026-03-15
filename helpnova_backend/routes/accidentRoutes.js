const express = require("express");
const AccidentRequest = require("../models/AccidentRequest");
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

// Create a new accident report
router.post("/create", authenticateToken, async (req, res) => {
  try {
    const { accidentType, numberOfInjured, description, photo, location } = req.body;

    // Validation
    if (!accidentType || !numberOfInjured || !description || !location) {
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

    // Create accident request
    const accidentRequest = new AccidentRequest({
      userId: req.userId,
      accidentType,
      numberOfInjured: parseInt(numberOfInjured),
      description,
      photo: photo || null,
      location: {
        latitude: parseFloat(location.latitude),
        longitude: parseFloat(location.longitude),
      },
      status: 'pending',
    });

    await accidentRequest.save();

    // Populate user details
    await accidentRequest.populate('userId', 'name email phone');

    res.status(201).json({
      message: "Accident report created successfully",
      success: true,
      request: accidentRequest,
    });
  } catch (error) {
    console.error("Accident request creation error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get all accident requests (for nearby volunteers/helpers)
router.get("/all", authenticateToken, async (req, res) => {
  try {
    const requests = await AccidentRequest.find({ status: 'pending' })
      .populate('userId', 'name email phone bloodGroup skill')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get accident requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get user's own accident requests
router.get("/my-requests", authenticateToken, async (req, res) => {
  try {
    const requests = await AccidentRequest.find({ userId: req.userId })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get my accident requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Accept an accident request (for volunteers/helpers)
router.post("/:requestId/accept", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const accidentRequest = await AccidentRequest.findById(requestId);

    if (!accidentRequest) {
      return res.status(404).json({
        message: "Accident request not found",
        success: false,
      });
    }

    // Check if already accepted by this user
    if (accidentRequest.acceptedBy.includes(req.userId)) {
      return res.status(400).json({
        message: "You have already accepted this request",
        success: false,
      });
    }

    // Add user to acceptedBy array
    accidentRequest.acceptedBy.push(req.userId);
    
    // Update status if first acceptance
    if (accidentRequest.status === 'pending') {
      accidentRequest.status = 'accepted';
    }

    await accidentRequest.save();

    res.status(200).json({
      message: "Accident request accepted successfully",
      success: true,
      request: accidentRequest,
    });
  } catch (error) {
    console.error("Accept accident request error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
