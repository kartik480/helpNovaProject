const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, "Name is required"],
    trim: true
  },
  email: {
    type: String,
    required: [true, "Email is required"],
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: [true, "Password is required"],
    minlength: 6
  },
  phone: {
    type: String,
    required: [true, "Phone number is required"],
    trim: true
  },
  bloodGroup: {
    type: String,
    required: [true, "Blood group is required"],
    trim: true
  },
  skill: {
    type: String,
    required: [true, "Skill is required"],
    trim: true
  },
  locationAllowed: {
    type: Boolean,
    default: false
  },
  fcmToken: {
    type: String,
    default: null,
    trim: true
  },
  location: {
    latitude: {
      type: Number,
      default: null
    },
    longitude: {
      type: Number,
      default: null
    },
    lastUpdated: {
      type: Date,
      default: null
    }
  }
}, {
  timestamps: true
});

module.exports = mongoose.model("User", userSchema);