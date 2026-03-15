import 'package:flutter/material.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList('Active'),
          _buildRequestList('Pending'),
          _buildRequestList('Completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create request screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigate to create request')),
          );
        },
        backgroundColor: Colors.red,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Request',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRequestList(String status) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: status == 'Active' ? 2 : status == 'Pending' ? 1 : 0,
      itemBuilder: (context, index) {
        return _buildRequestCard(status, index);
      },
    );
  }

  Widget _buildRequestCard(String status, int index) {
    Color statusColor = status == 'Active'
        ? Colors.orange
        : status == 'Pending'
            ? Colors.blue
            : Colors.green;

    IconData statusIcon = status == 'Active'
        ? Icons.access_time
        : status == 'Pending'
            ? Icons.pending
            : Icons.check_circle;

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
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          'Medical Help Request',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Patient condition: Chest pain'),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('2.5 km away', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
