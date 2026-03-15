const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');

/**
 * Get OAuth2 access token for Firebase Cloud Messaging V1 API
 */
async function getAccessToken() {
  try {
    // Get service account credentials from environment variable
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
    
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable is not set');
    }

    // Parse the JSON string (if stored as string) or use directly
    let credentials;
    try {
      credentials = typeof serviceAccountJson === 'string' 
        ? JSON.parse(serviceAccountJson) 
        : serviceAccountJson;
    } catch (e) {
      throw new Error('Invalid FIREBASE_SERVICE_ACCOUNT JSON format');
    }

    // Create GoogleAuth instance with service account credentials
    const auth = new GoogleAuth({
      credentials: credentials,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });

    // Get access token
    const client = await auth.getClient();
    const accessToken = await client.getAccessToken();

    if (!accessToken.token) {
      throw new Error('Failed to obtain access token');
    }

    return accessToken.token;
  } catch (error) {
    console.error('Error getting access token:', error.message);
    throw error;
  }
}

/**
 * Get Firebase Project ID from service account
 */
function getProjectId() {
  try {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
    
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable is not set');
    }

    let credentials;
    try {
      credentials = typeof serviceAccountJson === 'string' 
        ? JSON.parse(serviceAccountJson) 
        : serviceAccountJson;
    } catch (e) {
      throw new Error('Invalid FIREBASE_SERVICE_ACCOUNT JSON format');
    }

    return credentials.project_id;
  } catch (error) {
    console.error('Error getting project ID:', error.message);
    throw error;
  }
}

/**
 * Send FCM notification using V1 API
 * @param {string} fcmToken - The FCM token of the recipient
 * @param {object} notification - Notification payload {title, body}
 * @param {object} data - Data payload (key-value pairs)
 * @returns {Promise<object>} Response from FCM API
 */
async function sendFCMNotification(fcmToken, notification, data) {
  try {
    // Get access token and project ID
    const accessToken = await getAccessToken();
    const projectId = getProjectId();

    // V1 API endpoint
    const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    // V1 API message format
    const message = {
      message: {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: Object.keys(data).reduce((acc, key) => {
          // V1 API requires all data values to be strings
          acc[key] = String(data[key]);
          return acc;
        }, {}),
        android: {
          priority: 'high',
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
        },
      },
    };

    // Send notification
    const response = await axios.post(url, message, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      timeout: 10000, // 10 seconds timeout
    });

    return {
      success: true,
      response: response.data,
    };
  } catch (error) {
    console.error('Error sending FCM notification:', error.message);
    
    if (error.response) {
      console.error('FCM API Error:', error.response.data);
      return {
        success: false,
        error: error.response.data.error?.message || error.message,
        status: error.response.status,
      };
    }

    return {
      success: false,
      error: error.message,
    };
  }
}

module.exports = {
  getAccessToken,
  getProjectId,
  sendFCMNotification,
};
