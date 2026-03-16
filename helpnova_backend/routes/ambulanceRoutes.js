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
    // Check database connection
    const mongoose = require("mongoose");
    if (mongoose.connection.readyState !== 1) {
      console.error(`[Ambulance Request] ❌ Database not connected!`);
      return res.status(503).json({
        message: "Database connection unavailable. Please try again later.",
        success: false,
      });
    }
    
    console.log(`[Ambulance Request] Creating request for user ${req.userId}`);
    console.log(`[Ambulance Request] Request body:`, JSON.stringify(req.body, null, 2));
    
    const { patientCondition, patientAge, pickupLocation, hospitalDestination, contactNumber } = req.body;

    // Validation
    if (!patientCondition || !patientAge || !pickupLocation || !contactNumber) {
      console.log(`[Ambulance Request] Validation failed - missing fields`);
      return res.status(400).json({
        message: "Please provide all required fields",
        success: false,
      });
    }

    if (!pickupLocation.latitude || !pickupLocation.longitude) {
      console.log(`[Ambulance Request] Validation failed - invalid location`);
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

    console.log(`[Ambulance Request] Attempting to save request to database...`);
    const savedRequest = await ambulanceRequest.save();
    console.log(`[Ambulance Request] ✅ Request saved successfully with ID: ${savedRequest._id}`);

    // Populate user details
    await savedRequest.populate('userId', 'name email phone');
    console.log(`[Ambulance Request] ✅ Request populated with user details`);

    // TODO: In a real system, here you would:
    // 1. Find nearest available ambulance
    // 2. Calculate ETA
    // 3. Assign ambulance
    // 4. Send notifications

    res.status(201).json({
      message: "Ambulance request created successfully",
      success: true,
      request: savedRequest,
    });
  } catch (error) {
    console.error("❌ Ambulance request creation error:", error);
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
