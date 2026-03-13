import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'register_screen.dart';


class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],

      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 80),

            // Logo
            Column(
              children: [

                const SizedBox(height: 80),

                SizedBox(
                  height: 110,
                  child: Image.asset(
                    "images/logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),

            const SizedBox(height: 1),

            const Text(
              "Help Nova",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),

            const Text(
              "A hyperlocal emergency app",
              style: TextStyle(color: Colors.red),
            ),

            const SizedBox(height: 30),

            loginCard(),

            const SizedBox(height: 20),

            socialLogin(),

          ],
        ),
      ),
    );
  }
//login card//
  Widget loginCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          //for shadow glow //
          BoxShadow(
            color: Colors.red.withOpacity(0.25), // glow color
            blurRadius: 25,  // softness of glow
            spreadRadius: 2, // size of glow
            offset: Offset(0, 8), // shadow direction
          ),
        ],
      ),

      child: Column(
        children: [

          TabBar(
            controller: _tabController,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red,
            tabs: const [
              Tab(text: "Login"),
              Tab(text: "Sign Up"),

            ],

          ),



          const SizedBox(height: 20),

          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tabController,
              children: [
                loginForm(),   // your existing login UI
                signUpForm(),  // new signup UI
              ],
            ),
          ),





        ],
      ),
    );
  }

  //social login section //
  Widget socialLogin() {
    return Column(
      children: [

        const Text("Or continue with"),

        const SizedBox(height: 15),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(Icons.g_mobiledata, size: 30),
            ),

            const SizedBox(width: 20),

            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(Icons.apple),
            ),

          ],
        ),

        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "By joining, you agree to Help Nova's Terms of Service and Privacy Policy.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        )
      ],
    );
  }

  //login form//
  Widget loginForm() {
    return Column(
      children: [

        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.phone),
            hintText: "Enter phone number",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelText: "PHONE NUMBER",
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock),
            hintText: "********",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelText: "PASSWORD",
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(value: false, onChanged: (v) {}),
                Text("Remember me"),
              ],
            ),
            Text(
              "Forgot?",
              style: TextStyle(color: Colors.red),
            )
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder:(context)=> HomeScreen()),
              );
            },
            child: const Text("Sign In"),
          ),
        ),

      ],
    );
  }

  //signup form//
  Widget signUpForm() {
  return Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Full Name",
              ),
            ),

            SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Email"
              ),
            ),

            SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Phone",
              ),
            ),

            SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Password",
              ),
            ),

            SizedBox(height: 30),

            ElevatedButton(
              onPressed: (){},
              child: Text("Sign Up"),
            )
          ],
        )
      ),
      )
    )
  );
  }





}