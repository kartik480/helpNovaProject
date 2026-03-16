import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'widgets/radar_map_panel.dart';
import 'widgets/map_search_widget.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/geocoding_service.dart';
import 'utils/responsive.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  double? userLatitude;
  double? userLongitude;
  String? userAddress; // Store selected address
  bool isLoadingLocation = true;
  bool isLoadingHelpers = false;
  bool isSendingAlert = false;
  bool isLocationSet = false; // Track if location has been set via map search
  List<Map<String, dynamic>> acceptedHelpers = [];
  List<Map<String, dynamic>> helperLocations = []; // Real-time helper locations
  List<Map<String, dynamic>> activeUsers = []; // All active users with location enabled
  List<Map<String, dynamic>> nearbyActiveUsers = []; // Filtered active users within 10km (using Google Maps API)
  int nearbyHelpersCount = 0; // Count of nearby helpers within 10km
  bool isLoadingNearbyHelpers = false;
  Map<String, dynamic>? requestInfo;
  Timer? _helperLocationTimer;
  Timer? _activeUsersTimer;

  @override
  void initState() {
    super.initState();
    // Don't auto-get location, wait for user to set it via map search
    setState(() {
      isLoadingLocation = false;
    });
  }

  @override
  void dispose() {
    _helperLocationTimer?.cancel();
    _activeUsersTimer?.cancel();
    super.dispose();
  }


  // Filter helpers within 10km radius using Google Maps Distance Matrix API (batch processing)
  Future<List<Map<String, dynamic>>> _getNearbyHelpers(List<Map<String, dynamic>> helpers, double radiusKm) async {
    if (userLatitude == null || userLongitude == null || helpers.isEmpty) {
      return [];
    }
    
    // Prepare destinations list for batch API call
    List<Map<String, double>> destinations = [];
    List<Map<String, dynamic>> validHelpers = [];
    
    for (var helper in helpers) {
      final lat = helper['latitude'];
      final lng = helper['longitude'];
      
      if (lat == null || lng == null) continue;
      
      final latitude = lat is double ? lat : (lat is String ? double.tryParse(lat) : lat as double?);
      final longitude = lng is double ? lng : (lng is String ? double.tryParse(lng) : lng as double?);
      
      if (latitude == null || longitude == null) continue;
      
      destinations.add({'lat': latitude, 'lng': longitude});
      validHelpers.add(helper);
    }
    
    if (destinations.isEmpty) return [];
    
    try {
      // Use batch Distance Matrix API for efficient processing
      final distances = await GeocodingService.getBatchRoadDistances(
        userLatitude!,
        userLongitude!,
        destinations,
      );
      
      List<Map<String, dynamic>> nearbyHelpers = [];
      
      // Filter helpers based on road distances
      for (int i = 0; i < validHelpers.length; i++) {
        final distance = distances[i];
        if (distance != null && distance <= radiusKm) {
          nearbyHelpers.add(validHelpers[i]);
        }
      }
      
      print('[EmergencySOS] Filtered ${nearbyHelpers.length} nearby helpers using Google Maps Distance Matrix API (road distance)');
      return nearbyHelpers;
    } catch (e) {
      print('Error in batch distance calculation: $e');
      return [];
    }
  }

  // Get count of nearby helpers (within 10km) using Google Maps Distance Matrix API (batch processing)
  Future<int> _getNearbyHelpersCount() async {
    if (userLatitude == null || userLongitude == null) {
      return 0;
    }
    
    const double radiusKm = 10.0;
    
    // Combine all helpers (helperLocations + activeUsers) avoiding duplicates
    List<Map<String, dynamic>> allHelpers = [];
    Set<String> addedIds = {};
    
    // Add helperLocations first
    for (var helper in helperLocations) {
      final id = helper['helperId']?.toString() ?? helper['_id']?.toString();
      if (id != null && !addedIds.contains(id)) {
        allHelpers.add(helper);
        addedIds.add(id);
      }
    }
    
    // Add activeUsers (avoid duplicates)
    for (var user in activeUsers) {
      final userId = user['id']?.toString() ?? user['_id']?.toString();
      if (userId != null && !addedIds.contains(userId)) {
        allHelpers.add(user);
        addedIds.add(userId);
      }
    }
    
    if (allHelpers.isEmpty) return 0;
    
    // Prepare destinations list for batch API call
    List<Map<String, double>> destinations = [];
    List<Map<String, dynamic>> validHelpers = [];
    
    for (var helper in allHelpers) {
      final lat = helper['latitude'];
      final lng = helper['longitude'];
      
      if (lat == null || lng == null) continue;
      
      final latitude = lat is double ? lat : (lat is String ? double.tryParse(lat) : lat as double?);
      final longitude = lng is double ? lng : (lng is String ? double.tryParse(lng) : lng as double?);
      
      if (latitude == null || longitude == null) continue;
      
      destinations.add({'lat': latitude, 'lng': longitude});
      validHelpers.add(helper);
    }
    
    if (destinations.isEmpty) return 0;
    
    try {
      // Use batch Distance Matrix API for efficient processing
      final distances = await GeocodingService.getBatchRoadDistances(
        userLatitude!,
        userLongitude!,
        destinations,
      );
      
      int count = 0;
      
      // Count helpers within radius based on road distances
      for (int i = 0; i < validHelpers.length; i++) {
        final distance = distances[i];
        if (distance != null && distance <= radiusKm) {
          count++;
        }
      }
      
      print('[EmergencySOS] Found $count nearby helpers within ${radiusKm}km using Google Maps Distance Matrix API (road distance)');
      return count;
    } catch (e) {
      print('Error in batch distance calculation for count: $e');
      return 0;
    }
  }


  // Start periodic updates for helper locations and active users
  void _startPeriodicUpdates() {
    // Update helper locations every 5 seconds
    _helperLocationTimer?.cancel();
    _helperLocationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadHelperLocations();
      } else {
        timer.cancel();
      }
    });

    // Update active users every 10 seconds
    _activeUsersTimer?.cancel();
    _activeUsersTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadActiveUsers();
      } else {
        timer.cancel();
      }
    });
  }

  // Load real-time helper locations for active emergency
  Future<void> _loadHelperLocations() async {
    try {
      final result = await ApiService.getHelperLocations();
      if (result['success'] == true) {
        setState(() {
          helperLocations = List<Map<String, dynamic>>.from(result['helpers'] ?? []);
        });
        print('[EmergencySOS] Loaded ${helperLocations.length} helper locations');
        // Update nearby helpers count after loading helper locations
        _updateNearbyHelpers();
      }
    } catch (e) {
      print('Error loading helper locations: $e');
    }
  }

  // Load all active users with location enabled
  Future<void> _loadActiveUsers() async {
    try {
      final result = await ApiService.getActiveUsers();
      if (result['success'] == true) {
        setState(() {
          activeUsers = List<Map<String, dynamic>>.from(result['users'] ?? []);
        });
        print('[EmergencySOS] Loaded ${activeUsers.length} active users');
        // Update nearby helpers after loading active users
        _updateNearbyHelpers();
      }
    } catch (e) {
      print('Error loading active users: $e');
    }
  }

  // Update nearby helpers using Google Maps Distance Matrix API
  Future<void> _updateNearbyHelpers() async {
    if (userLatitude == null || userLongitude == null || isLoadingNearbyHelpers) {
      return; // Skip if already loading or location not available
    }

    setState(() {
      isLoadingNearbyHelpers = true;
    });

    try {
      // Filter active users within 10km using Google Maps Distance Matrix API
      // This uses accurate road distances instead of straight-line distance
      final filtered = await _getNearbyHelpers(activeUsers, 10.0);
      final count = await _getNearbyHelpersCount();
      
      if (mounted) {
        setState(() {
          nearbyActiveUsers = filtered;
          nearbyHelpersCount = count;
          isLoadingNearbyHelpers = false;
        });
        
        print('[EmergencySOS] Found $count nearby helpers within 10km using Google Maps Distance Matrix API (road distance)');
      }
    } catch (e) {
      print('Error updating nearby helpers: $e');
      if (mounted) {
        setState(() {
          isLoadingNearbyHelpers = false;
        });
      }
    }
  }

  Future<void> _loadAcceptedHelpers() async {
    if (userLatitude == null || userLongitude == null) {
      return;
    }

    setState(() {
      isLoadingHelpers = true;
    });

    try {
      final result = await ApiService.getAcceptedHelpers(
        latitude: userLatitude,
        longitude: userLongitude,
      );

      if (result['success'] == true) {
        setState(() {
          acceptedHelpers = List<Map<String, dynamic>>.from(result['helpers'] ?? []);
          requestInfo = result['request'];
          isLoadingHelpers = false;
        });
      } else {
        setState(() {
          acceptedHelpers = [];
          isLoadingHelpers = false;
        });
        // Only show error message if it's not a "no requests" message
        final message = result['message'] ?? '';
        if (mounted && !message.toLowerCase().contains('no active') && !message.toLowerCase().contains('not found')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.isNotEmpty ? message : 'Unable to load helpers'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading accepted helpers: $e');
      setState(() {
        acceptedHelpers = [];
        isLoadingHelpers = false;
      });
    }
  }

  Future<void> _sendEmergencyAlert() async {
    if (userLatitude == null || userLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location not available. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSendingAlert = true;
    });

    try {
      final result = await NotificationService.sendEmergencyAlert(
        latitude: userLatitude!,
        longitude: userLongitude!,
        address: userAddress,
        description: 'Emergency SOS request - Immediate help needed',
      );

      if (mounted) {
        setState(() {
          isSendingAlert = false;
        });

        if (result['success'] == true) {
          final notifiedUsers = result['notifiedUsers'] ?? 0;
          final totalNearbyUsers = result['totalNearbyUsers'] ?? 0;
          final usersWithoutFcm = result['usersWithoutFcmTokens'] ?? 0;
          
          String message;
          Color backgroundColor;
          
          if (notifiedUsers > 0) {
            message = 'Emergency alert sent successfully! $notifiedUsers nearby helper${notifiedUsers > 1 ? 's' : ''} notified.';
            backgroundColor = Colors.green;
          } else if (totalNearbyUsers > 0) {
            if (usersWithoutFcm > 0) {
              message = '⚠️ $totalNearbyUsers helper${totalNearbyUsers > 1 ? 's' : ''} nearby, but ${usersWithoutFcm} don\'t have notifications enabled. They need to enable notifications in the app.';
            } else {
              message = '⚠️ No helpers were notified. Check backend logs for details.';
            }
            backgroundColor = Colors.orange;
          } else {
            // More detailed message based on debug info
            final debug = result['debug'];
            final totalActive = debug?['totalActiveUsers'] ?? 0;
            final nearbyCount = debug?['nearbyUsersWithinDistance'] ?? 0;
            
            if (totalActive > 0 && nearbyCount == 0) {
              message = '⚠️ Found $totalActive active helper${totalActive > 1 ? 's' : ''}, but none within 10km. Try increasing the search radius or wait for helpers to come closer.';
            } else if (nearbyCount > 0) {
              message = '⚠️ Found $nearbyCount nearby helper${nearbyCount > 1 ? 's' : ''}, but they don\'t have notifications enabled. Ask them to enable notifications in the app.';
            } else {
              message = '⚠️ No nearby helpers found. Make sure helpers have location enabled and are within 10km.';
            }
            backgroundColor = Colors.orange;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: Duration(seconds: 5),
            ),
          );
          
          // Refresh accepted helpers and locations after a short delay
          Future.delayed(Duration(seconds: 2), () {
            _loadAcceptedHelpers();
            _loadHelperLocations();
            _loadActiveUsers();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send emergency alert'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSendingAlert = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending alert: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onLocationSelected(double latitude, double longitude, String address) {
    setState(() {
      userLatitude = latitude;
      userLongitude = longitude;
      userAddress = address;
      isLocationSet = true;
    });
    
    // Fetch accepted helpers once location is available
    _loadAcceptedHelpers();
    _loadHelperLocations();
    _loadActiveUsers();
    _startPeriodicUpdates();
    // Update nearby helpers after location is available
    _updateNearbyHelpers();
  }

  void _openMapSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSearchWidget(
          initialLatitude: userLatitude,
          initialLongitude: userLongitude,
          initialAddress: userAddress,
          onLocationSelected: _onLocationSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If location is not set, navigate to map search widget
    if (!isLocationSet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openMapSearch();
      });
      
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.red,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Emergency SOS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Location is set, show the main emergency SOS screen
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Emergency SOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_location, color: Colors.white),
            onPressed: _openMapSearch,
            tooltip: 'Change location',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Emergency Status Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(Responsive.spacing(context, 20)),
              decoration: BoxDecoration(
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: Responsive.iconSize(context, 48),
                  ),
                  SizedBox(height: Responsive.spacing(context, 12)),
                  Text(
                    'Emergency Alert Sent!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(context, 8)),
                  Text(
                    'Your location has been shared with nearby helpers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: Responsive.fontSize(context, 14),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Notification Alert Panel
          if (userLatitude != null && userLongitude != null)
            Container(
              margin: EdgeInsets.all(Responsive.spacing(context, 16)),
              padding: EdgeInsets.all(Responsive.spacing(context, 20)),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.orange.shade700, size: Responsive.iconSize(context, 28)),
                      SizedBox(width: Responsive.spacing(context, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alert Nearby Helpers',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 18),
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            SizedBox(height: Responsive.spacing(context, 4)),
                            Text(
                              'Send push notification to nearby helpers',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 14),
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.spacing(context, 16)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSendingAlert ? null : _sendEmergencyAlert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: isSendingAlert
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Sending Alert...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'SEND ALERT TO NEARBY HELPERS',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

          // Selected Address Display
          if (userAddress != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
              padding: EdgeInsets.all(Responsive.spacing(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userAddress!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: Responsive.spacing(context, 16)),

          // Radar Map Panel
          if (userLatitude != null && userLongitude != null)
            Column(
              children: [
                RadarMapPanel(
                  userLatitude: userLatitude!,
                  userLongitude: userLongitude!,
                  helpers: acceptedHelpers,
                  helperLocations: helperLocations,
                  activeUsers: nearbyActiveUsers, // Only show helpers within 10km (filtered using Google Maps API)
                ),
                // Display coordinates under the map
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade700, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Your Location: Lat ${userLatitude!.toStringAsFixed(6)}, Lng ${userLongitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Display helper count - show accepted helpers and nearby active users (within 10km)
                if (isLoadingNearbyHelpers)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Calculating distances...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (helperLocations.isNotEmpty || nearbyActiveUsers.isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, color: Colors.green.shade700, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${helperLocations.length} Accepted Helper${helperLocations.length != 1 ? 's' : ''} | $nearbyHelpersCount Nearby Helper${nearbyHelpersCount != 1 ? 's' : ''} Within 10km (Road Distance)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Container(
              height: 300,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Location not available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // Accepted Users List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Accepted Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.blue),
                          onPressed: _loadAcceptedHelpers,
                          tooltip: 'Refresh',
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${acceptedHelpers.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                isLoadingHelpers
                    ? Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : acceptedHelpers.isEmpty
                        ? Container(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No helpers accepted yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Helpers will appear here once they accept your request',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: acceptedHelpers.map((helper) {
                              // Convert dynamic map to string map for display
                              final userMap = <String, String>{
                                'name': helper['name']?.toString() ?? 'Helper',
                                'skill': helper['skill']?.toString() ?? 'Helper',
                                'distance': helper['distance']?.toString() ?? 'Unknown',
                                'phone': helper['phone']?.toString() ?? '',
                                'bloodGroup': helper['bloodGroup']?.toString() ?? '',
                                'status': helper['status']?.toString() ?? 'Accepted',
                              };
                              return _buildUserCard(userMap, context);
                            }).toList(),
                          ),
              ],
            ),
          ),
          SizedBox(height: 16), // Add bottom padding for better scrolling
        ],
        ),
      ),
      bottomNavigationBar: (userLatitude != null && userLongitude != null)
          ? _buildBottomWarningBar()
          : null,
    );
  }

  Widget _buildBottomWarningBar() {
    // Use the state variable that's updated with Google Maps API calculations
    if (nearbyHelpersCount > 0) {
      // Don't show warning if there are nearby helpers
      return SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          top: BorderSide(color: Colors.orange.shade300, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No nearby helpers found. Make sure helpers have location enabled and are within 10km.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, String> user, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.red.shade100,
            child: Icon(
              Icons.person,
              color: Colors.red,
              size: 30,
            ),
          ),
          SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user['name']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: user['status'] == 'On the way'
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user['status']!,
                        style: TextStyle(
                          color: user['status'] == 'On the way'
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.work_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      user['skill']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      user['distance']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.bloodtype, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      user['bloodGroup']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          Column(
            children: [
              // Chat Button
              IconButton(
                onPressed: () {
                  // TODO: Implement chat functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening chat with ${user['name']}...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Call Button
              IconButton(
                onPressed: () async {
                  final phone = user['phone'];
                  if (phone != null && phone.isNotEmpty) {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cannot make phone call'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Phone number not available'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                icon: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
