const express = require("express");
const jwt = require("jsonwebtoken");
const { calculateDistance } = require("../utils/distanceCalculator");

// Import all request models
const MedicalRequest = require("../models/MedicalRequest");
const BloodRequest = require("../models/BloodRequest");
const AccidentRequest = require("../models/AccidentRequest");
const AmbulanceRequest = require("../models/AmbulanceRequest");
const MechanicRequest = require("../models/MechanicRequest");
const ElectricianRequest = require("../models/ElectricianRequest");
const VolunteerRequest = require("../models/VolunteerRequest");
const FireEmergencyRequest = require("../models/FireEmergencyRequest");

const router = express.Router();

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

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

// Get all nearby requests within a radius
router.get("/nearby", authenticateToken, async (req, res) => {
  try {
    const { latitude, longitude, radius = 10 } = req.query; // radius in km, default 10km (increased from 5km)

    if (!latitude || !longitude) {
      return res.status(400).json({
        message: "Please provide latitude and longitude",
        success: false,
      });
    }

    const userLat = parseFloat(latitude);
    const userLon = parseFloat(longitude);
    const maxRadius = parseFloat(radius);

    console.log(`[Nearby Requests] User ${req.userId} searching at (${userLat}, ${userLon}) within ${maxRadius}km radius`);

    // Fetch all pending requests from all types
    const [
      medicalRequests,
      bloodRequests,
      accidentRequests,
      ambulanceRequests,
      mechanicRequests,
      electricianRequests,
      volunteerRequests,
      fireRequests,
    ] = await Promise.all([
      MedicalRequest.find({ status: 'pending' })
        .populate('userId', 'name email phone')
        .sort({ createdAt: -1 }),
      BloodRequest.find({ status: 'pending' })
        .populate('userId', 'name email phone')
        .sort({ createdAt: -1 }),
      AccidentRequest.find({ status: 'pending' })
        .populate('userId', 'name email phone')
        .sort({ createdAt: -1 }),
      AmbulanceRequest.find({ status: 'pending' })
        .populate('userId', 'name email phone')
        .sort({ createdAt: -1 }),
      MechanicRequest.find({ status: 'pending' })
        .populate('userId', 'name email phone')
        .sort({ createdAt: -1 }),
      ElectricianRequest.find({ status: 'pending' })
        .populate('userId', 'name email phone')
        .sort({ createdAt: -1 }),
      VolunteerRequest.find({ status: 'pending' })
        .populate('userId', 'name email phone')
        .sort({ createdAt: -1 }),
      FireEmergencyRequest.find({ status: 'pending' })
        .populate('userId', 'name email phone')
        .sort({ createdAt: -1 }),
    ]);

    console.log(`[Nearby Requests] Found requests: Medical=${medicalRequests.length}, Blood=${bloodRequests.length}, Accident=${accidentRequests.length}, Ambulance=${ambulanceRequests.length}, Mechanic=${mechanicRequests.length}, Electrician=${electricianRequests.length}, Volunteer=${volunteerRequests.length}, Fire=${fireRequests.length}`);

    // Combine and filter by distance
    const allRequests = [];

    // Process Medical Requests
    medicalRequests.forEach((req) => {
      if (req.location && req.location.latitude && req.location.longitude) {
        const distance = calculateDistance(
          userLat,
          userLon,
          req.location.latitude,
          req.location.longitude
        );
        console.log(`[Nearby Requests] Medical request ${req._id}: distance=${distance.toFixed(2)}km, location=(${req.location.latitude}, ${req.location.longitude})`);
        if (distance <= maxRadius) {
          allRequests.push({
            id: req._id,
            type: 'Medical Help',
            typeCode: 'medical',
            title: `Medical Help - ${req.patientCondition}`,
            description: req.description,
            distance: distance,
            location: req.location,
            userId: req.userId,
            createdAt: req.createdAt,
            data: {
              patientCondition: req.patientCondition,
              numberOfPeople: req.numberOfPeople,
              photo: req.photo,
            },
          });
        } else {
          console.log(`[Nearby Requests] Medical request ${req._id} filtered out: distance ${distance.toFixed(2)}km > maxRadius ${maxRadius}km`);
        }
      } else {
        console.log(`[Nearby Requests] Medical request ${req._id} has no valid location data`);
      }
    });

    // Process Blood Requests
    bloodRequests.forEach((req) => {
      if (req.location && req.location.latitude && req.location.longitude) {
        const distance = calculateDistance(
          userLat,
          userLon,
          req.location.latitude,
          req.location.longitude
        );
        if (distance <= maxRadius) {
          allRequests.push({
            id: req._id,
            type: 'Blood Donation',
            typeCode: 'blood',
            title: `Blood Needed - ${req.bloodGroup}`,
            description: `${req.bloodGroup} required at ${req.hospitalName}`,
            distance: distance,
            location: req.location,
            userId: req.userId,
            createdAt: req.createdAt,
            data: {
              bloodGroup: req.bloodGroup,
              hospitalName: req.hospitalName,
              patientName: req.patientName,
              unitsRequired: req.unitsRequired,
              urgencyLevel: req.urgencyLevel,
            },
          });
        }
      }
    });

    // Process Accident Requests
    accidentRequests.forEach((req) => {
      if (req.location && req.location.latitude && req.location.longitude) {
        const distance = calculateDistance(
          userLat,
          userLon,
          req.location.latitude,
          req.location.longitude
        );
        if (distance <= maxRadius) {
          allRequests.push({
            id: req._id,
            type: 'Accident Help',
            typeCode: 'accident',
            title: `Accident - ${req.accidentType}`,
            description: req.description,
            distance: distance,
            location: req.location,
            userId: req.userId,
            createdAt: req.createdAt,
            data: {
              accidentType: req.accidentType,
              numberOfInjured: req.numberOfInjured,
              photo: req.photo,
            },
          });
        }
      }
    });

    // Process Ambulance Requests
    ambulanceRequests.forEach((req) => {
      if (req.location && req.location.latitude && req.location.longitude) {
        const distance = calculateDistance(
          userLat,
          userLon,
          req.location.latitude,
          req.location.longitude
        );
        if (distance <= maxRadius) {
          allRequests.push({
            id: req._id,
            type: 'Ambulance Request',
            typeCode: 'ambulance',
            title: `Ambulance - ${req.patientCondition}`,
            description: `Patient age: ${req.patientAge}, Destination: ${req.hospitalDestination || 'Not specified'}`,
            distance: distance,
            location: req.location,
            userId: req.userId,
            createdAt: req.createdAt,
            data: {
              patientCondition: req.patientCondition,
              patientAge: req.patientAge,
              hospitalDestination: req.hospitalDestination,
              contactNumber: req.contactNumber,
            },
          });
        }
      }
    });

    // Process Mechanic Requests
    mechanicRequests.forEach((req) => {
      if (req.location && req.location.latitude && req.location.longitude) {
        const distance = calculateDistance(
          userLat,
          userLon,
          req.location.latitude,
          req.location.longitude
        );
        if (distance <= maxRadius) {
          allRequests.push({
            id: req._id,
            type: 'Mechanic Help',
            typeCode: 'mechanic',
            title: `${req.vehicleType} - ${req.problemType}`,
            description: req.description,
            distance: distance,
            location: req.location,
            userId: req.userId,
            createdAt: req.createdAt,
            data: {
              vehicleType: req.vehicleType,
              problemType: req.problemType,
            },
          });
        }
      }
    });

    // Process Electrician Requests
    electricianRequests.forEach((req) => {
      if (req.location && req.location.latitude && req.location.longitude) {
        const distance = calculateDistance(
          userLat,
          userLon,
          req.location.latitude,
          req.location.longitude
        );
        if (distance <= maxRadius) {
          allRequests.push({
            id: req._id,
            type: 'Electrician Help',
            typeCode: 'electrician',
            title: `Electrician - ${req.problemType}`,
            description: req.description,
            distance: distance,
            location: req.location,
            userId: req.userId,
            createdAt: req.createdAt,
            data: {
              problemType: req.problemType,
              photo: req.photo,
            },
          });
        }
      }
    });

    // Process Volunteer Requests
    volunteerRequests.forEach((req) => {
      if (req.location && req.location.latitude && req.location.longitude) {
        const distance = calculateDistance(
          userLat,
          userLon,
          req.location.latitude,
          req.location.longitude
        );
        if (distance <= maxRadius) {
          allRequests.push({
            id: req._id,
            type: 'Volunteer Help',
            typeCode: 'volunteer',
            title: `Volunteer - ${req.helpType}`,
            description: req.description,
            distance: distance,
            location: req.location,
            userId: req.userId,
            createdAt: req.createdAt,
            data: {
              helpType: req.helpType,
            },
          });
        }
      }
    });

    // Process Fire Emergency Requests
    fireRequests.forEach((req) => {
      if (req.location && req.location.latitude && req.location.longitude) {
        const distance = calculateDistance(
          userLat,
          userLon,
          req.location.latitude,
          req.location.longitude
        );
        if (distance <= maxRadius) {
          allRequests.push({
            id: req._id,
            type: 'Fire Emergency',
            typeCode: 'fire',
            title: `Fire - ${req.fireType} (${req.severityLevel})`,
            description: `Severity: ${req.severityLevel}`,
            distance: distance,
            location: req.location,
            userId: req.userId,
            createdAt: req.createdAt,
            data: {
              fireType: req.fireType,
              severityLevel: req.severityLevel,
              photo: req.photo,
            },
          });
        }
      }
    });

    // Sort by distance (nearest first)
    allRequests.sort((a, b) => a.distance - b.distance);

    // Exclude requests created by the current user
    const currentUserId = req.userId.toString(); // Get current user ID from token
    console.log(`[Nearby Requests] Found ${allRequests.length} total requests before filtering`);
    
    const filteredRequests = allRequests.filter((request) => {
      const requestUserId = request.userId._id ? request.userId._id.toString() : request.userId.toString();
      const isNotOwnRequest = requestUserId !== currentUserId;
      if (!isNotOwnRequest) {
        console.log(`[Nearby Requests] Filtering out own request: ${request.type} (${requestUserId})`);
      }
      return isNotOwnRequest; // Compare with current user ID
    });

    console.log(`[Nearby Requests] Returning ${filteredRequests.length} requests after filtering`);
    
    // Log first few requests for debugging
    if (filteredRequests.length > 0) {
      console.log(`[Nearby Requests] Sample request: ${JSON.stringify(filteredRequests[0], null, 2)}`);
    }

    res.status(200).json({
      success: true,
      count: filteredRequests.length,
      requests: filteredRequests,
    });
  } catch (error) {
    console.error("Get nearby requests error:", error);
    res.status(500).json({
      message: "Server error. Please try again later.",
      success: false,
      error: error.message,
    });
  }
});

