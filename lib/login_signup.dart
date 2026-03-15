import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'services/api_service.dart';


class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  int _currentTabIndex = 0;
  double _loginFormHeight = 280; // Will be calculated
  double _signupFormHeight = 650; // Will be calculated
  
  // Login form controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  
  // Signup form controllers
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPhoneController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupConfirmPasswordController = TextEditingController();
  
  // Signup form state
  String? _selectedBloodGroup;
  String? _selectedSkill;
  bool _locationAllowed = false;
  bool _isLoading = false;
  
  // Blood groups list
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  
  // Skills list
  final List<String> _skills = [
    'First Aid',
    'CPR',
    'Medical Professional',
    'Fire Safety',
    'Search & Rescue',
    'Emergency Response',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Calculate form heights based on content
    // Login form: 2 text fields (56px each) + spacing (12px) + remember me row (40px) + spacing (12px) + button (50px) = ~230px + padding
    _loginFormHeight = 280;
    
    // Signup form: 5 text fields (56px each) + 2 dropdowns (56px each) + spacing (12px between each) + location button (50px) + create button (50px) = ~600px + padding
    _signupFormHeight = 650;
    
    _tabController.addListener(() {
      if (_currentTabIndex != _tabController.index) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    
    // Measure after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeights();
    });
  }

  void _calculateHeights() {
    // Login form calculation (with isDense: true, fields are ~52px):
    // Email field: ~52px
    // Spacing: 12px
    // Password field: ~52px
    // Spacing: 8px
    // Remember me row: ~40px
    // Spacing: 12px
    // Sign In button: ~50px
    // Total: 52 + 12 + 52 + 8 + 40 + 12 + 50 = 226px, add 20px padding = 246px
    final loginHeight = 52 + 12 + 52 + 8 + 40 + 12 + 50 + 20;
    
    // Signup form calculation:
    // Full Name field: ~52px
    // Spacing: 12px
    // Phone Number field: ~52px
    // Spacing: 12px
    // Email field: ~52px
    // Spacing: 12px
    // Password field: ~52px
    // Spacing: 12px
    // Confirm Password field: ~52px
    // Spacing: 12px
    // Blood Group dropdown: ~52px
    // Spacing: 12px
    // Skills dropdown: ~52px
    // Spacing: 15px
    // Location button: ~50px
    // Spacing: 15px
    // Create Account button: ~50px
    // Total: (7 * 52) + (7 * 12) + 15 + 50 + 15 + 50 = 364 + 84 + 130 = 578px, add 40px = 618px
    final signupHeight = (7 * 52) + (7 * 12) + 15 + 50 + 15 + 50 + 40;
    
    if (mounted) {
      setState(() {
        _loginFormHeight = loginHeight.toDouble();
        _signupFormHeight = signupHeight.toDouble();
      });
    }
  }
  
  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
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

          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: _currentTabIndex == 0 
                ? _loginFormHeight  // Fitted height for login form
                : _signupFormHeight, // Fitted height for signup form
            child: TabBarView(
              controller: _tabController,
              children: [
                // Login form - no scroll needed, fits perfectly
                loginForm(),
                // Signup form - scrollable if content exceeds screen
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: signUpForm(),
                  ),
                ),
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
      mainAxisSize: MainAxisSize.min,
      children: [

        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "EMAIL",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "PASSWORD",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: false, 
                  onChanged: (v) {},
                  activeColor: Colors.red,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  "Remember me",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Forgot?",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading 
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  "Sign In",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
          ),
        ),

      ],
    );
  }
  
  Future<void> _handleLogin() async {
    if (_loginEmailController.text.isEmpty || _loginPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.login(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //signup form//
  Widget signUpForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full Name
        TextField(
          controller: _signupNameController,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "Full Name",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // Phone Number
        TextField(
          controller: _signupPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "Phone Number",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // Email
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "Email",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // Password
        TextField(
          controller: _signupPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "Password",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // Confirm Password
        TextField(
          controller: _signupConfirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "Confirm Password",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // Blood Group Dropdown
        DropdownButtonFormField<String>(
          value: _selectedBloodGroup,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.bloodtype, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "Blood Group",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _bloodGroups.map((String bloodGroup) {
            return DropdownMenuItem<String>(
              value: bloodGroup,
              child: Text(bloodGroup),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedBloodGroup = newValue;
            });
          },
        ),

        const SizedBox(height: 12),

        // Skills Dropdown
        DropdownButtonFormField<String>(
          value: _selectedSkill,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.medical_services, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            labelText: "Skills",
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _skills.map((String skill) {
            return DropdownMenuItem<String>(
              value: skill,
              child: Text(skill),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedSkill = newValue;
            });
          },
        ),

        const SizedBox(height: 15),

        // Allow Location Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              // Request location permission
              setState(() {
                _locationAllowed = !_locationAllowed;
              });
              // TODO: Implement actual location permission request
            },
            icon: Icon(
              _locationAllowed ? Icons.location_on : Icons.location_off,
              color: _locationAllowed ? Colors.green : Colors.grey,
            ),
            label: Text(
              _locationAllowed ? "Location Allowed" : "Allow Location",
              style: TextStyle(
                color: _locationAllowed ? Colors.green : Colors.grey,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _locationAllowed ? Colors.green : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Create Account Button
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
            onPressed: _isLoading ? null : _handleSignup,
            child: _isLoading 
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text("Create Account"),
          ),
        ),
      ],
    );
  }
  
  Future<void> _handleSignup() async {
    // Validation
    if (_signupNameController.text.isEmpty ||
        _signupEmailController.text.isEmpty ||
        _signupPhoneController.text.isEmpty ||
        _signupPasswordController.text.isEmpty ||
        _signupConfirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    if (_signupPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    if (_signupPasswordController.text != _signupConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select your blood group")),
      );
      return;
    }

    if (_selectedSkill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a skill")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.signup(
      name: _signupNameController.text.trim(),
      email: _signupEmailController.text.trim(),
      phone: _signupPhoneController.text.trim(),
      password: _signupPasswordController.text,
      bloodGroup: _selectedBloodGroup!,
      skill: _selectedSkill!,
      locationAllowed: _locationAllowed,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Account created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Switch to login tab after successful signup
      _tabController.animateTo(0);
      // Clear signup form
      _signupNameController.clear();
      _signupEmailController.clear();
      _signupPhoneController.clear();
      _signupPasswordController.clear();
      _signupConfirmPasswordController.clear();
      setState(() {
        _selectedBloodGroup = null;
        _selectedSkill = null;
        _locationAllowed = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Signup failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }





}