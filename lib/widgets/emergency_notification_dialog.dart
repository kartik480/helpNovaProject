import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/api_service.dart';

class EmergencyNotificationDialog extends StatefulWidget {
  final String userName;
  final String userPhone;
  final double latitude;
  final double longitude;
  final String description;
  final String requestId;

  const EmergencyNotificationDialog({
    super.key,
    required this.userName,
    required this.userPhone,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.requestId,
  });

  @override
  State<EmergencyNotificationDialog> createState() => _EmergencyNotificationDialogState();
}

class _EmergencyNotificationDialogState extends State<EmergencyNotificationDialog> {
  Timer? _locationUpdateTimer;
  bool _isUpdatingLocation = false;

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  // Start sending location updates for accepted request
  void _startLocationUpdates(String requestId) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _isUpdatingLocation) return;
      
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _isUpdatingLocation = true;
        });
        
        await ApiService.updateHelperLocation(
          requestId: requestId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        setState(() {
          _isUpdatingLocation = false;
        });
        
        print('[Helper] Updated location for request $requestId: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('[Helper] Error updating location: $e');
        setState(() {
          _isUpdatingLocation = false;
        });
      }
    });
  }

  Future<void> _acceptRequest(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get current location first
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('Error getting location: $e');
      }

      // Call the API to accept the emergency request
      final result = await ApiService.acceptEmergencyRequest(widget.requestId);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        if (result['success'] == true) {
          // Send initial location update if available
          if (currentPosition != null) {
            try {
              await ApiService.updateHelperLocation(
                requestId: widget.requestId,
                latitude: currentPosition.latitude,
                longitude: currentPosition.longitude,
              );
              print('[Helper] Sent initial location after accepting request');
            } catch (e) {
              print('[Helper] Error sending initial location: $e');
            }
          }
          
          // Start periodic location updates
          _startLocationUpdates(widget.requestId);
          
          Navigator.pop(context); // Close notification dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Request accepted! Your location is being shared.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Don't close dialog on error, let user try again
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error accepting request'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _callUser(BuildContext context) async {
    final uri = Uri.parse('tel:${widget.userPhone}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot make phone call')),
        );
      }
    }
  }

  Future<void> _navigateToLocation(BuildContext context) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade600,
              Colors.red.shade800,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emergency Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              '🚨 Emergency SOS Alert',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // User Name
            Text(
              '${widget.userName} needs immediate help!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Description
            if (widget.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                // Decline Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Accept Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Accept Help',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _callUser(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Call',
                ),
                IconButton(
                  onPressed: () => _navigateToLocation(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Navigate',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
