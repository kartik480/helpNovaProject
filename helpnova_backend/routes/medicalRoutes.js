const express = require("express");
const MedicalRequest = require("../models/MedicalRequest");
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

// Create a new medical emergency request
router.post("/create", authenticateToken, async (req, res) => {
  try {
    const { patientCondition, description, numberOfPeople, photo, location } = req.body;

    // Validation
    if (!patientCondition || !description || !numberOfPeople || !location) {
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

    // Create medical request
    const medicalRequest = new MedicalRequest({
      userId: req.userId,
      patientCondition,
      description,
      numberOfPeople: parseInt(numberOfPeople),
      photo: photo || null,
      location: {
        latitude: parseFloat(location.latitude),
        longitude: parseFloat(location.longitude),
      },
      status: 'pending',
    });

    await medicalRequest.save();

    // Populate user details
    await medicalRequest.populate('userId', 'name email phone');

    res.status(201).json({
      message: "Medical emergency request created successfully",
      success: true,
      request: medicalRequest,
    });
  } catch (error) {
    console.error("Medical request creation error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get all medical requests (for nearby volunteers/doctors)
router.get("/all", authenticateToken, async (req, res) => {
  try {
    const requests = await MedicalRequest.find({ status: 'pending' })
      .populate('userId', 'name email phone bloodGroup skill')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get medical requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get user's own medical requests
router.get("/my-requests", authenticateToken, async (req, res) => {
  try {
    const requests = await MedicalRequest.find({ userId: req.userId })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests,
    });
  } catch (error) {
    console.error("Get my medical requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Accept a medical request (for volunteers/doctors)
router.post("/:requestId/accept", authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const medicalRequest = await MedicalRequest.findById(requestId);

    if (!medicalRequest) {
      return res.status(404).json({
        message: "Medical request not found",
        success: false,
      });
    }

    // Check if already accepted by this user
    if (medicalRequest.acceptedBy.includes(req.userId)) {
      return res.status(400).json({
        message: "You have already accepted this request",
        success: false,
      });
    }

    // Add user to acceptedBy array
    medicalRequest.acceptedBy.push(req.userId);
    
    // Update status if first acceptance
    if (medicalRequest.status === 'pending') {
      medicalRequest.status = 'accepted';
    }

    await medicalRequest.save();

    res.status(200).json({
      message: "Medical request accepted successfully",
      success: true,
      request: medicalRequest,
    });
  } catch (error) {
    console.error("Accept medical request error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
