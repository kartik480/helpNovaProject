# Help Nova Backend

Node.js/Express backend API for the Help Nova Flutter application.

## Features

- User authentication (Signup/Login)
- JWT token-based authentication
- MongoDB database integration
- Password hashing with bcrypt
- RESTful API endpoints

## Setup Instructions

### Prerequisites

- Node.js (v14 or higher)
- MongoDB (running locally or MongoDB Atlas)

### Installation

1. Navigate to the backend directory:
```bash
cd helpnova_backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the `helpnova_backend` directory:
```env
PORT=5000
MONGO_URI=mongodb://127.0.0.1:27017/helpnova
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

4. Make sure MongoDB is running on your system.

5. Start the server:
```bash
node index.js
```

The server will start on `http://localhost:5000`

## API Endpoints

### Authentication

#### POST `/api/auth/signup`
Register a new user.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "jwt-token-here",
  "user": {
    "id": "user-id",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "1234567890"
  }
}
```

#### POST `/api/auth/login`
Login with email and password.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "jwt-token-here",
  "user": {
    "id": "user-id",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "1234567890"
  }
}
```

#### GET `/api/auth/profile`
Get user profile (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "user-id",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "1234567890"
  }
}
```

## Flutter App Configuration

In the Flutter app, update the `baseUrl` in `lib/services/api_service.dart`:

- **Android Emulator**: `http://10.0.2.2:5000/api`
- **iOS Simulator**: `http://localhost:5000/api`
- **Physical Device**: `http://<your-computer-ip>:5000/api`

To find your computer's IP address:
- Windows: `ipconfig` in Command Prompt
- Mac/Linux: `ifconfig` in Terminal
