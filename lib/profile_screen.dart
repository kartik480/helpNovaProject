import 'package:flutter/material.dart';
import 'login_signup.dart';
import 'services/api_service.dart';
import 'edit_profile_screen.dart';
import 'help_history_screen.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userName;
  int _userPoints = 0;
  String _userRank = 'Bronze Helper';
  
  // Sample leaderboard data
  final List<Map<String, dynamic>> _leaderboard = [
    {'name': 'Rahul', 'points': 20, 'rank': 'Gold Helper'},
    {'name': 'Priya', 'points': 17, 'rank': 'Silver Helper'},
    {'name': 'Arjun', 'points': 12, 'rank': 'Silver Helper'},
    {'name': 'Sneha', 'points': 10, 'rank': 'Bronze Helper'},
    {'name': 'Vikram', 'points': 8, 'rank': 'Bronze Helper'},
    {'name': 'Ananya', 'points': 5, 'rank': 'Bronze Helper'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final name = await ApiService.getUserName();
    // Simulate user points (in real app, fetch from backend)
    final random = Random();
    final points = random.nextInt(15) + 1; // Random points between 1-15
    final rank = _getRankFromPoints(points);
    
    setState(() {
      _userName = name;
      _userPoints = points;
      _userRank = rank;
    });
  }

  String _getRankFromPoints(int points) {
    if (points >= 25) return 'Community Hero';
    if (points >= 15) return 'Gold Helper';
    if (points >= 8) return 'Silver Helper';
    return 'Bronze Helper';
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Community Hero':
        return Colors.purple;
      case 'Gold Helper':
        return Colors.amber;
      case 'Silver Helper':
        return Colors.grey.shade600;
      case 'Bronze Helper':
        return Colors.brown.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getRankIcon(String rank) {
    switch (rank) {
      case 'Community Hero':
        return Icons.stars;
      case 'Gold Helper':
        return Icons.emoji_events;
      case 'Silver Helper':
        return Icons.military_tech;
      case 'Bronze Helper':
        return Icons.workspace_premium;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              backgroundColor: Colors.red,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red.shade600, Colors.red.shade800],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Profile Avatar with Rank Badge
                          Stack(
                            children: [
                              Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      _getRankColor(_userRank),
                                      _getRankColor(_userRank).withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 42,
                                    backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=${_userName?.hashCode ?? 1}"),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: _getRankColor(_userRank),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    _getRankIcon(_userRank),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            _userName ?? 'User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getRankColor(_userRank).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getRankColor(_userRank),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRankIcon(_userRank),
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _userRank,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Stats Cards
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Points',
                      '$_userPoints',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Assists',
                      '$_userPoints',
                      Icons.handshake,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Rank',
                      '#${_getUserRankPosition()}',
                      Icons.leaderboard,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.red,
                labelColor: Colors.red,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Leaderboard'),
                  Tab(text: 'Profile'),
                ],
              ),
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboardTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  int _getUserRankPosition() {
    // Find user's position in leaderboard
    final sortedLeaderboard = List<Map<String, dynamic>>.from(_leaderboard)
      ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    
    // Add user to list if not already there
    final userIndex = sortedLeaderboard.indexWhere((entry) => entry['name'] == _userName);
    if (userIndex == -1) {
      sortedLeaderboard.add({
        'name': _userName ?? 'You',
        'points': _userPoints,
        'rank': _userRank,
      });
      sortedLeaderboard.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    }
    
    return sortedLeaderboard.indexWhere((entry) => entry['name'] == _userName) + 1;
  }

  Widget _buildLeaderboardTab() {
    // Sort leaderboard by points
    final sortedLeaderboard = List<Map<String, dynamic>>.from(_leaderboard)
      ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    
    // Add current user to leaderboard
    final userEntry = {
      'name': _userName ?? 'You',
      'points': _userPoints,
      'rank': _userRank,
      'isCurrentUser': true,
    };
    
    // Check if user is already in leaderboard
    final userIndex = sortedLeaderboard.indexWhere((entry) => entry['name'] == _userName);
    if (userIndex == -1) {
      sortedLeaderboard.add(userEntry);
      sortedLeaderboard.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    } else {
      sortedLeaderboard[userIndex]['isCurrentUser'] = true;
    }

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.amber.shade600],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'Top Helpers',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Leaderboard List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: sortedLeaderboard.length,
              itemBuilder: (context, index) {
                final entry = sortedLeaderboard[index];
                final isCurrentUser = entry['isCurrentUser'] == true;
                final rank = index + 1;
                
                return _buildLeaderboardItem(
                  rank: rank,
                  name: entry['name'] as String,
                  points: entry['points'] as int,
                  rankTitle: entry['rank'] as String,
                  isCurrentUser: isCurrentUser,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    required int points,
    required String rankTitle,
    required bool isCurrentUser,
  }) {
    IconData rankIcon;
    Color rankColor;
    
    switch (rank) {
      case 1:
        rankIcon = Icons.emoji_events;
        rankColor = Colors.amber;
        break;
      case 2:
        rankIcon = Icons.workspace_premium;
        rankColor = Colors.grey.shade600;
        break;
      case 3:
        rankIcon = Icons.military_tech;
        rankColor = Colors.brown.shade600;
        break;
      default:
        rankIcon = Icons.star;
        rankColor = Colors.grey.shade400;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: Colors.red, width: 2)
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: rank <= 3 ? rankColor.withOpacity(0.2) : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: rank <= 3
                ? Border.all(color: rankColor, width: 2)
                : null,
          ),
          child: Center(
            child: rank <= 3
                ? Icon(rankIcon, color: rankColor, size: 24)
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
                color: isCurrentUser ? Colors.red : Colors.grey[800],
              ),
            ),
            if (isCurrentUser) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getRankIcon(rankTitle),
                  size: 14,
                  color: _getRankColor(rankTitle),
                ),
                SizedBox(width: 4),
                Text(
                  rankTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRankColor(rankTitle),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handshake, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text(
                '$points',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 2),
              Text(
                'assists',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 16),
          
          // Progress to Next Rank
          _buildNextRankCard(),
          
          SizedBox(height: 16),
          
          // Profile Options
          _buildProfileOption(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(),
                ),
              );
              if (result == true) {
                _loadUserData();
              }
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.history,
            title: 'Help History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HelpHistoryScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.workspace_premium,
            title: 'Achievements',
            onTap: () {
              _showAchievementsDialog();
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
              _showAboutDialog();
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
    );
  }

  Widget _buildNextRankCard() {
    int nextRankPoints;
    String nextRank;
    
    if (_userPoints < 8) {
      nextRankPoints = 8;
      nextRank = 'Silver Helper';
    } else if (_userPoints < 15) {
      nextRankPoints = 15;
      nextRank = 'Gold Helper';
    } else if (_userPoints < 25) {
      nextRankPoints = 25;
      nextRank = 'Community Hero';
    } else {
      nextRankPoints = 25;
      nextRank = 'Community Hero';
    }
    
    final progress = _userPoints >= nextRankPoints
        ? 1.0
        : _userPoints / nextRankPoints;
    final pointsNeeded = nextRankPoints - _userPoints;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRankColor(nextRank).withOpacity(0.1),
            _getRankColor(nextRank).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getRankColor(nextRank).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRankIcon(nextRank),
                color: _getRankColor(nextRank),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Next Rank: $nextRank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getRankColor(nextRank),
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_userPoints / $nextRankPoints points',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              if (pointsNeeded > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text(
                    '$pointsNeeded more to unlock',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showAchievementsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏆 Achievements',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildAchievementItem('First Help', 'Help someone for the first time', _userPoints > 0),
              _buildAchievementItem('Bronze Helper', 'Reach 5 assists', _userPoints >= 5),
              _buildAchievementItem('Silver Helper', 'Reach 8 assists', _userPoints >= 8),
              _buildAchievementItem('Gold Helper', 'Reach 15 assists', _userPoints >= 15),
              _buildAchievementItem('Community Hero', 'Reach 25 assists', _userPoints >= 25),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, bool unlocked) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.lock,
            color: unlocked ? Colors.green : Colors.grey,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.green.shade700 : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.red),
            SizedBox(width: 8),
            Text('About Help Nova'),
          ],
        ),
        content: Text(
          'Help Nova is a hyperlocal emergency response app that connects people in need with nearby helpers. '
          'Earn points and climb the leaderboard by helping others in your community!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
