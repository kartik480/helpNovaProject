import 'package:flutter/material.dart';
import 'login_signup.dart';
import 'services/api_service.dart';

class ProfileScreen extends StatelessWidget{
  const ProfileScreen ({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
                  ),
                  SizedBox(height: 16),
                  FutureBuilder<String?>(
                    future: ApiService.getUserName(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Emergency Helper',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Profile Options
            _buildProfileOption(
              context,
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit profile coming soon')),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Help & Support coming soon')),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('About Help Nova')),
                );
              },
            ),
            
            SizedBox(height: 24),
            
            // Logout Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    // Clear stored token
                    await ApiService.removeToken();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginSignupScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        leading: Icon(icon, color: Colors.red),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}