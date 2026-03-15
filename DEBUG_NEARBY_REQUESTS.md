# Debugging Nearby Requests Issue

## Problem
Nearby requests are not appearing when creating emergency service requests on one device and checking on another device.

## No API Keys Required
**You don't need any API keys** - this is a backend logic issue, not an API key problem.

## Steps to Debug

### 1. Check Backend Deployment
Make sure your backend on Render.com has the latest code deployed:
- The updated `nearbyRoutes.js` file with the fixed filter logic
- Restart the backend service on Render.com after deploying

### 2. Check Backend Logs
On Render.com, check the backend logs for:
```
[Nearby Requests] User <userId> searching at (<lat>, <lng>) within <radius>km radius
[Nearby Requests] Found requests: Medical=X, Blood=X, ...
[Nearby Requests] Returning X requests after filtering
```

### 3. Test Endpoint
You can test if requests exist by calling:
```
GET https://helpnovaproject.onrender.com/api/nearby/test
Authorization: Bearer <your-token>
```

This will show:
- Count of pending requests by type
- Sample requests with location data

### 4. Check Flutter App Logs
When testing, check the Flutter console/logs for:
```
[HomeScreen] Loading nearby requests at (<lat>, <lng>)
[API] Fetching nearby requests from: <url>
[API] Nearby requests response status: <code>
[API] Nearby requests response body: <body>
[HomeScreen] Loaded X nearby requests
```

### 5. Verify Request Creation
When creating a request, make sure:
- Location is being sent correctly (check the request creation logs)
- Request status is 'pending' (not 'completed' or 'cancelled')
- Location has both latitude and longitude

### 6. Common Issues

#### Issue 1: Requests not being created
- Check if the request creation API returns success
- Verify location is included in the request body
- Check backend logs for creation errors

#### Issue 2: Requests too far away
- Default radius is now 10km (increased from 5km)
- If devices are more than 10km apart, increase the radius in the API call

#### Issue 3: Backend not updated
- Make sure you've deployed the latest backend code to Render.com
- Restart the backend service after deployment

#### Issue 4: Filter bug (FIXED)
- The filter was comparing request userId with itself
- This has been fixed in the latest code
- Make sure the backend has the fix deployed

### 7. Manual Testing Steps

1. **Create a request on Device 1:**
   - Open the app
   - Create any emergency request (Medical, Blood, etc.)
   - Make sure location is detected
   - Submit the request
   - Note the success message

2. **Check on Device 2:**
   - Open the app (different user account)
   - Go to home screen
   - Check "Nearby Requests" section
   - Tap refresh button if needed
   - Wait a few seconds for location to be detected

3. **Check Backend Logs:**
   - On Render.com, check the logs
   - Look for the nearby requests query
   - Check if requests are being found
   - Check if they're being filtered correctly

### 8. Quick Fixes

If requests still don't appear:

1. **Increase radius:**
   - In `home_screen.dart`, change `radius: 10.0` to `radius: 50.0` for testing

2. **Check database:**
   - Verify requests are actually in the database
   - Check if they have location data
   - Check if status is 'pending'

3. **Test with same user:**
   - The filter excludes requests from the same user
   - Make sure you're using different user accounts on each device

## Next Steps

1. Deploy the updated backend code to Render.com
2. Restart the backend service
3. Rebuild and install the APK
4. Test again with the debug logs enabled
5. Check both Flutter and backend logs to identify the issue
