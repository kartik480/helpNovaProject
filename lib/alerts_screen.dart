import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'emergency_sos_screen.dart';
import 'widgets/emergency_notification_dialog.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<dynamic> alerts = [];
  bool isLoading = true;

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
    if (alert['type'] == 'emergency_alert' && alert['latitude'] != null && alert['longitude'] != null) {
      // Show emergency dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => EmergencyNotificationDialog(
          userName: alert['userName'] ?? 'User',
          userPhone: alert['userPhone'] ?? '',
          latitude: alert['latitude'] as double,
          longitude: alert['longitude'] as double,
          description: alert['message'] ?? 'Emergency SOS request',
          requestId: alert['requestId'] ?? '',
        ),
      );
    } else if (alert['type'] == 'request_accepted') {
      // Navigate to emergency SOS screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmergencySosScreen(),
        ),
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
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : alerts.isEmpty
              ? Center(
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
                        'No alerts yet',
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
                )
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
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
                    },
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
