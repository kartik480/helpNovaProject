import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<dynamic> alerts = [];
  bool isLoading = true;

  // Ready-made alert list items with functionality
  final List<Map<String, dynamic>> _readyMadeAlerts = [
    {
      'title': 'Medical Emergency Nearby',
      'message': 'Someone needs immediate medical assistance',
      'icon': Icons.local_hospital,
      'color': Colors.blue,
      'type': 'medical',
      'action': 'open_medical',
    },
    {
      'title': 'Blood Donation Request',
      'message': 'Urgent blood donation needed - Type O+',
      'icon': Icons.bloodtype,
      'color': Colors.red,
      'type': 'blood',
      'action': 'open_blood',
    },
    {
      'title': 'Accident Reported',
      'message': 'Road accident detected in your area',
      'icon': Icons.car_crash,
      'color': Colors.orange,
      'type': 'accident',
      'action': 'open_accident',
    },
    {
      'title': 'Ambulance Request',
      'message': 'Patient needs immediate ambulance service',
      'icon': Icons.emergency,
      'color': Colors.red,
      'type': 'ambulance',
      'action': 'open_ambulance',
    },
    {
      'title': 'Vehicle Breakdown',
      'message': 'Help needed for vehicle repair',
      'icon': Icons.build,
      'color': Colors.brown,
      'type': 'mechanic',
      'action': 'open_mechanic',
    },
    {
      'title': 'Electrical Emergency',
      'message': 'Electrical issue requires immediate attention',
      'icon': Icons.electrical_services,
      'color': Colors.yellow.shade700,
      'type': 'electrician',
      'action': 'open_electrician',
    },
    {
      'title': 'Volunteer Needed',
      'message': 'Community service opportunity available',
      'icon': Icons.people,
      'color': Colors.green,
      'type': 'volunteer',
      'action': 'open_volunteer',
    },
    {
      'title': 'Fire Emergency Alert',
      'message': 'Fire reported in nearby location',
      'icon': Icons.local_fire_department,
      'color': Colors.red.shade700,
      'type': 'fire',
      'action': 'open_fire',
    },
    {
      'title': 'Emergency SOS',
      'message': 'Critical emergency - Immediate help required',
      'icon': Icons.sos,
      'color': Colors.red,
      'type': 'sos',
      'action': 'open_sos',
    },
    {
      'title': 'Call Emergency Services',
      'message': 'Tap to call 911 or local emergency number',
      'icon': Icons.phone,
      'color': Colors.red.shade800,
      'type': 'call',
      'action': 'call_emergency',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      isLoading = true;
    });

    final result = await ApiService.getAlerts();
    
    if (mounted) {
      setState(() {
        isLoading = false;
        if (result['success'] == true) {
          alerts = result['alerts'] ?? [];
        } else {
          alerts = [];
        }
      });
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'emergency_alert':
        return Icons.emergency;
      case 'request_accepted':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'emergency_alert':
        return Colors.red;
      case 'request_accepted':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _handleAlertTap(dynamic alert) {
    // Navigate to alert detail screen with map and action buttons
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertDetailScreen(
          title: alert['title'] ?? 'Alert',
          message: alert['message'] ?? '',
          latitude: alert['latitude'] != null ? (alert['latitude'] as num).toDouble() : null,
          longitude: alert['longitude'] != null ? (alert['longitude'] as num).toDouble() : null,
          userPhone: alert['userPhone']?.toString(),
          userName: alert['userName']?.toString(),
          icon: _getIconForType(alert['type'] ?? ''),
          color: _getColorForType(alert['type'] ?? ''),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: Text(
          'Alerts & Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAlerts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Ready-made alerts section
            if (_readyMadeAlerts.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              ..._readyMadeAlerts.map((alert) => _buildReadyMadeAlertCard(
                alert['title'] as String,
                alert['message'] as String,
                alert['icon'] as IconData,
                alert['color'] as Color,
                onTap: () {
                  // Navigate to alert detail screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlertDetailScreen(
                        title: alert['title'] as String,
                        message: alert['message'] as String,
                        latitude: null, // Will generate random location
                        longitude: null,
                        userPhone: null,
                        userName: null,
                        icon: alert['icon'] as IconData,
                        color: alert['color'] as Color,
                      ),
                    ),
                  );
                },
              )),
              SizedBox(height: 24),
              Divider(thickness: 2),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
            // Real alerts from API
            if (isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (alerts.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No recent alerts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You will see emergency alerts here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...alerts.map((alert) {
                final timestamp = alert['timestamp'] != null
                    ? DateTime.parse(alert['timestamp'])
                    : DateTime.now();
                
                return _buildAlertCard(
                  alert['title'] ?? 'Alert',
                  alert['message'] ?? '',
                  _formatTime(timestamp),
                  _getIconForType(alert['type'] ?? ''),
                  _getColorForType(alert['type'] ?? ''),
                  isUnread: !(alert['isRead'] ?? false),
                  onTap: () => _handleAlertTap(alert),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyMadeAlertCard(
    String title,
    String message,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tap to open',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: color),
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    String message,
    String time,
    IconData icon,
    Color color, {
    required bool isUnread,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUnread
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }
}
