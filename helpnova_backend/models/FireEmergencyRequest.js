const mongoose = require("mongoose");

const fireEmergencyRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: [true, "User ID is required"],
  },
  fireType: {
    type: String,
    required: [true, "Fire type is required"],
    enum: ['House Fire', 'Vehicle Fire', 'Gas Leak', 'Other'],
  },
  severityLevel: {
    type: String,
    required: [true, "Severity level is required"],
    enum: ['Low', 'Medium', 'High'],
  },
  photo: {
    type: String, // URL or path to the uploaded photo
    default: null,
  },
  location: {
    latitude: {
      type: Number,
      required: [true, "Latitude is required"],
    },
    longitude: {
      type: Number,
      required: [true, "Longitude is required"],
    },
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'in_progress', 'completed', 'cancelled'],
    default: 'pending',
  },
  acceptedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  }],
}, {
  timestamps: true,
});

module.exports = mongoose.model("FireEmergencyRequest", fireEmergencyRequestSchema);
