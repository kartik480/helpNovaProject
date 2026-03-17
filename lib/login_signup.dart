import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'services/api_service.dart';
import 'widgets/map_search_widget.dart';
import 'utils/responsive.dart';
import 'dart:async';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentTabIndex = 0;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
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
  double? _signupLatitude;
  double? _signupLongitude;
  String? _signupAddress;
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
    
    // Initialize TabController first
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    // Start animation after a frame to ensure everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    // Add tab controller listener
    _tabController.addListener(() {
      if (mounted && _currentTabIndex != _tabController.index) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade50,
              Colors.white,
              Colors.red.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
        child: Column(
          children: [
                    SizedBox(height: Responsive.spacing(context, 40)),

                    // Logo and Title Section
            Column(
              children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                  ),
                  child: Image.asset(
                    "images/logo.png",
                            height: Responsive.value(
                              context,
                              mobile: 80.0,
                              tablet: 100.0,
                              desktop: 120.0,
                            ),
                    fit: BoxFit.contain,
                  ),
                ),
                        SizedBox(height: Responsive.spacing(context, 20)),
            Text(
              "Help Nova",
              style: TextStyle(
                            fontSize: Responsive.fontSize(context, 32),
                fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            letterSpacing: 1.2,
              ),
            ),
                        SizedBox(height: Responsive.spacing(context, 8)),
            Text(
                          "Emergency Response Made Simple",
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
              ),
                        ),
                      ],
            ),

                    SizedBox(height: Responsive.spacing(context, 40)),

                    // Login/Signup Card
                    _buildLoginCard(),

                    SizedBox(height: Responsive.spacing(context, 30)),

                    // Social Login
                    _buildSocialLogin(),

                    SizedBox(height: Responsive.spacing(context, 20)),
          ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.value(
          context,
          mobile: 20.0,
          tablet: 40.0,
          desktop: 60.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 0,
            offset: Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Tab Bar
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      text: "Login",
                      isSelected: _currentTabIndex == 0,
                      onTap: () {
                        _tabController.animateTo(0);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      text: "Sign Up",
                      isSelected: _currentTabIndex == 1,
                      onTap: () {
                        _tabController.animateTo(1);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, 28)),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _currentTabIndex == 0
                    ? _buildLoginForm()
                    : _buildSignupForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.15),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.red.shade700 : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: ValueKey('login'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: _loginEmailController,
          icon: Icons.email_outlined,
          label: "Email",
          keyboardType: TextInputType.emailAddress,
        ),
        
        SizedBox(height: 18),
        
        _buildTextField(
          controller: _loginPasswordController,
          icon: Icons.lock_outline_rounded,
          label: "Password",
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),

        SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _rememberMe ? Colors.red.shade600 : Colors.transparent,
                      border: Border.all(
                        color: _rememberMe ? Colors.red.shade600 : Colors.grey[400]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _rememberMe
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Remember me",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password reset feature coming soon')),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 28),
        
        _buildActionButton(
          text: "Sign In",
          onPressed: _isLoading ? null : _handleLogin,
          isLoading: _isLoading,
        ),
      ],
    );
  }
  
  Widget _buildSignupForm() {
    return SingleChildScrollView(
      key: ValueKey('signup'),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          _buildTextField(
            controller: _signupNameController,
            icon: Icons.person_outline_rounded,
            label: "Full Name",
          ),
          
          SizedBox(height: 18),
          
          _buildTextField(
            controller: _signupPhoneController,
            icon: Icons.phone_outlined,
            label: "Phone Number",
            keyboardType: TextInputType.phone,
          ),
          
          SizedBox(height: 18),
          
          _buildTextField(
            controller: _signupEmailController,
            icon: Icons.email_outlined,
            label: "Email",
            keyboardType: TextInputType.emailAddress,
          ),
          
          SizedBox(height: 18),
          
          _buildTextField(
            controller: _signupPasswordController,
            icon: Icons.lock_outline_rounded,
            label: "Password",
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),

          SizedBox(height: 18),

          _buildTextField(
            controller: _signupConfirmPasswordController,
            icon: Icons.lock_outline_rounded,
            label: "Confirm Password",
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),

          SizedBox(height: 18),

          _buildDropdownField(
            value: _selectedBloodGroup,
            icon: Icons.bloodtype_rounded,
            label: "Blood Group",
            items: _bloodGroups,
            onChanged: (value) {
              setState(() {
                _selectedBloodGroup = value;
              });
            },
          ),

          SizedBox(height: 18),

          _buildDropdownField(
            value: _selectedSkill,
            icon: Icons.medical_services_outlined,
            label: "Skills",
            items: _skills,
            onChanged: (value) {
              setState(() {
                _selectedSkill = value;
              });
            },
          ),
          
          SizedBox(height: 18),
          
          _buildLocationSection(),
          
          SizedBox(height: 28),
          
          _buildActionButton(
            text: "Create Account",
            onPressed: _isLoading ? null : _handleSignup,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.red.shade600,
              size: 20,
            ),
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: suffixIcon,
                )
              : null,
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.red.shade600,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required IconData icon,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.red.shade600,
              size: 20,
            ),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.red.shade600,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _locationAllowed ? Colors.green.shade50 : Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _locationAllowed ? Colors.green.shade400 : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _locationAllowed ? Colors.green.shade100 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: _locationAllowed ? Colors.green.shade700 : Colors.grey[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Location Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Switch(
                value: _locationAllowed,
                onChanged: (value) {
                  if (value) {
                    _openMapSearch();
                  } else {
                    setState(() {
                      _locationAllowed = false;
                      _signupLatitude = null;
                      _signupLongitude = null;
                      _signupAddress = null;
                    });
                  }
                },
                activeColor: Colors.green.shade600,
              ),
            ],
          ),
          SizedBox(height: 14),
          if (_locationAllowed && _signupAddress != null)
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _signupAddress!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_locationAllowed)
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please set your location on map',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Enable to help others in emergencies nearby',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_locationAllowed)
            SizedBox(height: 14),
          if (_locationAllowed)
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openMapSearch,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade700],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Set Location on Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey[300]!,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Or continue with",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              label: 'Google',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Google sign-in coming soon')),
                );
              },
            ),
            SizedBox(width: 16),
            _buildSocialButton(
              icon: Icons.apple,
              label: 'Apple',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Apple sign-in coming soon')),
                );
              },
            ),
          ],
        ),
        
        SizedBox(height: 28),
        
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.value(
              context,
              mobile: 40.0,
              tablet: 60.0,
              desktop: 80.0,
            ),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.5,
              ),
              children: [
                TextSpan(text: "By continuing, you agree to Help Nova's "),
                TextSpan(
                  text: "Terms of Service",
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: "."),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.grey[800],
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _openMapSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSearchWidget(
          initialLatitude: _signupLatitude,
          initialLongitude: _signupLongitude,
          initialAddress: _signupAddress,
          onLocationSelected: (latitude, longitude, address) {
            setState(() {
              _signupLatitude = latitude;
              _signupLongitude = longitude;
              _signupAddress = address;
              _locationAllowed = true;
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_loginEmailController.text.isEmpty || _loginPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainNavigation(),
          transitionDuration: Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSignup() async {
    if (_signupNameController.text.isEmpty ||
        _signupEmailController.text.isEmpty ||
        _signupPhoneController.text.isEmpty ||
        _signupPasswordController.text.isEmpty ||
        _signupConfirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all required fields"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_signupPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password must be at least 6 characters"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_signupPasswordController.text != _signupConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select your blood group"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedSkill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a skill"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_locationAllowed && (_signupLatitude == null || _signupLongitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please set your location on the map"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
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
      latitude: _signupLatitude,
      longitude: _signupLongitude,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Account created successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(0);
      _signupNameController.clear();
      _signupEmailController.clear();
      _signupPhoneController.clear();
      _signupPasswordController.clear();
      _signupConfirmPasswordController.clear();
      setState(() {
        _selectedBloodGroup = null;
        _selectedSkill = null;
        _locationAllowed = false;
        _signupLatitude = null;
        _signupLongitude = null;
        _signupAddress = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Signup failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
