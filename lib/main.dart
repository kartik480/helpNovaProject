import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_signup.dart';
import 'services/notification_service.dart';

// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set navigator key for notifications
    NotificationService.setNavigatorKey(navigatorKey);
    
    // Initialize FCM notifications
    await NotificationService.initialize();
  } catch (e) {
    // Firebase initialization failed - app will still run but Firebase features won't work
    // This is expected if Firebase is not configured yet
    debugPrint('Firebase initialization error: $e');
    debugPrint('Please configure Firebase by following the setup guide in FIREBASE_SETUP.md');
  }
  
  runApp(const MyApp());
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: LoginSignupScreen(),
    );
  }
}