const mongoose = require("mongoose");

const emergencyRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: [true, "User ID is required"],
    index: true
  },
  userName: {
    type: String,
    required: [true, "User name is required"],
    trim: true
  },
  userPhone: {
    type: String,
    required: [true, "User phone is required"],
    trim: true
  },
  type: {
    type: String,
    default: "emergency_sos",
    enum: ["emergency_sos", "accident", "medical", "fire", "other"],
    required: true
  },
  location: {
    latitude: {
      type: Number,
      required: [true, "Latitude is required"]
    },
    longitude: {
      type: Number,
      required: [true, "Longitude is required"]
    },
    address: {
      type: String,
      default: null,
      trim: true
    }
  },
  description: {
    type: String,
    default: "Emergency SOS request",
    trim: true
  },
  status: {
    type: String,
    enum: ["active", "resolved", "cancelled"],
    default: "active",
    index: true
  },
  acceptedHelpers: [{
    helperId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    },
    helperName: {
      type: String,
      required: true
    },
    helperPhone: {
      type: String,
      required: true
    },
    acceptedAt: {
      type: Date,
      default: Date.now
    },
    distance: {
      type: Number,
      default: null
    }
  }],
  notifiedUsers: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    },
    notifiedAt: {
      type: Date,
      default: Date.now
    }
  }],
  resolvedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

// Index for location-based queries
emergencyRequestSchema.index({ 
  "location.latitude": 1, 
  "location.longitude": 1 
});

// Index for active requests
emergencyRequestSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model("EmergencyRequest", emergencyRequestSchema);
