import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertDetailScreen extends StatefulWidget {
  final String title;
  final String message;
  final double? latitude;
  final double? longitude;
  final String? userPhone;
  final String? userName;
  final IconData icon;
  final Color color;

  const AlertDetailScreen({
    super.key,
    required this.title,
    required this.message,
    this.latitude,
    this.longitude,
    this.userPhone,
    this.userName,
    required this.icon,
    required this.color,
  });

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  GoogleMapController? _mapController;
  LatLng? _location;

  @override
  void initState() {
    super.initState();
    // Use provided location or generate random location for demo
    if (widget.latitude != null && widget.longitude != null) {
      _location = LatLng(widget.latitude!, widget.longitude!);
    } else {
      // Generate random location (for demo purposes)
      _location = LatLng(
        13.6288 + (0.5 - (DateTime.now().millisecond % 1000) / 1000) * 0.1, // Random around Tirupati
        79.4192 + (0.5 - (DateTime.now().second % 60) / 60) * 0.1,
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _openNavigation() async {
    if (_location == null) return;
    
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_location!.latitude},${_location!.longitude}',
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open navigation')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening navigation: $e')),
        );
      }
    }
  }

  Future<void> _makeCall() async {
    final phoneNumber = widget.userPhone ?? '911';
    final url = Uri.parse('tel:$phoneNumber');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not make phone call')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making call: $e')),
        );
      }
    }
  }

  Future<void> _openChat() async {
    final phoneNumber = widget.userPhone ?? '';
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number not available')),
      );
      return;
    }
    
    // Open WhatsApp if available, otherwise SMS
    final whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');
    final smsUrl = Uri.parse('sms:$phoneNumber');
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open messaging app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              child: _location != null
                  ? GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _location!,
                        zoom: 15.0,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId('alert_location'),
                          position: _location!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                          infoWindow: InfoWindow(
                            title: widget.title,
                            snippet: widget.message,
                          ),
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                    )
                  : Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),
          
          // Alert Info Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Icon and Title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (widget.userName != null) ...[
                            SizedBox(height: 4),
                            Text(
                              'From: ${widget.userName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Message
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone,
                        label: 'Call',
                        color: Colors.green,
                        onTap: _makeCall,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.chat,
                        label: 'Chat',
                        color: Colors.blue,
                        onTap: _openChat,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.navigation,
                        label: 'Navigate',
                        color: Colors.red,
                        onTap: _openNavigation,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}
