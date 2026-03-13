import 'package:flutter/material.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});

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
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.local_hospital, color: Colors.white),
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
                        "Hello Karthik 👋",
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

                // Emergency SOS Box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: Offset(0,4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [

                      // SOS Icon
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      SizedBox(width: 12),

                      // SOS Text
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(
                              "Emergency SOS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Tap for immediate help",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            )
                          ]
                      )
                    ],
                  ),
                ),

                SizedBox(height: 25),

                Text(
                  "Emergency Services",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 15),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    serviceCard(Icons.local_hospital, "Ambulance"),
                    serviceCard(Icons.bloodtype, "Blood"),
                    serviceCard(Icons.favorite, "Medical"),
                    serviceCard(Icons.car_crash, "Accident"),
                    serviceCard(Icons.build, "Mechanic"),
                    serviceCard(Icons.electrical_services, "Electrician"),

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
    return Container(
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
            ),
          ),
        ],
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