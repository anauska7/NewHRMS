import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static const String _attendanceChannelKey = 'attendance_channel';
  static const String _basicChannelKey = 'basic_channel';
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize notification service
  static Future<bool> initialize() async {
    try {
      bool initialized = await AwesomeNotifications().initialize(
        null, // Use default app icon
        [
          NotificationChannel(
            channelKey: _attendanceChannelKey,
            channelName: 'Attendance Notifications',
            channelDescription: 'Notifications for attendance check-in and check-out',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            onlyAlertOnce: false,
            playSound: true,
            criticalAlerts: false,
          ),
          NotificationChannel(
            channelKey: _basicChannelKey,
            channelName: 'Basic Notifications',
            channelDescription: 'General app notifications',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.Default,
            channelShowBadge: true,
            onlyAlertOnce: false,
            playSound: true,
            criticalAlerts: false,
          ),
        ],
        debug: kDebugMode,
      );

      if (initialized) {
        // Request permissions
        await requestNotificationPermissions();
        
        // Set up listeners
        AwesomeNotifications().setListeners(
          onActionReceivedMethod: _onActionReceivedMethod,
          onNotificationCreatedMethod: _onNotificationCreatedMethod,
          onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
          onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
        );
        
        debugPrint('✅ NotificationService: Initialized successfully');
        return true;
      }
      
      debugPrint('❌ NotificationService: Failed to initialize');
      return false;
    } catch (e) {
      debugPrint('❌ NotificationService initialization error: $e');
      return false;
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    try {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      
      debugPrint('📱 NotificationService: Permissions ${isAllowed ? 'granted' : 'denied'}');
      return isAllowed;
    } catch (e) {
      debugPrint('❌ NotificationService permission error: $e');
      return false;
    }
  }

  /// Show attendance notification
  static Future<bool> showAttendanceNotification({
    required int id,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    try {
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _attendanceChannelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
          color: const Color(0xFF9D50DD),
          icon: 'resource://drawable/ic_notification', // Add custom icon if needed
          largeIcon: 'resource://drawable/ic_notification_large', // Add custom large icon if needed
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          fullScreenIntent: false,
          autoDismissible: true,
          showWhen: true,
        ),
      );
      
      if (success) {
        debugPrint('✅ NotificationService: Attendance notification sent - $title');
      } else {
        debugPrint('❌ NotificationService: Failed to send attendance notification - $title');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ NotificationService attendance notification error: $e');
      return false;
    }
  }

  /// Show basic notification
  static Future<bool> showBasicNotification({
    required int id,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    try {
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _basicChannelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
          autoDismissible: true,
          showWhen: true,
        ),
      );
      
      if (success) {
        debugPrint('✅ NotificationService: Basic notification sent - $title');
      } else {
        debugPrint('❌ NotificationService: Failed to send basic notification - $title');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ NotificationService basic notification error: $e');
      return false;
    }
  }

  /// Show notification with actions
  static Future<bool> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required List<NotificationActionButton> actions,
    Map<String, String>? payload,
  }) async {
    try {
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _attendanceChannelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
          autoDismissible: false, // Don't auto dismiss when there are actions
          showWhen: true,
        ),
        actionButtons: actions,
      );
      
      if (success) {
        debugPrint('✅ NotificationService: Action notification sent - $title');
      } else {
        debugPrint('❌ NotificationService: Failed to send action notification - $title');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ NotificationService action notification error: $e');
      return false;
    }
  }

  /// Cancel notification by ID
  static Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      debugPrint('📱 NotificationService: Cancelled notification ID: $id');
    } catch (e) {
      debugPrint('❌ NotificationService cancel error: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      debugPrint('📱 NotificationService: Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ NotificationService cancel all error: $e');
    }
  }

  /// Check if notifications are allowed
  static Future<bool> isNotificationAllowed() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (e) {
      debugPrint('❌ NotificationService permission check error: $e');
      return false;
    }
  }

  // Event handlers
  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('📱 NotificationService: Action received - ${receivedAction.actionType}');
    
    // Handle different action types
    switch (receivedAction.actionType) {
      case ActionType.Default:
        // Handle default tap - could navigate to attendance page
        debugPrint('📱 Default action received');
        break;
      case ActionType.SilentAction:
        // Handle silent actions
        debugPrint('📱 Silent action received');
        break;
      case ActionType.SilentBackgroundAction:
        // Handle background actions
        debugPrint('📱 Background action received');
        break;
      default:
        debugPrint('📱 Unknown action type: ${receivedAction.actionType}');
        break;
    }
    
    // You can add navigation logic here if needed
    // For example, navigate to attendance page when notification is tapped
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('📱 NotificationService: Notification created - ${receivedNotification.title}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('📱 NotificationService: Notification displayed - ${receivedNotification.title}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('📱 NotificationService: Notification dismissed - ${receivedAction.id}');
  }
}

// Extension to make using the service easier
extension NotificationIds on int {
  static const int attendance = 888;
  static const int checkIn = 889;
  static const int checkOut = 890;
  static const int locationPermission = 891;
  static const int locationServices = 892;
}