import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'services/api_service.dart';
import 'emergency_sos_screen.dart';
import 'medical_help_screen.dart';
import 'blood_donation_screen.dart';
import 'accident_help_screen.dart';
import 'ambulance_request_screen.dart';
import 'mechanic_help_screen.dart';
import 'electrician_help_screen.dart';
import 'volunteer_help_screen.dart';
import 'fire_emergency_screen.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await ApiService.getUserName();
    setState(() {
      userName = name ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            //TOP BAR - Fixed at top //
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Row(
                    children: [
                      Image.asset(
                        'images/logo.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),

                      SizedBox(width: 8),

                      Text(
                        "Help Nova",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Icon(Icons.notifications_none),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
            // Scrollable content //
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),

                // GREETING CARD
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello ${userName ?? 'User'} 👋",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text("Stay safe and help others in need"),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Emergency SOS Box - Big and Visible
                GestureDetector(
                  onTap: () {
                    // Navigate to Emergency SOS screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmergencySosScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 4,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // SOS Siren Icon
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.emergency,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),

                        SizedBox(width: 16),

                        // SOS Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "EMERGENCY SOS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Request Immediate Help",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 25),

                Text(
                  "Emergency Service Categories",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 15),

                // Main Services Grid (2x3)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    serviceCard(Icons.local_hospital, "Medical Help"),
                    serviceCard(Icons.bloodtype, "Blood Donation"),
                    serviceCard(Icons.car_crash, "Accident Help"),
                    serviceCard(Icons.emergency, "Ambulance"),
                    serviceCard(Icons.build, "Mechanic Help"),
                    serviceCard(Icons.electrical_services, "Electrician"),
                  ],
                ),

                SizedBox(height: 20),

                // Optional Extra Services
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    serviceCard(Icons.people, "Volunteer Help"),
                    serviceCard(Icons.local_fire_department, "Fire Emergency"),
                  ],
                ),
                SizedBox(height: 25),

                //nearby request section //
                Text("Nearby Requests", style: TextStyle(fontSize: 18 , fontWeight: FontWeight.bold,),),
                SizedBox(height: 15),
                Column(
                  children: [
                    requestCard(
                      "Blood needed",
                      "O+ required",
                      "2 Km",
                      Icons.bloodtype,
                      Colors.red,
                    ),
                  ],
                )

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home),label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on),label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.request_page),label: "Request"),
          BottomNavigationBarItem(icon: Icon(Icons.person),label: "Profile"),
        ],
      ),
    );
  }

  // ✅ SERVICE CARD WIDGET
  Widget serviceCard(IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        // Navigate to service-specific screen
        if (title == "Medical Help") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MedicalHelpScreen()),
          );
        } else if (title == "Blood Donation") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BloodDonationScreen()),
          );
        } else if (title == "Accident Help") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccidentHelpScreen()),
          );
        } else if (title == "Ambulance") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AmbulanceRequestScreen()),
          );
        } else if (title == "Mechanic Help") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MechanicHelpScreen()),
          );
        } else if (title == "Electrician") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ElectricianHelpScreen()),
          );
        } else if (title == "Volunteer Help") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VolunteerHelpScreen()),
          );
        } else if (title == "Fire Emergency") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FireEmergencyScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0,2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.red),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  // ✅ REQUEST CARD WIDGET //
  Widget requestCard(String title, String description, String distance, IconData icon, Color color){
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0,2),
            )
          ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold
                  )

                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey
                  )
                ),
              ],
            ),
          ),
        ]
      ),
    );


  }

}