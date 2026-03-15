const express = require("express");
const MedicalRequest = require("../models/MedicalRequest");
const BloodRequest = require("../models/BloodRequest");
const AccidentRequest = require("../models/AccidentRequest");
const AmbulanceRequest = require("../models/AmbulanceRequest");
const MechanicRequest = require("../models/MechanicRequest");
const ElectricianRequest = require("../models/ElectricianRequest");
const VolunteerRequest = require("../models/VolunteerRequest");
const FireEmergencyRequest = require("../models/FireEmergencyRequest");
const User = require("../models/User");
const jwt = require("jsonwebtoken");
const calculateDistance = require("../utils/distanceCalculator");

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

// Get accepted helpers for user's latest active request
router.get("/my-latest-request/helpers", authenticateToken, async (req, res) => {
  try {
    const { latitude, longitude } = req.query;
    const userLat = latitude ? parseFloat(latitude) : null;
    const userLon = longitude ? parseFloat(longitude) : null;

    // Find the latest active request from any request type
    const requestModels = [
      { model: MedicalRequest, type: 'Medical' },
      { model: BloodRequest, type: 'Blood Donation' },
      { model: AccidentRequest, type: 'Accident' },
      { model: AmbulanceRequest, type: 'Ambulance' },
      { model: MechanicRequest, type: 'Mechanic' },
      { model: ElectricianRequest, type: 'Electrician' },
      { model: VolunteerRequest, type: 'Volunteer' },
      { model: FireEmergencyRequest, type: 'Fire Emergency' },
    ];

    let latestRequest = null;
    let latestRequestType = null;

    // Find the most recent request with accepted helpers
    for (const { model, type } of requestModels) {
      const requests = await model.find({
        userId: req.userId,
        status: { $in: ['pending', 'accepted', 'in_progress'] },
        acceptedBy: { $exists: true, $ne: [] }
      })
        .sort({ createdAt: -1 })
        .limit(1);

      if (requests.length > 0) {
        const request = requests[0];
        if (!latestRequest || request.createdAt > latestRequest.createdAt) {
          latestRequest = request;
          latestRequestType = type;
        }
      }
    }

    if (!latestRequest || !latestRequest.acceptedBy || latestRequest.acceptedBy.length === 0) {
      return res.status(200).json({
        success: true,
        helpers: [],
        request: null,
        message: "No active requests with accepted helpers found",
      });
    }

    // Populate accepted helpers with user details
    await latestRequest.populate('acceptedBy', 'name email phone bloodGroup skill locationAllowed');

    // Get helpers with their locations and calculate distances
    const helpers = [];
    for (const helper of latestRequest.acceptedBy) {
      const helperData = {
        id: helper._id.toString(),
        name: helper.name,
        phone: helper.phone || '',
        email: helper.email || '',
        bloodGroup: helper.bloodGroup || '',
        skill: helper.skill || '',
        status: 'Accepted', // Default status
      };

      // Calculate distance if user location is provided
      if (userLat && userLon && latestRequest.location) {
        const distance = calculateDistance(
          userLat,
          userLon,
          latestRequest.location.latitude,
          latestRequest.location.longitude
        );
        helperData.distance = distance < 1 
          ? `${Math.round(distance * 1000)}m` 
          : `${distance.toFixed(1)} km`;
        helperData.distanceKm = distance;
      } else {
        helperData.distance = 'Unknown';
        helperData.distanceKm = null;
      }

      // For now, we'll use the request location with small offset for visualization
      // In a real app, helpers would have their own current location from their device
      if (latestRequest.location) {
        // Add small random offset to show helpers as separate markers
        const offset = (helpers.length * 0.002) - (helpers.length * 0.001); // Spread helpers around
        helperData.latitude = latestRequest.location.latitude + (Math.random() * 0.01 - 0.005);
        helperData.longitude = latestRequest.location.longitude + (Math.random() * 0.01 - 0.005);
      }

      helpers.push(helperData);
    }

    // Sort by distance if available
    helpers.sort((a, b) => {
      if (a.distanceKm == null) return 1;
      if (b.distanceKm == null) return -1;
      return a.distanceKm - b.distanceKm;
    });

    res.status(200).json({
      success: true,
      helpers,
      request: {
        id: latestRequest._id.toString(),
        type: latestRequestType,
        location: latestRequest.location,
        createdAt: latestRequest.createdAt,
      },
    });
  } catch (error) {
    console.error("Get accepted helpers error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Get accepted helpers for a specific request
router.get("/:requestType/:requestId/helpers", authenticateToken, async (req, res) => {
  try {
    const { requestType, requestId } = req.params;
    const { latitude, longitude } = req.query;
    const userLat = latitude ? parseFloat(latitude) : null;
    const userLon = longitude ? parseFloat(longitude) : null;

    // Map request type to model
    const modelMap = {
      'medical': MedicalRequest,
      'blood': BloodRequest,
      'accident': AccidentRequest,
      'ambulance': AmbulanceRequest,
      'mechanic': MechanicRequest,
      'electrician': ElectricianRequest,
      'volunteer': VolunteerRequest,
      'fire': FireEmergencyRequest,
    };

    const RequestModel = modelMap[requestType.toLowerCase()];
    if (!RequestModel) {
      return res.status(400).json({
        message: "Invalid request type",
        success: false,
      });
    }

    const request = await RequestModel.findById(requestId);
    if (!request) {
      return res.status(404).json({
        message: "Request not found",
        success: false,
      });
    }

    // Check if user owns this request
    if (request.userId.toString() !== req.userId.toString()) {
      return res.status(403).json({
        message: "Access denied. You can only view helpers for your own requests.",
        success: false,
      });
    }

    if (!request.acceptedBy || request.acceptedBy.length === 0) {
      return res.status(200).json({
        success: true,
        helpers: [],
        request: {
          id: request._id.toString(),
          location: request.location,
        },
      });
    }

    // Populate accepted helpers
    await request.populate('acceptedBy', 'name email phone bloodGroup skill locationAllowed');

    // Get helpers with distances
    const helpers = [];
    for (const helper of request.acceptedBy) {
      const helperData = {
        id: helper._id.toString(),
        name: helper.name,
        phone: helper.phone || '',
        email: helper.email || '',
        bloodGroup: helper.bloodGroup || '',
        skill: helper.skill || '',
        status: 'Accepted',
      };

      // Calculate distance
      if (userLat && userLon && request.location) {
        const distance = calculateDistance(
          userLat,
          userLon,
          request.location.latitude,
          request.location.longitude
        );
        helperData.distance = distance < 1 
          ? `${Math.round(distance * 1000)}m` 
          : `${distance.toFixed(1)} km`;
        helperData.distanceKm = distance;
      } else {
        helperData.distance = 'Unknown';
        helperData.distanceKm = null;
      }

      // Use request location with small offset for visualization
      // In a real app, get helper's current location from their device
      if (request.location) {
        // Add small random offset to show helpers as separate markers
        const offset = (helpers.length * 0.002) - (helpers.length * 0.001);
        helperData.latitude = request.location.latitude + (Math.random() * 0.01 - 0.005);
        helperData.longitude = request.location.longitude + (Math.random() * 0.01 - 0.005);
      }

      helpers.push(helperData);
    }

    // Sort by distance
    helpers.sort((a, b) => {
      if (a.distanceKm == null) return 1;
      if (b.distanceKm == null) return -1;
      return a.distanceKm - b.distanceKm;
    });

    res.status(200).json({
      success: true,
      helpers,
      request: {
        id: request._id.toString(),
        location: request.location,
        createdAt: request.createdAt,
      },
    });
  } catch (error) {
    console.error("Get accepted helpers error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
