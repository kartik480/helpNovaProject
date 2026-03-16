import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'profile_screen.dart';
import 'services/api_service.dart';
import 'services/geocoding_service.dart';
import 'emergency_sos_screen.dart';
import 'medical_help_screen.dart';
import 'blood_donation_screen.dart';
import 'accident_help_screen.dart';
import 'ambulance_request_screen.dart';
import 'mechanic_help_screen.dart';
import 'electrician_help_screen.dart';
import 'volunteer_help_screen.dart';
import 'fire_emergency_screen.dart';
import 'utils/responsive.dart';
import 'request_detail_screen.dart';
import 'widgets/emergency_notification_dialog.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? userName;
  List<dynamic> nearbyRequests = [];
  bool isLoadingRequests = false;
  double? userLatitude;
  double? userLongitude;
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();
    _getUserLocation();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // Setup notification listener for this screen
  void _setupNotificationListener() {
    // Listen for foreground messages directly in this screen
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[HomeScreen] Notification received in foreground');
      debugPrint('[HomeScreen] Message data: ${message.data}');
      debugPrint('[HomeScreen] Notification title: ${message.notification?.title}');
      
      // Check if it's an emergency notification
      final data = message.data;
      final title = message.notification?.title ?? '';
      final dataType = data['type'] ?? '';
      
      final isEmergency = 
          dataType == 'emergency_sos' || 
          title.toLowerCase().contains('emergency') ||
          title.toLowerCase().contains('sos') ||
          title.contains('🚨') ||
          (data.containsKey('userId') && data.containsKey('latitude'));
      
      if (isEmergency && mounted) {
        debugPrint('[HomeScreen] Emergency notification detected, showing dialog...');
        _showEmergencyDialog(message);
      }
    });
  }

  // Show emergency dialog directly from this screen
  void _showEmergencyDialog(RemoteMessage message) {
    if (!mounted) {
      debugPrint('[HomeScreen] Cannot show dialog - widget not mounted');
      return;
    }
    
    final data = message.data;
    debugPrint('[HomeScreen] Showing emergency dialog with data: $data');
    
    // Use SchedulerBinding to ensure dialog shows after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => EmergencyNotificationDialog(
              userName: data['userName'] ?? 'User',
              userPhone: data['userPhone'] ?? '',
              latitude: double.tryParse(data['latitude'] ?? '0') ?? 0,
              longitude: double.tryParse(data['longitude'] ?? '0') ?? 0,
              description: data['description'] ?? 'Emergency SOS request',
              requestId: data['userId'] ?? '',
            ),
          );
          debugPrint('[HomeScreen] Emergency dialog shown successfully');
        } catch (e) {
          debugPrint('[HomeScreen] ERROR showing dialog: $e');
          // Retry after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && context.mounted) {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => EmergencyNotificationDialog(
                    userName: data['userName'] ?? 'User',
                    userPhone: data['userPhone'] ?? '',
                    latitude: double.tryParse(data['latitude'] ?? '0') ?? 0,
                    longitude: double.tryParse(data['longitude'] ?? '0') ?? 0,
                    description: data['description'] ?? 'Emergency SOS request',
                    requestId: data['userId'] ?? '',
                  ),
                );
                debugPrint('[HomeScreen] Emergency dialog shown on retry');
              } catch (retryError) {
                debugPrint('[HomeScreen] ERROR on retry: $retryError');
              }
            }
          });
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh nearby requests when app comes back to foreground
      if (userLatitude != null && userLongitude != null) {
        _loadNearbyRequests();
      }
    }
  }

  Future<void> _loadUserName() async {
    final name = await ApiService.getUserName();
    setState(() {
      userName = name ?? 'User';
    });
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
      });

      // Update user location in backend for emergency notifications
      _updateUserLocationInBackend(position.latitude, position.longitude);

      _loadNearbyRequests();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _updateUserLocationInBackend(double latitude, double longitude) async {
    try {
      // Update location in backend (silently, don't show errors to user)
      await ApiService.updateUserLocation(
        latitude: latitude,
        longitude: longitude,
      );
      print('[HomeScreen] User location updated in backend');
    } catch (e) {
      // Silently fail - location update is not critical for app functionality
      print('[HomeScreen] Failed to update location in backend: $e');
    }
  }

  Future<void> _loadNearbyRequests() async {
    if (userLatitude == null || userLongitude == null) {
      print('[HomeScreen] Cannot load nearby requests: location not available');
      return;
    }

    print('[HomeScreen] Loading nearby requests at (${userLatitude}, ${userLongitude})');
    
    setState(() {
      isLoadingRequests = true;
    });

    final result = await ApiService.getNearbyRequests(
      latitude: userLatitude!,
      longitude: userLongitude!,
      radius: 10.0, // 10km radius (increased from 5km)
    );

    setState(() {
      isLoadingRequests = false;
      if (result['success'] == true) {
        nearbyRequests = result['requests'] ?? [];
        print('[HomeScreen] Loaded ${nearbyRequests.length} nearby requests');
      } else {
        print('[HomeScreen] Failed to load nearby requests: ${result['message']}');
        nearbyRequests = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);
    final logoSize = Responsive.logoSize(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        bottom: false, // Let bottom nav handle bottom safe area
        child: Column(
          children: [
            //TOP BAR - Fixed at top //
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padding.horizontal,
                vertical: padding.vertical,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'images/logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: Responsive.spacing(context, 8)),
                      Text(
                        "Help Nova",
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: Responsive.iconSize(context, 24),
                      ),
                      SizedBox(width: Responsive.spacing(context, 10)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: Responsive.value(
                            context,
                            mobile: 20.0,
                            tablet: 25.0,
                            desktop: 30.0,
                          ),
                          backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable content //
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.maxContentWidth(context),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding.horizontal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: Responsive.spacing(context, 20)),

                        // GREETING CARD
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Responsive.spacing(context, 16)),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hello ${userName ?? 'User'} 👋",
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: Responsive.spacing(context, 4)),
                              Text(
                                "Stay safe and help others in need",
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: Responsive.spacing(context, 20)),

                        // Emergency SOS Box - Big and Visible
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmergencySosScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.spacing(context, 24),
                              horizontal: Responsive.spacing(context, 20),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.6),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                  offset: Offset(0, 6),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(Responsive.spacing(context, 12)),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.emergency,
                                    color: Colors.white,
                                    size: Responsive.iconSize(context, 32),
                                  ),
                                ),
                                SizedBox(width: Responsive.spacing(context, 16)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "EMERGENCY SOS",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: Responsive.fontSize(context, 20),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: Responsive.spacing(context, 4)),
                                      Text(
                                        "Request Immediate Help",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: Responsive.fontSize(context, 15),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: Responsive.spacing(context, 25)),

                        Text(
                          "Emergency Service Categories",
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: Responsive.spacing(context, 15)),

                        // Main Services Grid - Responsive
                        GridView.count(
                          crossAxisCount: Responsive.isSmallMobile(context) 
                            ? 2 
                            : Responsive.gridCrossAxisCount(
                                context,
                                mobile: 2,
                                tablet: 3,
                                desktop: 4,
                              ),
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisSpacing: Responsive.spacing(context, Responsive.isSmallMobile(context) ? 8 : 12),
                          mainAxisSpacing: Responsive.spacing(context, Responsive.isSmallMobile(context) ? 8 : 12),
                          childAspectRatio: Responsive.isSmallMobile(context)
                            ? 1.6
                            : Responsive.gridAspectRatio(
                                context,
                                mobile: 1.5,
                                tablet: 1.3,
                                desktop: 1.2,
                              ),
                          children: [
                            serviceCard(context, Icons.local_hospital, "Medical Help"),
                            serviceCard(context, Icons.bloodtype, "Blood Donation"),
                            serviceCard(context, Icons.car_crash, "Accident Help"),
                            serviceCard(context, Icons.emergency, "Ambulance"),
                            serviceCard(context, Icons.build, "Mechanic Help"),
                            serviceCard(context, Icons.electrical_services, "Electrician"),
                            serviceCard(context, Icons.people, "Volunteer Help"),
                            serviceCard(context, Icons.local_fire_department, "Fire Emergency"),
                          ],
                        ),

                        SizedBox(height: Responsive.spacing(context, 25)),

                        // Nearby Requests Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Nearby Requests",
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isLoadingRequests)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
                              )
                            else
                              IconButton(
                                icon: Icon(Icons.refresh, color: Colors.red),
                                onPressed: _loadNearbyRequests,
                                tooltip: 'Refresh',
                              ),
                          ],
                        ),
                        SizedBox(height: Responsive.spacing(context, 15)),
                        if (isLoadingRequests)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(Responsive.spacing(context, 20)),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (nearbyRequests.isEmpty)
                          Container(
                            padding: EdgeInsets.all(Responsive.spacing(context, 20)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: Responsive.iconSize(context, 48),
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: Responsive.spacing(context, 8)),
                                  Text(
                                    'No nearby requests found',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 14),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: Responsive.spacing(context, 4)),
                                  Text(
                                    'Check back later or refresh',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 12),
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...nearbyRequests.map((request) {
                            return _buildNearbyRequestCard(context, request);
                          }).toList(),
                        SizedBox(height: Responsive.spacing(context, 20)),
                        // Add bottom padding to account for bottom navigation bar
                        SizedBox(height: Responsive.bottomNavContentHeight(context) + 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SERVICE CARD WIDGET
  Widget serviceCard(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        // Navigate to service-specific screen
        if (title == "Medical Help") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MedicalHelpScreen()),
          );
        } else if (title == "Blood Donation") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BloodDonationScreen()),
          );
        } else if (title == "Accident Help") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccidentHelpScreen()),
          );
        } else if (title == "Ambulance") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AmbulanceRequestScreen()),
          );
        } else if (title == "Mechanic Help") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MechanicHelpScreen()),
          );
        } else if (title == "Electrician") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ElectricianHelpScreen()),
          );
        } else if (title == "Volunteer Help") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VolunteerHelpScreen()),
          );
        } else if (title == "Fire Emergency") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FireEmergencyScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: Responsive.iconSize(context, 32),
              color: Colors.red,
            ),
            SizedBox(height: Responsive.spacing(context, 10)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.fontSize(context, 14),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEARBY REQUEST CARD WIDGET //
  Widget _buildNearbyRequestCard(BuildContext context, dynamic request) {
    // Get icon and color based on request type
    IconData icon;
    Color color;
    
    switch (request['typeCode']) {
      case 'medical':
        icon = Icons.local_hospital;
        color = Colors.blue;
        break;
      case 'blood':
        icon = Icons.bloodtype;
        color = Colors.red;
        break;
      case 'accident':
        icon = Icons.car_crash;
        color = Colors.orange;
        break;
      case 'ambulance':
        icon = Icons.emergency;
        color = Colors.red;
        break;
      case 'mechanic':
        icon = Icons.build;
        color = Colors.brown;
        break;
      case 'electrician':
        icon = Icons.electrical_services;
        color = Colors.yellow.shade700;
        break;
      case 'volunteer':
        icon = Icons.people;
        color = Colors.green;
        break;
      case 'fire':
        icon = Icons.local_fire_department;
        color = Colors.red.shade700;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    // Format distance
    final distance = request['distance'] ?? 0.0;
    String distanceText;
    if (distance < 1) {
      distanceText = '${(distance * 1000).toStringAsFixed(0)}m away';
    } else {
      distanceText = '${distance.toStringAsFixed(1)} km away';
    }

    // Format time posted
    String timeText = 'Just now';
    if (request['createdAt'] != null) {
      try {
        final createdAt = DateTime.parse(request['createdAt']);
        final now = DateTime.now();
        final difference = now.difference(createdAt);
        
        if (difference.inMinutes < 1) {
          timeText = 'Just now';
        } else if (difference.inMinutes < 60) {
          timeText = '${difference.inMinutes} min ago';
        } else if (difference.inHours < 24) {
          timeText = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        } else {
          timeText = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
        }
      } catch (e) {
        timeText = 'Recently';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailScreen(request: request),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.spacing(context, 12)),
        padding: EdgeInsets.all(Responsive.spacing(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, 10)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: Responsive.iconSize(context, 24),
              ),
            ),
            SizedBox(width: Responsive.spacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['title'] ?? 'Emergency Request',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 16),
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(context, 4)),
                  Text(
                    request['description'] ?? '',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Responsive.spacing(context, 6)),
                  // Address from coordinates
                  FutureBuilder<String?>(
                    future: () {
                      final location = request['location'];
                      if (location != null && location['latitude'] != null && location['longitude'] != null) {
                        return GeocodingService.getShortAddress(
                          location['latitude'] as double,
                          location['longitude'] as double,
                        );
                      }
                      return Future.value(null);
                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: Responsive.iconSize(context, 14),
                              color: Colors.grey[400],
                            ),
                            SizedBox(width: 4),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      final address = snapshot.data;
                      if (address != null && address.isNotEmpty) {
                        return Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: Responsive.iconSize(context, 14),
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 12),
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }
                      
                      // Fallback to distance if address not available
                      return Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: Responsive.iconSize(context, 14),
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            distanceText,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 12),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: Responsive.spacing(context, 4)),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: Responsive.iconSize(context, 14),
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: Responsive.spacing(context, 8)),
                      Icon(
                        Icons.straighten,
                        size: Responsive.iconSize(context, 14),
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        distanceText,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

}