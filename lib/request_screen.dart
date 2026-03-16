import 'package:flutter/material.dart';
import 'emergency_sos_screen.dart';
import 'medical_help_screen.dart';
import 'blood_donation_screen.dart';
import 'accident_help_screen.dart';
import 'ambulance_request_screen.dart';
import 'mechanic_help_screen.dart';
import 'electrician_help_screen.dart';
import 'volunteer_help_screen.dart';
import 'fire_emergency_screen.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Ready-made sample requests
  final List<Map<String, dynamic>> _activeRequests = [
    {
      'id': '1',
      'type': 'Medical',
      'title': 'Medical Emergency',
      'description': 'Patient experiencing severe chest pain and difficulty breathing',
      'location': '123 Main Street, Downtown',
      'distance': '1.2 km',
      'time': '5 min ago',
      'status': 'Active',
      'helpers': 2,
      'icon': Icons.local_hospital,
      'color': Colors.blue,
      'screen': MedicalHelpScreen(),
    },
    {
      'id': '2',
      'type': 'Blood',
      'title': 'Blood Donation Urgent',
      'description': 'Urgent need for O+ blood type for emergency surgery',
      'location': 'City Hospital, Medical Center',
      'distance': '3.5 km',
      'time': '15 min ago',
      'status': 'Active',
      'helpers': 1,
      'icon': Icons.bloodtype,
      'color': Colors.red,
      'screen': BloodDonationScreen(),
    },
    {
      'id': '3',
      'type': 'Emergency SOS',
      'title': 'Emergency SOS Alert',
      'description': 'Critical emergency - Immediate assistance required',
      'location': 'Highway 101, Exit 5',
      'distance': '2.8 km',
      'time': '8 min ago',
      'status': 'Active',
      'helpers': 3,
      'icon': Icons.sos,
      'color': Colors.red.shade800,
      'screen': EmergencySosScreen(),
    },
  ];

  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': '4',
      'type': 'Accident',
      'title': 'Road Accident Report',
      'description': 'Vehicle collision on Main Street, multiple people injured',
      'location': 'Main Street & 5th Avenue',
      'distance': '4.2 km',
      'time': '30 min ago',
      'status': 'Pending',
      'helpers': 0,
      'icon': Icons.car_crash,
      'color': Colors.orange,
      'screen': AccidentHelpScreen(),
    },
    {
      'id': '5',
      'type': 'Ambulance',
      'title': 'Ambulance Request',
      'description': 'Patient needs immediate ambulance transport to hospital',
      'location': 'Residential Area, Block 12',
      'distance': '5.1 km',
      'time': '45 min ago',
      'status': 'Pending',
      'helpers': 0,
      'icon': Icons.emergency,
      'color': Colors.red,
      'screen': AmbulanceRequestScreen(),
    },
    {
      'id': '6',
      'type': 'Mechanic',
      'title': 'Vehicle Breakdown',
      'description': 'Car broke down on highway, need mechanic assistance',
      'location': 'Highway 95, Mile Marker 42',
      'distance': '6.3 km',
      'time': '1 hour ago',
      'status': 'Pending',
      'helpers': 0,
      'icon': Icons.build,
      'color': Colors.brown,
      'screen': MechanicHelpScreen(),
    },
  ];

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
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRequestTypeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Request Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _buildRequestTypeOption(
                  Icons.local_hospital,
                  'Medical',
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalHelpScreen())),
                ),
                _buildRequestTypeOption(
                  Icons.bloodtype,
                  'Blood',
                  Colors.red,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => BloodDonationScreen())),
                ),
                _buildRequestTypeOption(
                  Icons.car_crash,
                  'Accident',
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccidentHelpScreen())),
                ),
                _buildRequestTypeOption(
                  Icons.emergency,
                  'Ambulance',
                  Colors.red,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AmbulanceRequestScreen())),
                ),
                _buildRequestTypeOption(
                  Icons.build,
                  'Mechanic',
                  Colors.brown,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => MechanicHelpScreen())),
                ),
                _buildRequestTypeOption(
                  Icons.electrical_services,
                  'Electrician',
                  Colors.yellow.shade700,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => ElectricianHelpScreen())),
                ),
                _buildRequestTypeOption(
                  Icons.people,
                  'Volunteer',
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => VolunteerHelpScreen())),
                ),
                _buildRequestTypeOption(
                  Icons.local_fire_department,
                  'Fire',
                  Colors.red.shade700,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => FireEmergencyScreen())),
                ),
                _buildRequestTypeOption(
                  Icons.sos,
                  'SOS',
                  Colors.red.shade800,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencySosScreen())),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTypeOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
          'My Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Active (${_activeRequests.length})'),
            Tab(text: 'Pending (${_pendingRequests.length})'),
            Tab(text: 'Completed (${_completedRequests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList(_activeRequests),
          _buildRequestList(_pendingRequests),
          _buildRequestList(_completedRequests),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestTypeDialog,
        backgroundColor: Colors.red,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRequestList(List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create a new request to get started',
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
    final status = request['status'] as String;
    final statusColor = status == 'Active'
        ? Colors.orange
        : status == 'Pending'
            ? Colors.blue
            : Colors.green;

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
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
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
                  Spacer(),
                  if (status == 'Active' || status == 'Pending')
                    TextButton.icon(
                      onPressed: () {
                        _showRequestActions(request);
                      },
                      icon: Icon(Icons.more_vert, size: 16),
                      label: Text('Actions'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  void _showRequestActions(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              request['title'] as String,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.visibility, color: Colors.blue),
              title: Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                final screen = request['screen'] as Widget;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => screen),
                );
              },
            ),
            if (request['status'] == 'Active')
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.orange),
                title: Text('Cancel Request'),
                onTap: () {
                  Navigator.pop(context);
                  _showCancelConfirmation(request);
                },
              ),
            if (request['status'] == 'Pending')
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Mark as Active'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Request marked as active'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.blue),
              title: Text('Share Request'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request shared'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Request?'),
        content: Text('Are you sure you want to cancel this request? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request cancelled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
