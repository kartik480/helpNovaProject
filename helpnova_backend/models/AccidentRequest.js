const mongoose = require("mongoose");

const accidentRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: [true, "User ID is required"],
  },
  accidentType: {
    type: String,
    required: [true, "Accident type is required"],
    enum: ['Bike', 'Car', 'Pedestrian', 'Other'],
  },
  numberOfInjured: {
    type: Number,
    required: [true, "Number of injured persons is required"],
    min: 0,
  },
  description: {
    type: String,
    required: [true, "Description is required"],
    trim: true,
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

module.exports = mongoose.model("AccidentRequest", accidentRequestSchema);
