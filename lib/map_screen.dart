import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: Text(
          'Emergency Map',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Search functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Placeholder for map
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 80,
                  color: Colors.grey[600],
                ),
                SizedBox(height: 16),
                Text(
                  'Map View',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Emergency requests will be shown here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Floating action buttons
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "location",
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Locating your position...')),
                    );
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: Colors.red),
                ),
                SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "filter",
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Filter options coming soon')),
                    );
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.filter_list, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
