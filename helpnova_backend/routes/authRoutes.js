const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

const router = express.Router();

// Generate JWT Token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET || "your-secret-key", {
    expiresIn: "30d",
  });
};

// SIGNUP
router.post("/signup", async (req, res) => {
  const { name, email, password, phone, bloodGroup, skill, locationAllowed } = req.body;

  // Validation
  if (!name || !email || !password || !phone || !bloodGroup || !skill) {
    return res.status(400).json({ 
      message: "Please provide all required fields",
      success: false 
    });
  }

  // Email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ 
      message: "Please provide a valid email address",
      success: false 
    });
  }

  // Password validation
  if (password.length < 6) {
    return res.status(400).json({ 
      message: "Password must be at least 6 characters long",
      success: false 
    });
  }

  try {
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ 
        message: "User with this email already exists",
        success: false 
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = new User({
      name,
      email,
      password: hashedPassword,
      phone,
      bloodGroup,
      skill,
      locationAllowed: locationAllowed || false
    });

    await user.save();

    // Generate token
    const token = generateToken(user._id);

    // Return user data (without password) and token
    res.status(201).json({ 
      message: "User registered successfully",
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        bloodGroup: user.bloodGroup,
        skill: user.skill,
        locationAllowed: user.locationAllowed
      }
    });

  } catch (error) {
    console.error("Signup error:", error);
    
    // Handle specific MongoDB errors
    if (error.name === 'MongoServerError' && error.code === 11000) {
      return res.status(400).json({ 
        message: "User with this email already exists",
        success: false 
      });
    }
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({ 
        message: errors.join(', '),
        success: false 
      });
    }
    
    res.status(500).json({ 
      message: error.message || "Server error. Please try again later.",
      success: false,
      error: error.message 
    });
  }
});

// LOGIN
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  // Validation
  if (!email || !password) {
    return res.status(400).json({ 
      message: "Please provide email and password",
      success: false 
    });
  }

  try {
    // Find user by email
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(401).json({ 
        message: "Invalid email or password",
        success: false 
      });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ 
        message: "Invalid email or password",
        success: false 
      });
    }

    // Generate token
    const token = generateToken(user._id);

    // Return user data (without password) and token
    res.json({ 
      message: "Login successful",
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        bloodGroup: user.bloodGroup,
        skill: user.skill,
        locationAllowed: user.locationAllowed
      }
    });

  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ 
      message: "Server error. Please try again later.",
      success: false,
      error: error.message 
    });
  }
});

// Get user profile (protected route)
router.get("/profile", async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
      return res.status(401).json({ 
        message: "No token provided",
        success: false 
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key");
    const user = await User.findById(decoded.userId).select("-password");

    if (!user) {
      return res.status(404).json({ 
        message: "User not found",
        success: false 
      });
    }

    res.json({ 
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        bloodGroup: user.bloodGroup,
        skill: user.skill,
        locationAllowed: user.locationAllowed
      }
    });

  } catch (error) {
    console.error("Profile error:", error);
    res.status(401).json({ 
      message: "Invalid or expired token",
      success: false 
    });
  }
});

// Update FCM Token (protected route)
router.post("/update-fcm-token", async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
      return res.status(401).json({ 
        message: "No token provided",
        success: false 
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key");
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ 
        message: "FCM token is required",
        success: false 
      });
    }

    const user = await User.findByIdAndUpdate(
      decoded.userId,
      { fcmToken: fcmToken },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ 
        message: "User not found",
        success: false 
      });
    }

    res.json({ 
      success: true,
      message: "FCM token updated successfully"
    });

  } catch (error) {
    console.error("Update FCM token error:", error);
    res.status(401).json({ 
      message: "Invalid or expired token",
      success: false 
    });
  }
});

// Update User Location (protected route)
router.post("/update-location", async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
      return res.status(401).json({ 
        message: "No token provided",
        success: false 
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key");
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ 
        message: "Latitude and longitude are required",
        success: false 
      });
    }

    // Validate coordinates
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return res.status(400).json({ 
        message: "Invalid coordinates",
        success: false 
      });
    }

    const user = await User.findByIdAndUpdate(
      decoded.userId,
      { 
        locationAllowed: true, // Set to true when user updates location (they're allowing location sharing)
        location: {
          latitude: latitude,
          longitude: longitude,
          lastUpdated: new Date()
        }
      },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ 
        message: "User not found",
        success: false 
      });
    }

    res.json({ 
      success: true,
      message: "Location updated successfully"
    });

  } catch (error) {
    console.error("Update location error:", error);
    res.status(401).json({ 
      message: "Invalid or expired token",
      success: false 
    });
  }
});

// Get all active users with location enabled (for displaying on map)
router.get("/active-users", async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
      return res.status(401).json({ 
        message: "No token provided",
        success: false 
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key");
    
    // Get current user's location if available
    const currentUser = await User.findById(decoded.userId).select("location");
    const userLat = currentUser?.location?.latitude;
    const userLon = currentUser?.location?.longitude;

    // Find all users with location enabled and valid coordinates
    // Only include users who updated location within the last 1 hour (active users)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000); // 1 hour ago

    const activeUsers = await User.find({
      _id: { $ne: decoded.userId }, // Exclude current user
      locationAllowed: true, // Only users who allow location sharing
      'location.latitude': { $ne: null, $exists: true }, // Only users with valid latitude
      'location.longitude': { $ne: null, $exists: true }, // Only users with valid longitude
      $or: [
        { 'location.lastUpdated': { $gte: oneHourAgo } }, // Updated within last hour
        { 'location.lastUpdated': null }, // Or never updated (newly enabled)
        { 'location.lastUpdated': { $exists: false } } // Or field doesn't exist
      ]
    }).select("name phone location locationAllowed").limit(100); // Limit to 100 users for performance

    // Format response
    const usersList = activeUsers.map(user => ({
      id: user._id.toString(),
      name: user.name,
      phone: user.phone,
      latitude: user.location?.latitude,
      longitude: user.location?.longitude,
      lastUpdated: user.location?.lastUpdated,
      locationAllowed: user.locationAllowed
    }));

    console.log(`[Active Users] Found ${usersList.length} active users with location enabled`);

    res.json({
      success: true,
      users: usersList,
      count: usersList.length,
      currentUserLocation: userLat && userLon ? {
        latitude: userLat,
        longitude: userLon
      } : null
    });

  } catch (error) {
    console.error("Get active users error:", error);
    res.status(401).json({ 
      message: "Invalid or expired token",
      success: false,
      error: error.message 
    });
  }
});

module.exports = router;