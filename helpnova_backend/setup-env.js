/**
 * Helper script to format Firebase Service Account JSON for .env file
 * 
 * Usage:
 * 1. Save your service account JSON to a file named 'service-account.json' in this directory
 * 2. Run: node setup-env.js
 * 3. Copy the output to your .env file
 */

const fs = require('fs');
const path = require('path');

const serviceAccountPath = path.join(__dirname, 'service-account.json');
const envPath = path.join(__dirname, '.env');

try {
  // Read service account JSON
  if (!fs.existsSync(serviceAccountPath)) {
    console.log('❌ service-account.json not found!');
    console.log('\n📝 Steps:');
    console.log('1. Save your Firebase Service Account JSON to: helpnova_backend/service-account.json');
    console.log('2. Run this script again: node setup-env.js');
    process.exit(1);
  }

  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  
  // Convert to single-line string
  const serviceAccountString = JSON.stringify(serviceAccount);
  
  // Read existing .env or create new
  let envContent = '';
  if (fs.existsSync(envPath)) {
    envContent = fs.readFileSync(envPath, 'utf8');
  }
  
  // Update or add FIREBASE_SERVICE_ACCOUNT
  if (envContent.includes('FIREBASE_SERVICE_ACCOUNT=')) {
    // Replace existing
    envContent = envContent.replace(
      /FIREBASE_SERVICE_ACCOUNT=.*/,
      `FIREBASE_SERVICE_ACCOUNT=${serviceAccountString}`
    );
  } else {
    // Add new
    envContent += `\nFIREBASE_SERVICE_ACCOUNT=${serviceAccountString}\n`;
  }
  
  // Write to .env file
  fs.writeFileSync(envPath, envContent, 'utf8');
  
  console.log('✅ Successfully updated .env file with FIREBASE_SERVICE_ACCOUNT!');
  console.log('\n⚠️  Security Reminder:');
  console.log('   - Never commit .env file to Git');
  console.log('   - Never commit service-account.json to Git');
  console.log('   - Keep these files secure and private');
  
} catch (error) {
  console.error('❌ Error:', error.message);
  if (error.message.includes('JSON')) {
    console.log('\n💡 Make sure your service-account.json file contains valid JSON');
  }
  process.exit(1);
}
