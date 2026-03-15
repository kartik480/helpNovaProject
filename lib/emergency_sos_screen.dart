import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/radar_map_panel.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  double? userLatitude;
  double? userLongitude;
  bool isLoadingLocation = true;
  bool isLoadingHelpers = false;
  bool isSendingAlert = false;
  List<Map<String, dynamic>> acceptedHelpers = [];
  Map<String, dynamic>? requestInfo;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
        isLoadingLocation = false;
      });
      
      // Fetch accepted helpers once location is available
      _loadAcceptedHelpers();
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        isLoadingLocation = false;
      });
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
        description: 'Emergency SOS request - Immediate help needed',
      );

      if (mounted) {
        setState(() {
          isSendingAlert = false;
        });

        if (result['success'] == true) {
          final notifiedUsers = result['notifiedUsers'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Emergency alert sent successfully! $notifiedUsers nearby helpers notified.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Refresh accepted helpers after a short delay
          Future.delayed(Duration(seconds: 2), () {
            _loadAcceptedHelpers();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send emergency alert'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
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

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          // Emergency Status Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
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
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'Emergency Alert Sent!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your location has been shared with nearby helpers',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Notification Alert Panel
          if (userLatitude != null && userLongitude != null)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
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
                      Icon(Icons.notifications_active, color: Colors.orange.shade700, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alert Nearby Helpers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Send push notification to nearby helpers',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
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

          // Radar Map Panel
          if (isLoadingLocation)
            Container(
              height: 300,
              margin: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (userLatitude != null && userLongitude != null)
            RadarMapPanel(
              userLatitude: userLatitude!,
              userLongitude: userLongitude!,
              helpers: acceptedHelpers,
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
          Expanded(
            child: Padding(
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
                  Expanded(
                    child: isLoadingHelpers
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : acceptedHelpers.isEmpty
                            ? RefreshIndicator(
                                onRefresh: _loadAcceptedHelpers,
                                child: SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.4,
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
                                          SizedBox(height: 16),
                                          Text(
                                            'Pull down to refresh',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadAcceptedHelpers,
                                child: ListView.builder(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  itemCount: acceptedHelpers.length,
                                  itemBuilder: (context, index) {
                                    final helper = acceptedHelpers[index];
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
                                  },
                                ),
                              ),
                  ),
                ],
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
