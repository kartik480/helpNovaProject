import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'services/notification_service.dart';

// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set navigator key for notifications early
  NotificationService.setNavigatorKey(navigatorKey);
  
  // Initialize Firebase and notifications in background (non-blocking)
  // This allows the app UI to show immediately while initialization happens
  _initializeServicesInBackground();
  
  // Start the app immediately - don't wait for Firebase
  runApp(const MyApp());
}

// Initialize Firebase and notifications in the background
void _initializeServicesInBackground() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize FCM notifications
    await NotificationService.initialize();
  } catch (e) {
    // Firebase initialization failed - app will still run but Firebase features won't work
    // This is expected if Firebase is not configured yet
    debugPrint('Firebase initialization error: $e');
    debugPrint('Please configure Firebase by following the setup guide in FIREBASE_SETUP.md');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Help Nova',
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Roboto',
      ),
      home: SplashScreen(),
    );
  }
}