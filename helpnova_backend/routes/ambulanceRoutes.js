const express = require("express");
const AmbulanceRequest = require("../models/AmbulanceRequest");
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

// Create a new ambulance request
router.post("/create", authenticateToken, async (req, res) => {
  try {
    const { patientCondition, patientAge, pickupLocation, hospitalDestination, contactNumber } = req.body;

    // Validation
    if (!patientCondition || !patientAge || !pickupLocation || !contactNumber) {
      return res.status(400).json({
        message: "Please provide all required fields",
        success: false,
      });
    }

    if (!pickupLocation.latitude || !pickupLocation.longitude) {
      return res.status(400).json({
        message: "Please provide valid pickup location coordinates",
        success: false,
      });
    }

    // Create ambulance request
    const ambulanceRequest = new AmbulanceRequest({
      userId: req.userId,
      patientCondition,
      patientAge: parseInt(patientAge),
      pickupLocation: {
        latitude: parseFloat(pickupLocation.latitude),
        longitude: parseFloat(pickupLocation.longitude),
      },
      hospitalDestination: hospitalDestination || null,
      contactNumber,
      status: 'pending',
    });

    await ambulanceRequest.save();

    // Populate user details
    await ambulanceRequest.populate('userId', 'name email phone');

    // TODO: In a real system, here you would:
    // 1. Find nearest available ambulance
    // 2. Calculate ETA
    // 3. Assign ambulance
    // 4. Send notifications

    res.status(201).json({
      message: "Ambulance request created successfully",
      success: true,
      request: ambulanceRequest,
    });
  } catch (error) {
    console.error("Ambulance request creation error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get all ambulance requests (for ambulance services)
router.get("/all", authenticateToken, async (req, res) => {
  try {
    const requests = await AmbulanceRequest.find({ status: { $in: ['pending', 'assigned'] } })
      .populate('userId', 'name email phone')
      .populate('assignedAmbulance', 'name email phone')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get ambulance requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get user's own ambulance requests
router.get("/my-requests", authenticateToken, async (req, res) => {
  try {
    const requests = await AmbulanceRequest.find({ userId: req.userId })
      .populate('assignedAmbulance', 'name email phone')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get my ambulance requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Assign ambulance to a request
router.post("/:requestId/assign", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;
    const { eta } = req.body; // ETA in minutes

    const ambulanceRequest = await AmbulanceRequest.findById(requestId);

    if (!ambulanceRequest) {
      return res.status(404).json({
        message: "Ambulance request not found",
        success: false,
      });
    }

    if (ambulanceRequest.status !== 'pending') {
      return res.status(400).json({
        message: "This request has already been assigned",
        success: false,
      });
    }

    // Assign ambulance
    ambulanceRequest.assignedAmbulance = req.userId;
    ambulanceRequest.status = 'assigned';
    if (eta) {
      ambulanceRequest.eta = parseInt(eta);
    }

    await ambulanceRequest.save();

    res.status(200).json({
      message: "Ambulance assigned successfully",
      success: true,
      request: ambulanceRequest,
    });
  } catch (error) {
    console.error("Assign ambulance error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
