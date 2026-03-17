import 'package:flutter/material.dart';
import 'medical_help_screen.dart';
import 'blood_donation_screen.dart';
import 'electrician_help_screen.dart';
import 'volunteer_help_screen.dart';
import 'fire_emergency_screen.dart';

class CompletedRequestsScreen extends StatefulWidget {
  const CompletedRequestsScreen({super.key});

  @override
  State<CompletedRequestsScreen> createState() => _CompletedRequestsScreenState();
}

class _CompletedRequestsScreenState extends State<CompletedRequestsScreen> {
  // Completed requests data
  final List<Map<String, dynamic>> _completedRequests = [
    {
      'id': '7',
      'type': 'Electrician',
      'title': 'Electrical Emergency',
      'description': 'Power outage in building, electrical system needs repair',
      'location': 'Commercial Building, Floor 3',
      'distance': '2.1 km',
      'time': '2 hours ago',
      'status': 'Completed',
      'helpers': 1,
      'icon': Icons.electrical_services,
      'color': Colors.yellow.shade700,
      'screen': ElectricianHelpScreen(),
    },
    {
      'id': '8',
      'type': 'Volunteer',
      'title': 'Community Service',
      'description': 'Help needed for community cleanup event',
      'location': 'Community Park, Central Area',
      'distance': '1.8 km',
      'time': '3 hours ago',
      'status': 'Completed',
      'helpers': 5,
      'icon': Icons.people,
      'color': Colors.green,
      'screen': VolunteerHelpScreen(),
    },
    {
      'id': '9',
      'type': 'Fire',
      'title': 'Fire Emergency',
      'description': 'Small fire in kitchen, now extinguished',
      'location': 'Residential Building, Apartment 4B',
      'distance': '3.7 km',
      'time': '5 hours ago',
      'status': 'Completed',
      'helpers': 2,
      'icon': Icons.local_fire_department,
      'color': Colors.red.shade700,
      'screen': FireEmergencyScreen(),
    },
    {
      'id': '10',
      'type': 'Medical',
      'title': 'Medical Emergency Resolved',
      'description': 'Patient stabilized and transported to hospital',
      'location': 'City Hospital, Emergency Ward',
      'distance': '4.5 km',
      'time': '1 day ago',
      'status': 'Completed',
      'helpers': 3,
      'icon': Icons.local_hospital,
      'color': Colors.blue,
      'screen': MedicalHelpScreen(),
    },
    {
      'id': '11',
      'type': 'Blood',
      'title': 'Blood Donation Completed',
      'description': 'Blood donation successful, patient received required blood',
      'location': 'Blood Bank, Medical Center',
      'distance': '2.3 km',
      'time': '2 days ago',
      'status': 'Completed',
      'helpers': 2,
      'icon': Icons.bloodtype,
      'color': Colors.red,
      'screen': BloodDonationScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: Text(
          'Completed Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _buildRequestList(_completedRequests),
    );
  }

  Widget _buildRequestList(List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No completed requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Completed requests will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(requests[index]);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to the appropriate screen
          final screen = request['screen'] as Widget;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (request['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      request['icon'] as IconData,
                      color: request['color'] as Color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 12, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            if (request['helpers'] as int > 0)
                              Row(
                                children: [
                                  Icon(Icons.people, size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    '${request['helpers']} helper${request['helpers'] > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              SizedBox(height: 12),
              Text(
                request['description'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request['location'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 12),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        request['distance'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    request['time'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
