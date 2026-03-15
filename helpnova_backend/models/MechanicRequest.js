const mongoose = require("mongoose");

const mechanicRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: [true, "User ID is required"],
  },
  vehicleType: {
    type: String,
    required: [true, "Vehicle type is required"],
    enum: ['Bike', 'Car', 'Truck', 'Other'],
  },
  problemType: {
    type: String,
    required: [true, "Problem type is required"],
    enum: ['Flat Tire', 'Engine Issue', 'Battery Dead', 'Other'],
  },
  description: {
    type: String,
    required: [true, "Description is required"],
    trim: true,
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

module.exports = mongoose.model("MechanicRequest", mechanicRequestSchema);
