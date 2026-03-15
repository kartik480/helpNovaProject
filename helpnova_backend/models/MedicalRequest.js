const mongoose = require("mongoose");

const medicalRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: [true, "User ID is required"],
  },
  patientCondition: {
    type: String,
    required: [true, "Patient condition is required"],
    enum: ['Fainted', 'Chest pain', 'Injury', 'Breathing problem', 'Other'],
  },
  description: {
    type: String,
    required: [true, "Description is required"],
    trim: true,
  },
  numberOfPeople: {
    type: Number,
    required: [true, "Number of people is required"],
    min: 1,
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

module.exports = mongoose.model("MedicalRequest", medicalRequestSchema);
