const mongoose = require("mongoose");

const electricianRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: [true, "User ID is required"],
  },
  problemType: {
    type: String,
    required: [true, "Problem type is required"],
    enum: ['Short Circuit', 'Power Failure', 'Burning Smell', 'Other'],
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

module.exports = mongoose.model("ElectricianRequest", electricianRequestSchema);
