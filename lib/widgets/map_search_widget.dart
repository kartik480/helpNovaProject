import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/geocoding_service.dart';

class MapSearchWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double latitude, double longitude, String address) onLocationSelected;

  const MapSearchWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<MapSearchWidget> createState() => _MapSearchWidgetState();
}

class _MapSearchWidgetState extends State<MapSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _controller;
  
  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _isLoadingLocation = false;
  
  double? _selectedLatitude;
  double? _longitude;
  String? _selectedAddress;
  Marker? _selectedMarker;
  
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _selectedAddress = widget.initialAddress;
    
    if (_selectedLatitude != null && _longitude != null) {
      _updateMarker(_selectedLatitude!, _longitude!);
    } else {
      _getCurrentLocation();
    }
    
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _addressSuggestions = [];
      });
      return;
    }

    final results = await GeocodingService.searchAddresses(query);
    
    if (mounted) {
      setState(() {
        _addressSuggestions = results;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission permanently denied')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: kIsWeb ? const Duration(seconds: 10) : const Duration(seconds: 15),
      );

      final address = await GeocodingService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _selectedLatitude = position.latitude;
          _longitude = position.longitude;
          _selectedAddress = address ?? 'Current Location';
          _searchController.text = _selectedAddress ?? '';
        });
        
        _updateMarker(_selectedLatitude!, _longitude!);
        _moveCamera(_selectedLatitude!, _longitude!);
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _selectAddress(Map<String, dynamic> addressData) async {
    final lat = addressData['latitude'] as double;
    final lng = addressData['longitude'] as double;
    final address = addressData['address'] as String;

    setState(() {
      _selectedLatitude = lat;
      _longitude = lng;
      _selectedAddress = address;
      _searchController.text = address;
      _addressSuggestions = [];
    });

    _updateMarker(lat, lng);
    _moveCamera(lat, lng);
  }

  void _updateMarker(double lat, double lng) {
    setState(() {
      _selectedMarker = Marker(
        markerId: MarkerId('selected_location'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });
  }

  Future<void> _moveCamera(double lat, double lng) async {
    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0),
      );
    }
  }

  void _onMapTap(LatLng position) async {
    final address = await GeocodingService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _selectedLatitude = position.latitude;
      _longitude = position.longitude;
      _selectedAddress = address ?? 'Selected Location';
      _searchController.text = _selectedAddress ?? '';
    });

    _updateMarker(position.latitude, position.longitude);
  }

  void _onOkPressed() {
    if (_selectedLatitude != null && _longitude != null && _selectedAddress != null) {
      widget.onLocationSelected(_selectedLatitude!, _longitude!, _selectedAddress!);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for address...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _isLoadingLocation
                        ? Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: Icon(Icons.my_location),
                            onPressed: _getCurrentLocation,
                            tooltip: 'Use current location',
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // Address Suggestions Dropdown
                if (_addressSuggestions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _addressSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _addressSuggestions[index];
                        return ListTile(
                          leading: Icon(Icons.location_on, color: Colors.red),
                          title: Text(
                            suggestion['address'] as String,
                            style: TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectAddress(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _selectedLatitude ?? 28.6139,
                      _longitude ?? 77.2090,
                    ),
                    zoom: _selectedLatitude != null ? 15.0 : 10.0,
                  ),
                  markers: _selectedMarker != null ? {_selectedMarker!} : {},
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                    if (_selectedLatitude != null && _longitude != null) {
                      _moveCamera(_selectedLatitude!, _longitude!);
                    }
                  },
                  onTap: _onMapTap,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomGesturesEnabled: true, // Enable pinch-to-zoom
                  scrollGesturesEnabled: true, // Enable pan/scroll gestures
                  tiltGesturesEnabled: true, // Enable tilt gestures
                  rotateGesturesEnabled: true, // Enable rotation gestures
                ),
                
                // Center indicator
                Center(
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          
          // OK Button
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _onOkPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
