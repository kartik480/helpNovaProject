const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const connectDB = require("./config/db");

// Load environment variables
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Middleware
// CORS configuration - allows requests from any origin (for mobile apps)
app.use(cors({
  origin: '*', // In production, you might want to restrict this to your app's domain
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/medical", require("./routes/medicalRoutes"));
app.use("/api/blood", require("./routes/bloodRoutes"));
app.use("/api/accident", require("./routes/accidentRoutes"));
app.use("/api/ambulance", require("./routes/ambulanceRoutes"));
app.use("/api/mechanic", require("./routes/mechanicRoutes"));
app.use("/api/electrician", require("./routes/electricianRoutes"));
app.use("/api/volunteer", require("./routes/volunteerRoutes"));
app.use("/api/fire", require("./routes/fireEmergencyRoutes"));
app.use("/api/nearby", require("./routes/nearbyRoutes"));
app.use("/api/helpers", require("./routes/acceptedHelpersRoutes"));
app.use("/api/emergency", require("./routes/emergencyRoutes"));

// Health check endpoint
app.get("/", (req, res) => {
  res.json({ message: "Help Nova Backend API is running!" });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: "Something went wrong!", error: err.message });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
