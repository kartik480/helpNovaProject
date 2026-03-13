import 'package:flutter/material.dart';
import 'login_signup.dart';

class ProfileScreen extends StatelessWidget{
  const ProfileScreen ({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Account"),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 40 , vertical: 15),
          ),
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginSignupScreen(),
              ),
            );
          },

          child: Text(
            "LogOut",
            style: TextStyle(fontSize: 16),
          ),
        )
      )
    );
  }
}