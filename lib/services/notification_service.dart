import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../widgets/emergency_notification_dialog.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Notification data: ${message.data}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  // Initialize FCM and request permissions
  static Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Save token to backend
    if (_fcmToken != null) {
      await _saveTokenToBackend(_fcmToken!);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');
      _saveTokenToBackend(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');
      debugPrint('Notification title: ${message.notification?.title}');
      debugPrint('Notification body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
      
      // Show notification dialog if it's an emergency SOS
      if (message.data['type'] == 'emergency_sos') {
        _showEmergencyDialog(message);
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification taps (when app is in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.messageId}');
      debugPrint('Data: ${message.data}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a notification (when app was terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  // Save FCM token to backend
  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final authToken = await ApiService.getToken();
      if (authToken == null) {
        debugPrint('No auth token found, skipping FCM token save');
        return;
      }

      final response = await ApiService.updateFcmToken(token);
      if (response['success'] == true) {
        debugPrint('FCM token saved to backend successfully');
      } else {
        debugPrint('Failed to save FCM token: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Show emergency notification dialog
  static void _showEmergencyDialog(RemoteMessage message) {
    final data = message.data;
    
    // Get the root navigator context
    final context = navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('No navigator context available for showing dialog');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmergencyNotificationDialog(
        userName: data['userName'] ?? 'User',
        userPhone: data['userPhone'] ?? '',
        latitude: double.tryParse(data['latitude'] ?? '0') ?? 0,
        longitude: double.tryParse(data['longitude'] ?? '0') ?? 0,
        description: data['description'] ?? 'Emergency SOS request',
        requestId: data['userId'] ?? '',
      ),
    );
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    // Handle emergency SOS notification
    if (data['type'] == 'emergency_sos') {
      final requestId = data['requestId'];
      final userId = data['userId'];
      
      debugPrint('Emergency SOS notification tapped');
      debugPrint('Request ID: $requestId');
      debugPrint('User ID: $userId');
      
      // Show the emergency dialog
      _showEmergencyDialog(message);
    }
  }
  
  // Set navigator key for showing dialogs
  static GlobalKey<NavigatorState>? navigatorKey;
  
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  // Get current FCM token
  static String? getToken() {
    return _fcmToken;
  }

  // Send notification to nearby users (called from Emergency SOS screen)
  static Future<Map<String, dynamic>> sendEmergencyAlert({
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final result = await ApiService.sendEmergencyNotification(
        latitude: latitude,
        longitude: longitude,
        description: description,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending emergency alert: ${e.toString()}',
      };
    }
  }
}
