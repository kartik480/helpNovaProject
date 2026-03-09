import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'register_screen.dart';
class SplashScreen extends StatelessWidget{
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build 
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Image.asset(
                "images/logo.png",
                height: 120,
              ),
            ),
            const SizedBox(height: 20),
            //App name
            const Text(
              "Help Nova",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 40),

            //phone no field
            TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "phone number",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            //password field
            TextField(
            obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            //Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    )
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                ),
                child: const Text("Login" , style: TextStyle(fontSize: 18),),
              ),
            ),
            const SizedBox(height: 20),
            //Sign up button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                  TextButton(
                    onPressed: (){
                      Navigator.push(
                        context ,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        )
                      );
                    },
                    child: const Text("Sign Up"),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}