// Test endpoint to check if requests exist (for debugging)
router.get("/test", authenticateToken, async (req, res) => {
  try {
    const [medicalCount, bloodCount, accidentCount, ambulanceCount, mechanicCount, electricianCount, volunteerCount, fireCount] = await Promise.all([
      MedicalRequest.countDocuments({ status: 'pending' }),
      BloodRequest.countDocuments({ status: 'pending' }),
      AccidentRequest.countDocuments({ status: 'pending' }),
      AmbulanceRequest.countDocuments({ status: 'pending' }),
      MechanicRequest.countDocuments({ status: 'pending' }),
      ElectricianRequest.countDocuments({ status: 'pending' }),
      VolunteerRequest.countDocuments({ status: 'pending' }),
      FireEmergencyRequest.countDocuments({ status: 'pending' }),
    ]);

    // Get sample requests with location
    const sampleMedical = await MedicalRequest.findOne({ status: 'pending' }).select('location createdAt');
    const sampleBlood = await BloodRequest.findOne({ status: 'pending' }).select('location createdAt');
    
    res.status(200).json({
      success: true,
      counts: {
        medical: medicalCount,
        blood: bloodCount,
        accident: accidentCount,
        ambulance: ambulanceCount,
        mechanic: mechanicCount,
        electrician: electricianCount,
        volunteer: volunteerCount,
        fire: fireCount,
        total: medicalCount + bloodCount + accidentCount + ambulanceCount + mechanicCount + electricianCount + volunteerCount + fireCount,
      },
      samples: {
        medical: sampleMedical,
        blood: sampleBlood,
      },
    });
  } catch (error) {
    console.error("Test endpoint error:", error);
    res.status(500).json({
      message: "Server error.",
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
