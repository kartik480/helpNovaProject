import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/api_service.dart';
import 'services/geocoding_service.dart';
import 'utils/responsive.dart';

class RequestDetailScreen extends StatefulWidget {
  final dynamic request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarker();
  }

  void _createMarker() {
    final location = widget.request['location'];
    if (location != null && location['latitude'] != null && location['longitude'] != null) {
      final lat = location['latitude'] as double;
      final lng = location['longitude'] as double;
      final typeCode = widget.request['typeCode'] ?? '';
      
      // Get marker color based on request type
      BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      switch (typeCode) {
        case 'medical':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
          break;
        case 'blood':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
        case 'accident':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          break;
        case 'ambulance':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
        case 'mechanic':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
          break;
        case 'electrician':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
          break;
        case 'volunteer':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          break;
        case 'fire':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
      }

      setState(() {
        _markers = {
          Marker(
            markerId: MarkerId('request_location'),
            position: LatLng(lat, lng),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: widget.request['title'] ?? 'Emergency Location',
              snippet: widget.request['description'] ?? '',
            ),
          ),
        };
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Center map on request location
    final location = widget.request['location'];
    if (location != null && location['latitude'] != null && location['longitude'] != null) {
      final lat = location['latitude'] as double;
      final lng = location['longitude'] as double;
      
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          15.0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  IconData _getIcon(String typeCode) {
    switch (typeCode) {
      case 'medical':
        return Icons.local_hospital;
      case 'blood':
        return Icons.bloodtype;
      case 'accident':
        return Icons.car_crash;
      case 'ambulance':
        return Icons.emergency;
      case 'mechanic':
        return Icons.build;
      case 'electrician':
        return Icons.electrical_services;
      case 'volunteer':
        return Icons.people;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColor(String typeCode) {
    switch (typeCode) {
      case 'medical':
        return Colors.blue;
      case 'blood':
        return Colors.red;
      case 'accident':
        return Colors.orange;
      case 'ambulance':
        return Colors.red;
      case 'mechanic':
        return Colors.brown;
      case 'electrician':
        return Colors.yellow.shade700;
      case 'volunteer':
        return Colors.green;
      case 'fire':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptRequest(BuildContext context) async {
    final token = await ApiService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login again')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // You'll need to implement accept methods in ApiService for each type
      // For now, show a success message
      await Future.delayed(Duration(seconds: 1)); // Simulate API call
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request accepted! You will be contacted soon.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callUser(BuildContext context) async {
    final user = widget.request['userId'];
    if (user == null || user['phone'] == null) return;

    final phone = user['phone'];
    final uri = Uri.parse('tel:$phone');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot make phone call')),
      );
    }
  }

  Future<void> _navigateToLocation(BuildContext context) async {
    final location = widget.request['location'];
    if (location == null) return;

    final lat = location['latitude'];
    final lng = location['longitude'];
    
    // Open in Google Maps
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon(widget.request['typeCode'] ?? '');
    final color = _getColor(widget.request['typeCode'] ?? '');
    final distance = widget.request['distance'] ?? 0.0;
    final distanceText = distance < 1
        ? '${(distance * 1000).toStringAsFixed(0)}m away'
        : '${distance.toStringAsFixed(1)} km away';

    String timeText = 'Just now';
    if (widget.request['createdAt'] != null) {
      try {
        final createdAt = DateTime.parse(widget.request['createdAt']);
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

    final user = widget.request['userId'] ?? {};
    final data = widget.request['data'] ?? {};
    final location = widget.request['location'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: color,
        elevation: 0,
        title: Text(
          widget.request['type'] ?? 'Emergency Request',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(Responsive.spacing(context, 20)),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: Responsive.iconSize(context, 60),
                    color: Colors.white,
                  ),
                  SizedBox(height: Responsive.spacing(context, 12)),
                  Text(
                    widget.request['title'] ?? 'Emergency Request',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Responsive.spacing(context, 8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text(
                        distanceText,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 20)),

            // Location Address
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
              child: Container(
                padding: EdgeInsets.all(Responsive.spacing(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Exact Location',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.spacing(context, 12)),
                    FutureBuilder<String?>(
                      future: () {
                        if (location != null && location['latitude'] != null && location['longitude'] != null) {
                          return GeocodingService.getAddressFromCoordinates(
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
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Loading address...',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 14),
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        }
                        
                        final address = snapshot.data;
                        if (address != null && address.isNotEmpty) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  address,
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 14),
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        
                        // Fallback to coordinates
                        if (location != null && location['latitude'] != null && location['longitude'] != null) {
                          return Text(
                            '${location['latitude']}, ${location['longitude']}',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 14),
                              color: Colors.grey[600],
                            ),
                          );
                        }
                        
                        return Text(
                          'Location not available',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 16)),

            // Map View
            if (location != null && location['latitude'] != null && location['longitude'] != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          location['latitude'] as double,
                          location['longitude'] as double,
                        ),
                        zoom: 15.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                    ),
                  ),
                ),
              ),

            if (location != null && location['latitude'] != null && location['longitude'] != null)
              SizedBox(height: Responsive.spacing(context, 16)),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
              child: Container(
                padding: EdgeInsets.all(Responsive.spacing(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, 8)),
                    Text(
                      widget.request['description'] ?? 'No description provided',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 14),
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 16)),

            // Request Details
            if (data.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
                child: Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, 16)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Details',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, 12)),
                      ...data.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: Responsive.spacing(context, 8)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${entry.key.toString().replaceAll(RegExp(r'([A-Z])'), r' $1').trim()}:',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 14),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.value.toString(),
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 14),
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

            SizedBox(height: Responsive.spacing(context, 16)),

            // Requester Info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
              child: Container(
                padding: EdgeInsets.all(Responsive.spacing(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requester Information',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, 12)),
                    if (user['name'] != null)
                      _buildInfoRow(context, 'Name', user['name']),
                    if (user['phone'] != null)
                      _buildInfoRow(context, 'Phone', user['phone']),
                    if (user['email'] != null)
                      _buildInfoRow(context, 'Email', user['email']),
                  ],
                ),
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 24)),

            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _callUser(context),
                      icon: Icon(Icons.phone, color: Colors.white),
                      label: Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(context, 14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.spacing(context, 12)),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToLocation(context),
                      icon: Icon(Icons.navigation, color: Colors.white),
                      label: Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(context, 14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 12)),

            // Accept Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: EdgeInsets.symmetric(vertical: Responsive.spacing(context, 16)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Accept Help',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
