const mongoose = require("mongoose");

const bloodRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: [true, "User ID is required"],
  },
  bloodGroup: {
    type: String,
    required: [true, "Blood group is required"],
    enum: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
  },
  hospitalName: {
    type: String,
    required: [true, "Hospital name is required"],
    trim: true,
  },
  patientName: {
    type: String,
    required: [true, "Patient name is required"],
    trim: true,
  },
  unitsRequired: {
    type: Number,
    required: [true, "Units required is required"],
    min: 1,
  },
  urgencyLevel: {
    type: String,
    required: [true, "Urgency level is required"],
    enum: ['Normal', 'Urgent', 'Critical'],
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

module.exports = mongoose.model("BloodRequest", bloodRequestSchema);
