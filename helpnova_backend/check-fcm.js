/**
 * Quick script to check if Firebase Service Account is configured
 * Run: node check-fcm.js
 */

console.log('🔍 Checking Firebase Service Account Configuration...\n');

// Check if .env file exists
const fs = require('fs');
const path = require('path');
const envPath = path.join(__dirname, '.env');

if (!fs.existsSync(envPath)) {
  console.log('❌ .env file not found!');
  console.log('   Location: helpnova_backend/.env');
  console.log('\n📝 To create it:');
  console.log('   1. Get Firebase Service Account JSON from Firebase Console');
  console.log('   2. Run: node setup-env.js');
  process.exit(1);
}

// Try to load environment variables
try {
  require('dotenv').config({ path: envPath });
} catch (e) {
  console.log('⚠️  dotenv package not found. Install it: npm install dotenv');
  console.log('   Or check .env file manually\n');
}

// Check if FIREBASE_SERVICE_ACCOUNT is set
const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccount) {
  console.log('❌ FIREBASE_SERVICE_ACCOUNT is NOT set in .env file');
  console.log('\n📝 To set it up:');
  console.log('   1. Go to Firebase Console: https://console.firebase.google.com/');
  console.log('   2. Project Settings → Service Accounts');
  console.log('   3. Generate new private key');
  console.log('   4. Save JSON to: helpnova_backend/service-account.json');
  console.log('   5. Run: node setup-env.js');
  process.exit(1);
}

console.log('✅ FIREBASE_SERVICE_ACCOUNT is set');

// Try to parse it
let isValid = false;
let projectId = null;
let errorMessage = null;

try {
  const credentials = typeof serviceAccount === 'string' 
    ? JSON.parse(serviceAccount) 
    : serviceAccount;
  
  projectId = credentials.project_id;
  isValid = true;
  console.log('✅ JSON format is valid');
  console.log(`✅ Project ID: ${projectId}`);
} catch (e) {
  isValid = false;
  errorMessage = e.message;
  console.log('❌ Invalid JSON format:', errorMessage);
  console.log('\n💡 Make sure the JSON is on one line with no line breaks');
  process.exit(1);
}

// Try to get access token (if google-auth-library is available)
try {
  const { GoogleAuth } = require('google-auth-library');
  const auth = new GoogleAuth({
    credentials: typeof serviceAccount === 'string' ? JSON.parse(serviceAccount) : serviceAccount,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  
  console.log('\n🔄 Testing access token...');
  auth.getClient().then(async (client) => {
    try {
      const token = await client.getAccessToken();
      if (token.token) {
        console.log('✅ Access token obtained successfully!');
        console.log('✅ FCM is properly configured and ready to use!');
        console.log('\n🎉 Everything looks good! You can send notifications now.');
      } else {
        console.log('❌ Failed to obtain access token');
      }
    } catch (error) {
      console.log('❌ Error getting access token:', error.message);
      console.log('\n💡 Check:');
      console.log('   - Service account JSON is correct');
      console.log('   - Cloud Messaging API is enabled in Google Cloud Console');
    }
  }).catch((error) => {
    console.log('❌ Error:', error.message);
  });
} catch (e) {
  console.log('\n⚠️  google-auth-library not found');
  console.log('   Install it: npm install google-auth-library');
  console.log('   But the configuration looks valid!');
}

console.log('\n📋 Summary:');
console.log(`   - Environment variable: ✅ Set`);
console.log(`   - JSON format: ${isValid ? '✅ Valid' : '❌ Invalid'}`);
console.log(`   - Project ID: ${projectId || 'N/A'}`);
