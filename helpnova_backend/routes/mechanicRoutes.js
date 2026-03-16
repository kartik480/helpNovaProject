const express = require("express");
const MechanicRequest = require("../models/MechanicRequest");
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

// Create a new mechanic request
router.post("/create", authenticateToken, async (req, res) => {
  try {
    // Check database connection
    const mongoose = require("mongoose");
    if (mongoose.connection.readyState !== 1) {
      console.error(`[Mechanic Request] ❌ Database not connected!`);
      return res.status(503).json({
        message: "Database connection unavailable. Please try again later.",
        success: false,
      });
    }
    
    console.log(`[Mechanic Request] Creating request for user ${req.userId}`);
    console.log(`[Mechanic Request] Request body:`, JSON.stringify(req.body, null, 2));
    
    const { vehicleType, problemType, description, location } = req.body;

    // Validation
    if (!vehicleType || !problemType || !description || !location) {
      console.log(`[Mechanic Request] Validation failed - missing fields`);
      return res.status(400).json({
        message: "Please provide all required fields",
        success: false,
      });
    }

    if (!location.latitude || !location.longitude) {
      console.log(`[Mechanic Request] Validation failed - invalid location`);
      return res.status(400).json({
        message: "Please provide valid location coordinates",
        success: false,
      });
    }

    // Create mechanic request
    const mechanicRequest = new MechanicRequest({
      userId: req.userId,
      vehicleType,
      problemType,
      description,
      location: {
        latitude: parseFloat(location.latitude),
        longitude: parseFloat(location.longitude),
      },
      status: 'pending',
    });

    console.log(`[Mechanic Request] Attempting to save request to database...`);
    const savedRequest = await mechanicRequest.save();
    console.log(`[Mechanic Request] ✅ Request saved successfully with ID: ${savedRequest._id}`);

    // Populate user details
    await savedRequest.populate('userId', 'name email phone');
    console.log(`[Mechanic Request] ✅ Request populated with user details`);

    res.status(201).json({
      message: "Mechanic request created successfully",
      success: true,
      request: savedRequest,
    });
  } catch (error) {
    console.error("❌ Mechanic request creation error:", error);
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

// Get all mechanic requests (for nearby mechanics)
router.get("/all", authenticateToken, async (req, res) => {
  try {
    const requests = await MechanicRequest.find({ status: 'pending' })
      .populate('userId', 'name email phone')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get mechanic requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get user's own mechanic requests
router.get("/my-requests", authenticateToken, async (req, res) => {
  try {
    const requests = await MechanicRequest.find({ userId: req.userId })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get my mechanic requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Accept a mechanic request (for mechanics)
router.post("/:requestId/accept", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const mechanicRequest = await MechanicRequest.findById(requestId);

    if (!mechanicRequest) {
      return res.status(404).json({
        message: "Mechanic request not found",
        success: false,
      });
    }

    // Check if already accepted by this user
    if (mechanicRequest.acceptedBy.includes(req.userId)) {
      return res.status(400).json({
        message: "You have already accepted this request",
        success: false,
      });
    }

    // Add user to acceptedBy array
    mechanicRequest.acceptedBy.push(req.userId);
    
    // Update status if first acceptance
    if (mechanicRequest.status === 'pending') {
      mechanicRequest.status = 'accepted';
    }

    await mechanicRequest.save();

    res.status(200).json({
      message: "Mechanic request accepted successfully",
      success: true,
      request: mechanicRequest,
    });
  } catch (error) {
    console.error("Accept mechanic request error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
