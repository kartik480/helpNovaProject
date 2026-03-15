import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

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
            icon: Icon(Icons.check_circle_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mark all as read')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildAlertCard(
            'Emergency Request Nearby',
            'Blood donation needed within 2 km',
            '2 minutes ago',
            Icons.bloodtype,
            Colors.red,
            isUnread: true,
          ),
          _buildAlertCard(
            'Request Accepted',
            'Your medical help request has been accepted',
            '15 minutes ago',
            Icons.check_circle,
            Colors.green,
            isUnread: true,
          ),
          _buildAlertCard(
            'New Volunteer Available',
            'A volunteer is available in your area',
            '1 hour ago',
            Icons.people,
            Colors.blue,
            isUnread: false,
          ),
          _buildAlertCard(
            'Request Completed',
            'Your ambulance request has been completed',
            '2 hours ago',
            Icons.done_all,
            Colors.green,
            isUnread: false,
          ),
          _buildAlertCard(
            'System Update',
            'New features available in Help Nova',
            '1 day ago',
            Icons.info,
            Colors.orange,
            isUnread: false,
          ),
        ],
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
    );
  }
}
