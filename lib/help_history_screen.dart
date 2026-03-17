import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/geocoding_service.dart';

class HelpHistoryScreen extends StatefulWidget {
  const HelpHistoryScreen({super.key});

  @override
  State<HelpHistoryScreen> createState() => _HelpHistoryScreenState();
}

class _HelpHistoryScreenState extends State<HelpHistoryScreen> {
  // Sample accepted help history data
  List<Map<String, dynamic>> _acceptedHelps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAcceptedHelps();
  }

  Future<void> _loadAcceptedHelps() async {
    // Simulate loading - in real app, fetch from API
    await Future.delayed(Duration(seconds: 1));
    
    setState(() {
      _acceptedHelps = [
        {
          'id': '1',
          'typeCode': 'medical',
          'title': 'Medical Emergency - Need Doctor',
          'description': 'Elderly person needed immediate medical attention. Successfully provided first aid and called ambulance.',
          'requesterName': 'Priya Sharma',
          'requesterPhone': '+91 98765 43210',
          'acceptedAt': DateTime.now().subtract(Duration(days: 2, hours: 5)),
          'completedAt': DateTime.now().subtract(Duration(days: 2, hours: 3)),
          'location': {
            'latitude': 13.6288 + 0.01,
            'longitude': 79.4192 + 0.01,
          },
          'status': 'completed',
          'pointsEarned': 5,
        },
        {
          'id': '2',
          'typeCode': 'blood',
          'title': 'Urgent Blood Donation Needed',
          'description': 'Patient required O+ blood urgently. Donated blood at hospital.',
          'requesterName': 'Raj Kumar',
          'requesterPhone': '+91 98765 43211',
          'acceptedAt': DateTime.now().subtract(Duration(days: 5, hours: 2)),
          'completedAt': DateTime.now().subtract(Duration(days: 5)),
          'location': {
            'latitude': 13.6288 - 0.015,
            'longitude': 79.4192 + 0.02,
          },
          'status': 'completed',
          'pointsEarned': 10,
        },
        {
          'id': '3',
          'typeCode': 'mechanic',
          'title': 'Vehicle Breakdown - Need Mechanic',
          'description': 'Car broke down on highway. Helped with basic repairs and arranged towing service.',
          'requesterName': 'Amit Patel',
          'requesterPhone': '+91 98765 43212',
          'acceptedAt': DateTime.now().subtract(Duration(days: 7)),
          'completedAt': DateTime.now().subtract(Duration(days: 7, hours: -1)),
          'location': {
            'latitude': 13.6288 + 0.02,
            'longitude': 79.4192 - 0.01,
          },
          'status': 'completed',
          'pointsEarned': 3,
        },
        {
          'id': '4',
          'typeCode': 'accident',
          'title': 'Road Accident - Immediate Help Needed',
          'description': 'Two-wheeler accident occurred. Provided first aid and helped coordinate with emergency services.',
          'requesterName': 'Vikram Singh',
          'requesterPhone': '+91 98765 43214',
          'acceptedAt': DateTime.now().subtract(Duration(days: 10)),
          'completedAt': DateTime.now().subtract(Duration(days: 10, hours: -2)),
          'location': {
            'latitude': 13.6288 + 0.005,
            'longitude': 79.4192 + 0.005,
          },
          'status': 'completed',
          'pointsEarned': 8,
        },
        {
          'id': '5',
          'typeCode': 'electrician',
          'title': 'Electrical Emergency at Home',
          'description': 'Power outage in building. Helped identify and fix electrical fault.',
          'requesterName': 'Sneha Reddy',
          'requesterPhone': '+91 98765 43213',
          'acceptedAt': DateTime.now().subtract(Duration(days: 12)),
          'completedAt': DateTime.now().subtract(Duration(days: 12, hours: -1)),
          'location': {
            'latitude': 13.6288 - 0.01,
            'longitude': 79.4192 - 0.015,
          },
          'status': 'completed',
          'pointsEarned': 4,
        },
      ];
      _isLoading = false;
    });
  }

  IconData _getIconForType(String typeCode) {
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

  Color _getColorForType(String typeCode) {
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _openNavigation(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open navigation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening navigation: $e')),
      );
    }
  }

  Future<void> _makeCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make phone call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making call: $e')),
      );
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadAcceptedHelps();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _acceptedHelps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Help History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your accepted help requests will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAcceptedHelps,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _acceptedHelps.length,
                    itemBuilder: (context, index) {
                      final help = _acceptedHelps[index];
                      return _buildHelpHistoryCard(help);
                    },
                  ),
                ),
    );
  }

  Widget _buildHelpHistoryCard(Map<String, dynamic> help) {
    final typeCode = help['typeCode'] as String;
    final icon = _getIconForType(typeCode);
    final color = _getColorForType(typeCode);
    final location = help['location'] as Map<String, dynamic>;
    final lat = location['latitude'] as double;
    final lng = location['longitude'] as double;
    final completedAt = help['completedAt'] as DateTime;
    final pointsEarned = help['pointsEarned'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and status
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        help['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            help['requesterName'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Description
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  help['description'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                
                // Location
                FutureBuilder<String?>(
                  future: GeocodingService.getShortAddress(lat, lng),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                          SizedBox(width: 4),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      );
                    }
                    
                    final address = snapshot.data;
                    return Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.red),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                SizedBox(height: 8),
                
                // Time and Points
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Text(
                          'Completed ${_formatDateTime(completedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '+$pointsEarned points',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeCall(help['requesterPhone'] as String),
                    icon: Icon(Icons.phone, color: Colors.white, size: 18),
                    label: Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openNavigation(lat, lng),
                    icon: Icon(Icons.navigation, color: Colors.white, size: 18),
                    label: Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
