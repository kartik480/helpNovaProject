import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../widgets/emergency_notification_dialog.dart';
import 'dart:async';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Notification data: ${message.data}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static final List<RemoteMessage> _pendingMessages = [];
  static Timer? _contextCheckTimer;

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
      debugPrint('=== FOREGROUND MESSAGE RECEIVED ===');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('Notification title: ${message.notification?.title}');
      debugPrint('Notification body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
      debugPrint('Data type: ${message.data['type']}');
      debugPrint('====================================');
      
      // Show notification dialog if it's an emergency SOS
      // Check multiple conditions to catch all emergency notifications
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      final dataType = message.data['type'] ?? '';
      final clickAction = message.data['click_action'] ?? '';
      
      final isEmergency = 
          dataType == 'emergency_sos' || 
          clickAction == 'FLUTTER_NOTIFICATION_CLICK' ||
          title.toLowerCase().contains('emergency') ||
          title.toLowerCase().contains('sos') ||
          title.contains('🚨') ||
          body.toLowerCase().contains('emergency') ||
          body.toLowerCase().contains('help') ||
          message.data.containsKey('userId') && message.data.containsKey('latitude');
      
      debugPrint('Emergency check result: $isEmergency');
      
      if (isEmergency) {
        debugPrint('✅ Emergency SOS detected, showing dialog...');
        _showEmergencyDialog(message);
      } else {
        debugPrint('❌ Not an emergency SOS notification, skipping dialog');
        debugPrint('Title: $title');
        debugPrint('Body: $body');
        debugPrint('Data type: $dataType');
        debugPrint('Click action: $clickAction');
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification taps (when app is in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('=== NOTIFICATION OPENED APP ===');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('Data: ${message.data}');
      debugPrint('Notification: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a notification (when app was terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('=== APP OPENED FROM NOTIFICATION ===');
      debugPrint('Message ID: ${initialMessage.messageId}');
      debugPrint('Data: ${initialMessage.data}');
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
    try {
      final data = message.data;
      
      debugPrint('=== SHOWING EMERGENCY DIALOG ===');
      debugPrint('User Name: ${data['userName']}');
      debugPrint('User Phone: ${data['userPhone']}');
      debugPrint('Latitude: ${data['latitude']}');
      debugPrint('Longitude: ${data['longitude']}');
      debugPrint('Description: ${data['description']}');
      debugPrint('User ID: ${data['userId']}');
      
      // Get the root navigator context
      final context = navigatorKey?.currentContext;
      if (context == null) {
        debugPrint('WARNING: No navigator context available, storing message for later');
        debugPrint('Navigator key is null: ${navigatorKey == null}');
        debugPrint('Current context is null: ${navigatorKey?.currentContext == null}');
        
        // Store message to show later
        _pendingMessages.add(message);
        
        // Start checking for context availability
        _startContextCheck();
        
        // Also try to show after delays
        Future.delayed(const Duration(milliseconds: 500), () {
          _tryShowPendingDialogs();
        });
        Future.delayed(const Duration(milliseconds: 1000), () {
          _tryShowPendingDialogs();
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          _tryShowPendingDialogs();
        });
        return;
      }

      _showDialogWithContext(context, data);
    } catch (e) {
      debugPrint('ERROR showing emergency dialog: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Start checking for context availability
  static void _startContextCheck() {
    _contextCheckTimer?.cancel();
    _contextCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_pendingMessages.isNotEmpty) {
        _tryShowPendingDialogs();
      } else {
        timer.cancel();
        _contextCheckTimer = null;
      }
    });
  }

  // Try to show pending dialogs
  static void _tryShowPendingDialogs() {
    final context = navigatorKey?.currentContext;
    if (context != null && _pendingMessages.isNotEmpty) {
      debugPrint('Context available, showing ${_pendingMessages.length} pending dialog(s)');
      final messages = List<RemoteMessage>.from(_pendingMessages);
      _pendingMessages.clear();
      _contextCheckTimer?.cancel();
      _contextCheckTimer = null;
      
      for (final message in messages) {
        _showDialogWithContext(context, message.data);
      }
    }
  }

  // Helper method to show dialog with context
  static void _showDialogWithContext(BuildContext context, Map<String, dynamic> data) {
    try {
      // Use SchedulerBinding to ensure the dialog shows after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
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
          debugPrint('Dialog shown successfully');
        }
      });
    } catch (e) {
      debugPrint('ERROR in _showDialogWithContext: $e');
      // Retry after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        final retryContext = navigatorKey?.currentContext;
        if (retryContext != null && retryContext.mounted) {
          try {
            showDialog(
              context: retryContext,
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
            debugPrint('Dialog shown successfully on retry');
          } catch (retryError) {
            debugPrint('ERROR on retry: $retryError');
          }
        }
      });
    }
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      
      debugPrint('=== HANDLING NOTIFICATION TAP ===');
      debugPrint('Data type: ${data['type']}');
      debugPrint('All data: $data');
      
      // Handle emergency SOS notification
      // Check multiple conditions to ensure we catch the notification
      if (data['type'] == 'emergency_sos' || 
          data['click_action'] == 'FLUTTER_NOTIFICATION_CLICK' ||
          message.notification?.title?.contains('Emergency') == true) {
        final requestId = data['requestId'] ?? data['userId'];
        final userId = data['userId'];
        
        debugPrint('Emergency SOS notification tapped');
        debugPrint('Request ID: $requestId');
        debugPrint('User ID: $userId');
        
        // Show the emergency dialog
        _showEmergencyDialog(message);
      } else {
        debugPrint('Not an emergency SOS notification');
      }
    } catch (e) {
      debugPrint('ERROR handling notification tap: $e');
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

  // Verify FCM token is registered (for debugging)
  static Future<void> verifyToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('=== FCM TOKEN VERIFICATION ===');
      debugPrint('Current token: $token');
      debugPrint('Stored token: $_fcmToken');
      debugPrint('Tokens match: ${token == _fcmToken}');
      
      if (token != null) {
        _fcmToken = token;
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error verifying token: $e');
    }
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
