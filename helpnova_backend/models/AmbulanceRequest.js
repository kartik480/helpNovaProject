const mongoose = require("mongoose");

const ambulanceRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: [true, "User ID is required"],
  },
  patientCondition: {
    type: String,
    required: [true, "Patient condition is required"],
    enum: ['Critical', 'Serious', 'Stable'],
  },
  patientAge: {
    type: Number,
    required: [true, "Patient age is required"],
    min: 0,
    max: 150,
  },
  pickupLocation: {
    latitude: {
      type: Number,
      required: [true, "Pickup latitude is required"],
    },
    longitude: {
      type: Number,
      required: [true, "Pickup longitude is required"],
    },
  },
  hospitalDestination: {
    type: String,
    default: null,
    trim: true,
  },
  contactNumber: {
    type: String,
    required: [true, "Contact number is required"],
    trim: true,
  },
  status: {
    type: String,
    enum: ['pending', 'assigned', 'in_transit', 'arrived', 'completed', 'cancelled'],
    default: 'pending',
  },
  assignedAmbulance: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    default: null,
  },
  eta: {
    type: Number, // Estimated time of arrival in minutes
    default: null,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model("AmbulanceRequest", ambulanceRequestSchema);
