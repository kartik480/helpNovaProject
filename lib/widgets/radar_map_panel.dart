import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RadarMapPanel extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;
  final List<Map<String, dynamic>> helpers; // List of helpers with lat, lng, name, etc.
  final List<Map<String, dynamic>> helperLocations; // Real-time helper locations from emergency
  final List<Map<String, dynamic>> activeUsers; // All active users with location enabled

  const RadarMapPanel({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
    required this.helpers,
    this.helperLocations = const [],
    this.activeUsers = const [],
  });

  @override
  State<RadarMapPanel> createState() => _RadarMapPanelState();
}

class _RadarMapPanelState extends State<RadarMapPanel> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(RadarMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update markers if helpers list, helper locations, or active users changed
    if (oldWidget.helpers.length != widget.helpers.length ||
        oldWidget.helperLocations.length != widget.helperLocations.length ||
        oldWidget.activeUsers.length != widget.activeUsers.length ||
        oldWidget.userLatitude != widget.userLatitude ||
        oldWidget.userLongitude != widget.userLongitude) {
      _createMarkers();
      // Refit bounds if map is already created
      if (_mapController != null) {
        Future.delayed(Duration(milliseconds: 300), () {
          _fitBounds();
        });
      }
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};
    Set<String> addedHelperIds = {}; // Track helpers already added to avoid duplicates

    // Add user marker (center, red)
    markers.add(
      Marker(
        markerId: MarkerId('user_location'),
        position: LatLng(widget.userLatitude, widget.userLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: 'Emergency SOS Location',
        ),
      ),
    );

    // Add real-time helper locations (green, priority - these are helpers who accepted)
    for (int i = 0; i < widget.helperLocations.length; i++) {
      final helper = widget.helperLocations[i];
      final lat = helper['latitude'];
      final lng = helper['longitude'];
      final helperId = helper['helperId']?.toString() ?? 'helper_$i';
      
      if (lat != null && lng != null) {
        final latitude = lat is double ? lat : (lat is String ? double.tryParse(lat) : lat as double?);
        final longitude = lng is double ? lng : (lng is String ? double.tryParse(lng) : lng as double?);
        
        if (latitude != null && longitude != null) {
          addedHelperIds.add(helperId);
          final distance = helper['distance'];
          final distanceText = distance != null 
              ? '${distance.toStringAsFixed(1)} km away'
              : 'Helper Location';
          
          markers.add(
            Marker(
              markerId: MarkerId('helper_location_$i'),
              position: LatLng(latitude, longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: helper['name']?.toString() ?? 'Helper',
                snippet: distanceText,
              ),
            ),
          );
        }
      }
    }

    // Add accepted helpers (if not already added from helperLocations)
    for (int i = 0; i < widget.helpers.length; i++) {
      final helper = widget.helpers[i];
      final helperId = helper['helperId']?.toString() ?? helper['_id']?.toString();
      
      // Skip if already added from helperLocations
      if (helperId != null && addedHelperIds.contains(helperId)) {
        continue;
      }
      
      final lat = helper['latitude'];
      final lng = helper['longitude'];
      
      if (lat != null && lng != null) {
        final latitude = lat is double ? lat : (lat is String ? double.tryParse(lat) : lat as double?);
        final longitude = lng is double ? lng : (lng is String ? double.tryParse(lng) : lng as double?);
        
        if (latitude != null && longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('helper_$i'),
              position: LatLng(latitude, longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: helper['name']?.toString() ?? 'Helper',
                snippet: helper['distance']?.toString() ?? 'Helper Location',
              ),
            ),
          );
        }
      }
    }

    // Add all active users with location enabled (green markers)
    for (int i = 0; i < widget.activeUsers.length; i++) {
      final user = widget.activeUsers[i];
      final userId = user['id']?.toString() ?? user['_id']?.toString() ?? 'user_$i';
      
      // Skip if already added as a helper
      if (addedHelperIds.contains(userId)) {
        continue;
      }
      
      final lat = user['latitude'];
      final lng = user['longitude'];
      
      if (lat != null && lng != null) {
        final latitude = lat is double ? lat : (lat is String ? double.tryParse(lat) : lat as double?);
        final longitude = lng is double ? lng : (lng is String ? double.tryParse(lng) : lng as double?);
        
        if (latitude != null && longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('active_user_$i'),
              position: LatLng(latitude, longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: user['name']?.toString() ?? 'Active User',
                snippet: 'Ready to help',
              ),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = markers;
    });
  }


  Future<void> _fitBounds() async {
    if (_mapController == null || _markers.isEmpty) return;

    double minLat = widget.userLatitude;
    double maxLat = widget.userLatitude;
    double minLng = widget.userLongitude;
    double maxLng = widget.userLongitude;

    for (var marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    // Add padding
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make map height responsive - use 40% of screen height but cap at 400px
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = (screenHeight * 0.4).clamp(250.0, 400.0);
    
    return Container(
      height: mapHeight,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Center on user location immediately
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(widget.userLatitude, widget.userLongitude),
                15, // Zoom level to clearly show current location
              ),
            );
            // Fit bounds to show all markers after a short delay
            Future.delayed(Duration(milliseconds: 500), () {
              if (_markers.isNotEmpty) {
                _fitBounds();
              }
            });
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.userLatitude, widget.userLongitude),
            zoom: 15, // Increased zoom to better show current location
          ),
          markers: _markers,
          myLocationEnabled: true, // Shows blue dot for current location
          myLocationButtonEnabled: true, // Shows button to center on location
          mapType: MapType.normal,
          zoomControlsEnabled: true,
          compassEnabled: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
