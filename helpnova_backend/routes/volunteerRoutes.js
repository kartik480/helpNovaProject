const express = require("express");
const VolunteerRequest = require("../models/VolunteerRequest");
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

// Create a new volunteer request
router.post("/create", authenticateToken, async (req, res) => {
  try {
    const { helpType, description, location } = req.body;

    // Validation
    if (!helpType || !description || !location) {
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

    // Create volunteer request
    const volunteerRequest = new VolunteerRequest({
      userId: req.userId,
      helpType,
      description,
      location: {
        latitude: parseFloat(location.latitude),
        longitude: parseFloat(location.longitude),
      },
      status: 'pending',
    });

    await volunteerRequest.save();

    // Populate user details
    await volunteerRequest.populate('userId', 'name email phone');

    res.status(201).json({
      message: "Volunteer request created successfully",
      success: true,
      request: volunteerRequest,
    });
  } catch (error) {
    console.error("Volunteer request creation error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get all volunteer requests (for nearby volunteers)
router.get("/all", authenticateToken, async (req, res) => {
  try {
    const requests = await VolunteerRequest.find({ status: 'pending' })
      .populate('userId', 'name email phone')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get volunteer requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get user's own volunteer requests
router.get("/my-requests", authenticateToken, async (req, res) => {
  try {
    const requests = await VolunteerRequest.find({ userId: req.userId })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get my volunteer requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Accept a volunteer request (for volunteers)
router.post("/:requestId/accept", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const volunteerRequest = await VolunteerRequest.findById(requestId);

    if (!volunteerRequest) {
      return res.status(404).json({
        message: "Volunteer request not found",
        success: false,
      });
    }

    // Check if already accepted by this user
    if (volunteerRequest.acceptedBy.includes(req.userId)) {
      return res.status(400).json({
        message: "You have already accepted this request",
        success: false,
      });
    }

    // Add user to acceptedBy array
    volunteerRequest.acceptedBy.push(req.userId);
    
    // Update status if first acceptance
    if (volunteerRequest.status === 'pending') {
      volunteerRequest.status = 'accepted';
    }

    await volunteerRequest.save();

    res.status(200).json({
      message: "Volunteer request accepted successfully",
      success: true,
      request: volunteerRequest,
    });
  } catch (error) {
    console.error("Accept volunteer request error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
