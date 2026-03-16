const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGO_URI || process.env.MONGODB_URI || "mongodb://127.0.0.1:27017/helpnova";
    console.log(`[Database] Attempting to connect to MongoDB...`);
    console.log(`[Database] Connection string: ${mongoURI.replace(/\/\/[^:]+:[^@]+@/, '//***:***@')}`); // Hide credentials in logs
    
    const conn = await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    console.log(`[Database] ✅ MongoDB Connected: ${conn.connection.host}`);
    console.log(`[Database] ✅ Database Name: ${conn.connection.name}`);
    
    // Monitor connection events
    mongoose.connection.on('error', (err) => {
      console.error(`[Database] ❌ MongoDB connection error:`, err);
    });
    
    mongoose.connection.on('disconnected', () => {
      console.warn(`[Database] ⚠️ MongoDB disconnected`);
    });
    
    mongoose.connection.on('reconnected', () => {
      console.log(`[Database] ✅ MongoDB reconnected`);
    });
    
  } catch (error) {
    console.error("❌ MongoDB connection error:", error);
    console.error("❌ Error details:", error.message);
    process.exit(1);
  }
};

// Helper function to check if database is connected
const isConnected = () => {
  return mongoose.connection.readyState === 1; // 1 = connected
};

module.exports = { connectDB, isConnected };