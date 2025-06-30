import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_model.dart';
import 'package:new_hrms/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Define office location 
const double OFFICE_LATITUDE = 19.0443696;
const double OFFICE_LONGITUDE = 73.0731067;
const double OFFICE_RADIUS = 100.0; // meters

class AttendanceViewModel extends StateNotifier<AttendanceState> {
  final String? selectedYear;
  final String? selectedMonth;
  final String? selectedDay;

  AttendanceViewModel({
    this.selectedYear,
    this.selectedMonth,
    this.selectedDay,
  }) : super(AttendanceState.initial()) {
    debugPrint('🏗️ [CONSTRUCTOR] AttendanceViewModel constructor called');
    debugPrint('🏗️ [CONSTRUCTOR] Initial filters - Year: $selectedYear, Month: $selectedMonth, Day: $selectedDay');
    debugPrint('🏗️ [CONSTRUCTOR] Initial state: ${state.toString()}');
    _initializeServices();
    // Fetch attendance records on initialization
    fetchAttendanceRecords();
    debugPrint('🏗️ [CONSTRUCTOR] Constructor completed');
  }

  Future<void> _initializeServices() async {
    debugPrint('🔧 [INIT_SERVICES] Starting service initialization');
    try {
      // Initialize notification service
      debugPrint('🔧 [INIT_SERVICES] Initializing notification service...');
      await NotificationService.initialize();
      debugPrint('✅ [INIT_SERVICES] Notification service initialized successfully');
      
      // Request location permissions and initialize background service
      debugPrint('🔧 [INIT_SERVICES] Requesting initial location permission...');
      await _requestInitialLocationPermission();
      debugPrint('✅ [INIT_SERVICES] Location permission request completed');
      
      debugPrint('🔧 [INIT_SERVICES] Initializing background service...');
      await initializeBackgroundService();
      debugPrint('✅ [INIT_SERVICES] Background service initialization completed');
      
      debugPrint('🎉 [INIT_SERVICES] All services initialized successfully');
    } catch (e) {
      debugPrint('❌ [INIT_SERVICES] Error during service initialization: $e');
      debugPrint('❌ [INIT_SERVICES] Stack trace: ${StackTrace.current}');
    }
  }

  // Request initial location permission from the UI thread
  Future<void> _requestInitialLocationPermission() async {
    debugPrint('🌍 [LOCATION_PERM] _requestInitialLocationPermission() START');
    try {
      // Check if location services are enabled
      debugPrint('🌍 [LOCATION_PERM] Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('🌍 [LOCATION_PERM] Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('⚠️ [LOCATION_PERM] Location services not enabled, saving to preferences');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('location_services_enabled', false);
        debugPrint('💾 [LOCATION_PERM] Saved location_services_enabled: false');
        debugPrint('🔄 [LOCATION_PERM] Returning early due to disabled location services');
        return;
      }

      // Check and request location permission
      debugPrint('🌍 [LOCATION_PERM] Checking current location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🌍 [LOCATION_PERM] Current location permission: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('🌍 [LOCATION_PERM] Permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('🌍 [LOCATION_PERM] Permission request result: $permission');
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('location_permission', permission.toString());
        debugPrint('💾 [LOCATION_PERM] Saved location_permission to preferences: $permission');
      } else {
        debugPrint('✅ [LOCATION_PERM] Permission already granted: $permission');
      }
      
      debugPrint('🎉 [LOCATION_PERM] _requestInitialLocationPermission() completed successfully');
    } catch (e) {
      debugPrint('❌ [LOCATION_PERM] Error requesting initial location permission: $e');
      debugPrint('❌ [LOCATION_PERM] Stack trace: ${StackTrace.current}');
    }
  }

  // Initialize background service
  Future<void> initializeBackgroundService() async {
    debugPrint('🔧 [BG_SERVICE] initializeBackgroundService() START');
    final service = FlutterBackgroundService();
    
    try {
      debugPrint('🔧 [BG_SERVICE] Getting FlutterBackgroundService instance');
      bool isRunning = await service.isRunning();
      debugPrint('🔧 [BG_SERVICE] Background service running status: $isRunning');
      
      if (!isRunning) {
        debugPrint('🔧 [BG_SERVICE] Service not running, configuring service...');
        await service.configure(
          androidConfiguration: AndroidConfiguration(
            onStart: onStart,
            isForegroundMode: true,
            autoStart: true,
            notificationChannelId: 'attendance_channel',
            initialNotificationTitle: "Attendance Tracking",
            initialNotificationContent: "Tracking your office presence",
            foregroundServiceNotificationId: NotificationIds.attendance,
          ),
          iosConfiguration: IosConfiguration(
            autoStart: true,
            onForeground: onStart,
            onBackground: onIosBackground,
          ),
        );
        debugPrint('✅ [BG_SERVICE] Service configuration completed');
        
        debugPrint('🔧 [BG_SERVICE] Starting background service...');
        await service.startService();
        debugPrint('🎉 [BG_SERVICE] Background service started successfully');
      } else {
        debugPrint('ℹ️ [BG_SERVICE] Background service already running, skipping initialization');
      }
    } catch (e) {
      debugPrint('❌ [BG_SERVICE] Error initializing background service: $e');
      debugPrint('❌ [BG_SERVICE] Stack trace: ${StackTrace.current}');
    }
  }

  // iOS background handling
  static Future<bool> onIosBackground(ServiceInstance service) async {
    debugPrint('🍎 [IOS_BG] onIosBackground() called');
    debugPrint('🍎 [IOS_BG] Service instance: ${service.toString()}');
    debugPrint('🍎 [IOS_BG] Returning true for iOS background handling');
    return true;
  }

  // Background service entry point
  static void onStart(ServiceInstance service) async {
    debugPrint('🚀 [BG_START] onStart() START');
    debugPrint('🚀 [BG_START] Service instance type: ${service.runtimeType}');
    debugPrint('🚀 [BG_START] Service instance: ${service.toString()}');

    try {
      // Initialize notification service in background isolate
      debugPrint('🚀 [BG_START] Initializing notification service in background isolate...');
      await NotificationService.initialize();
      debugPrint('✅ [BG_START] Notification service initialized in background');

      // For Android, make sure to create a valid notification
      if (service is AndroidServiceInstance) {
        debugPrint('🤖 [BG_START] Service is AndroidServiceInstance');
        
        debugPrint('🤖 [BG_START] Setting as foreground service...');
        service.setAsForegroundService();
        
        debugPrint('🤖 [BG_START] Setting initial foreground notification...');
        service.setForegroundNotificationInfo(
          title: "Attendance Tracker",
          content: "Running in background",
        );
        debugPrint('✅ [BG_START] Initial notification set');
        
        // Set up event listeners
        debugPrint('🤖 [BG_START] Setting up event listeners...');
        service.on('setAsForeground').listen((event) {
          debugPrint('📢 [BG_EVENT] setAsForeground event received: $event');
          service.setAsForegroundService();
          service.setForegroundNotificationInfo(
            title: "Attendance Tracker",
            content: "Running in foreground",
          );
          debugPrint('✅ [BG_EVENT] Foreground mode activated');
        });

        service.on('setAsBackground').listen((event) {
          debugPrint('📢 [BG_EVENT] setAsBackground event received: $event');
          service.setAsBackgroundService();
          debugPrint('✅ [BG_EVENT] Background mode activated');
        });
        
        debugPrint('✅ [BG_START] Event listeners configured');
      } else {
        debugPrint('🍎 [BG_START] Service is not AndroidServiceInstance (likely iOS)');
      }

      // Set up stop service listener
      debugPrint('🚀 [BG_START] Setting up stop service listener...');
      service.on('stopService').listen((event) {
        debugPrint('🛑 [BG_EVENT] stopService event received: $event');
        service.stopSelf();
        debugPrint('🛑 [BG_EVENT] Service stopped');
      });

      // Run the location check right away
      debugPrint('🚀 [BG_START] Running initial location check...');
      await backgroundLocationCheck(service);
      debugPrint('✅ [BG_START] Initial location check completed');

      // Set up periodic location checks
      debugPrint('🚀 [BG_START] Setting up periodic timer (5 minutes)...');
      Timer.periodic(const Duration(minutes: 5), (timer) async {
        debugPrint('⏰ [TIMER] Timer tick: ${DateTime.now()}');
        debugPrint('⏰ [TIMER] Running backgroundLocationCheck...');
        await backgroundLocationCheck(service);
        debugPrint('⏰ [TIMER] backgroundLocationCheck completed');
        
        if (service is AndroidServiceInstance) {
          debugPrint('⏰ [TIMER] Updating Android notification with productivity...');
          final prefs = await SharedPreferences.getInstance();
          final int totalMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
          final int hours = totalMinutes ~/ 60;
          final int minutes = totalMinutes % 60;
          final String productivityString = '${hours}h ${minutes}m';
          debugPrint('⏰ [TIMER] Current productivity: $productivityString');

          service.setForegroundNotificationInfo(
            title: "Attendance Tracker",
            content: "Productivity today: $productivityString",
          );
          debugPrint('✅ [TIMER] Notification updated');
        }
      });
      
      debugPrint('🎉 [BG_START] Background service onStart() completed successfully');
    } catch (e) {
      debugPrint('❌ [BG_START] Error in onStart(): $e');
      debugPrint('❌ [BG_START] Stack trace: ${StackTrace.current}');
    }
  }

// Background location check method with server-side attendance verification
static Future backgroundLocationCheck(ServiceInstance service) async {
  debugPrint('🌍 [BG_LOCATION] backgroundLocationCheck() START');
  debugPrint('🌍 [BG_LOCATION] Service instance: ${service.toString()}');
  
  try {
    debugPrint('🌍 [BG_LOCATION] Getting SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    
    debugPrint('🌍 [BG_LOCATION] Retrieving auth token...');
    final token = prefs.getString('auth_token');
    if (token == null) {
      debugPrint('❌ [BG_LOCATION] No auth token found, skipping location check');
      return;
    }
    debugPrint('✅ [BG_LOCATION] Auth token found: ${token.substring(0, 20)}...');

    final now = DateTime.now();
    final currentHour = now.hour;
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📍 [LOCATION CHECK] $formattedTime');
    debugPrint('⏰ [BG_LOCATION] Current hour: $currentHour');

    // Only proceed during working hours (9 AM to 6 PM)
    if (currentHour < 9 || currentHour > 18) {
      debugPrint('⏰ [BG_LOCATION] Outside working hours (current hour: $currentHour), skipping check');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }
    debugPrint('✅ [BG_LOCATION] Within working hours, proceeding with check');

    // Get decoded token
    debugPrint('🔐 [BG_LOCATION] Decoding JWT token...');
    final decodedToken = JwtDecoder.decode(token);
    final employeeId = decodedToken['_id'];
    debugPrint('👤 [BG_LOCATION] Employee ID: $employeeId');

    // **NEW: Fetch today's attendance status from server**
    debugPrint('🔍 [BG_LOCATION] Fetching today\'s attendance status from server...');
    final today = DateFormat('yyyy-MM-dd').format(now);
    final attendanceStatus = await _fetchTodayAttendanceStatus(token, employeeId, today);
    debugPrint('📊 [BG_LOCATION] Server attendance status: $attendanceStatus');

    // Update local preferences with server data
    if (attendanceStatus['isCheckedIn'] == true && attendanceStatus['checkInDate'] == today) {
      debugPrint('💾 [BG_LOCATION] Updating local check-in status from server data');
      await prefs.setString('last_checkin_date', today);
      await prefs.setBool('checked_out_today', attendanceStatus['isCheckedOut'] ?? false);
    } else {
      debugPrint('💾 [BG_LOCATION] No check-in found for today on server, clearing local status');
      await prefs.remove('last_checkin_date');
      await prefs.setBool('checked_out_today', false);
    }

    // Use server data for attendance status
    final isCheckedIn = attendanceStatus['isCheckedIn'] ?? false;
    final isCheckedOut = attendanceStatus['isCheckedOut'] ?? false;
    
    debugPrint('📆 [BG_LOCATION] Today: $today');
    debugPrint('📆 [BG_LOCATION] Server check-in status: ${isCheckedIn ? "Checked in" : "Not checked in"}');
    debugPrint('📆 [BG_LOCATION] Server check-out status: ${isCheckedOut ? "Checked out" : "Not checked out"}');

    // Retrieve current daily productivity
    debugPrint('📊 [BG_LOCATION] Retrieving productivity data...');
    int dailyProductivityMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
    String? storedProductivityDate = prefs.getString('last_productivity_date');
    debugPrint('📊 [BG_LOCATION] Current productivity minutes: $dailyProductivityMinutes');
    debugPrint('📊 [BG_LOCATION] Stored productivity date: ${storedProductivityDate ?? "None"}');
    
    // If it's a new day, reset productivity
    if (storedProductivityDate != today) {
      debugPrint('🔄 [BG_LOCATION] New day detected, resetting productivity...');
      dailyProductivityMinutes = 0;
      await prefs.setString('last_productivity_date', today);
      await prefs.setInt('daily_productivity_minutes', 0);
      debugPrint('✅ [BG_LOCATION] Productivity reset for new day');
    }

    // Check location permission
    debugPrint('🔐 [BG_LOCATION] Checking location permission...');
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('🔐 [BG_LOCATION] Current permission: $permission');
    
    if (permission == LocationPermission.denied) {
      debugPrint('🔐 [BG_LOCATION] Permission denied, requesting...');
      permission = await Geolocator.requestPermission();
      debugPrint('🔐 [BG_LOCATION] Permission request result: $permission');
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('❌ [BG_LOCATION] Location permission denied: $permission');
        debugPrint('🔔 [BG_LOCATION] Showing permission notification...');
        await NotificationService.showBasicNotification(
          id: NotificationIds.locationPermission,
          title: 'Location Permission Required',
          body: 'Please enable location permissions for automatic attendance tracking',
        );
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }
    }
    debugPrint('✅ [BG_LOCATION] Location permission granted');

    // Check location services
    debugPrint('📡 [BG_LOCATION] Checking location services...');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('📡 [BG_LOCATION] Location services enabled: $serviceEnabled');
    
    if (!serviceEnabled) {
      debugPrint('❌ [BG_LOCATION] Location services disabled');
      if (service is AndroidServiceInstance) {
        debugPrint('🤖 [BG_LOCATION] Updating Android notification for disabled location services');
        service.setForegroundNotificationInfo(
          title: "Attendance Tracker",
          content: "Location services disabled. Please enable for automatic check-in.",
        );
      }
      debugPrint('🔔 [BG_LOCATION] Showing location services notification...');
      await NotificationService.showBasicNotification(
        id: NotificationIds.locationServices,
        title: 'Location Services Disabled',
        body: 'Please enable location services for automatic attendance tracking',
      );
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    debugPrint('🔄 [BG_LOCATION] Trying to get current position...');
    // Get current location with timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    ).catchError((e) {
      debugPrint('❌ [BG_LOCATION] Error getting location: $e');
      return Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    });

    // If invalid position, return
    if (position.latitude == 0 && position.longitude == 0) {
      debugPrint('❌ [BG_LOCATION] Invalid position received, skipping check');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    // Log location data
    debugPrint('📍 [BG_LOCATION] Position details:');
    debugPrint(' └─ Latitude: ${position.latitude.toStringAsFixed(6)}');
    debugPrint(' └─ Longitude: ${position.longitude.toStringAsFixed(6)}');
    debugPrint(' └─ Accuracy: ${position.accuracy.toStringAsFixed(2)} meters');
    debugPrint(' └─ Timestamp: ${position.timestamp}');

    // Check if within office radius
    debugPrint('🏢 [BG_LOCATION] Calculating distance to office...');
    double distanceInMeters = Geolocator.distanceBetween(
      OFFICE_LATITUDE,
      OFFICE_LONGITUDE,
      position.latitude,
      position.longitude,
    );
    debugPrint('🏢 [BG_LOCATION] Office coordinates: ($OFFICE_LATITUDE, $OFFICE_LONGITUDE)');
    debugPrint('🏢 [BG_LOCATION] Current coordinates: (${position.latitude}, ${position.longitude})');
    debugPrint('🏢 [BG_LOCATION] Distance to office: ${distanceInMeters.toStringAsFixed(2)} meters');
    debugPrint('🏢 [BG_LOCATION] Office radius limit: $OFFICE_RADIUS meters');

    if (distanceInMeters <= OFFICE_RADIUS) {
      debugPrint('✅ [BG_LOCATION] Employee is WITHIN office radius');
      
      // Only add productivity if checked in
      if (isCheckedIn && !isCheckedOut) {
        debugPrint('📊 [BG_LOCATION] Employee is checked in, adding 5 minutes to productivity...');
        dailyProductivityMinutes += 5;
        await prefs.setInt('daily_productivity_minutes', dailyProductivityMinutes);
        debugPrint('💾 [BG_LOCATION] Updated productivity in preferences: $dailyProductivityMinutes minutes');
        
        // Show productivity notification to employee
        final int hours = dailyProductivityMinutes ~/ 60;
        final int minutes = dailyProductivityMinutes % 60;
        final String productivityString = '${hours}h ${minutes}m';
        debugPrint('📊 [BG_LOCATION] Current productivity: $productivityString');
        
        // Show periodic productivity notifications (every 30 minutes)
        if (dailyProductivityMinutes > 0 && dailyProductivityMinutes % 30 == 0) {
          debugPrint('🔔 [BG_LOCATION] Showing productivity milestone notification...');
          await NotificationService.showBasicNotification(
            id: NotificationIds.attendance + 100,
            title: 'Productivity Update',
            body: 'You\'ve been productive for $productivityString today! Keep it up! 🎯',
          );
          debugPrint('✅ [BG_LOCATION] Productivity notification sent');
        }
        debugPrint('📊 [PRODUCTIVITY] Updated to: $productivityString (+5m)');
      } else {
        debugPrint('ℹ️ [BG_LOCATION] Employee is within office but not eligible for productivity tracking');
        debugPrint(' └─ Is checked in: $isCheckedIn');
        debugPrint(' └─ Is checked out: $isCheckedOut');
      }
    } else {
      debugPrint('❌ [BG_LOCATION] Employee is OUTSIDE office radius');

      // Handle check-out scenario
      if (isCheckedIn && !isCheckedOut) {
        debugPrint('🚪 [BG_LOCATION] Employee is checked in but not checked out');
        if (distanceInMeters > OFFICE_RADIUS) {
          debugPrint('🔄 [BG_LOCATION] Attempting auto check-out...');
          
          final requestBody = {
            'employeeID': employeeId,
            'latitude': position.latitude.toString(),
            'longitude': position.longitude.toString(),
            'productivity': dailyProductivityMinutes, // Send productivity in minutes
            'isMobile': true,                         // Indicate this is a mobile check-out
          };
          debugPrint('📤 [BG_LOCATION] Check-out request body: $requestBody');
          
          final response = await http.post(
            Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkout'),
            body: jsonEncode(requestBody),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'accessToken=$token',
            },
          ).timeout(const Duration(seconds: 30), onTimeout: () {
            debugPrint('⚠️ [BG_LOCATION] Check-out API request timed out');
            return http.Response('{"error": "timeout"}', 408);
          });

          debugPrint('📡 [BG_LOCATION] Check-out API response status: ${response.statusCode}');
          debugPrint('📡 [BG_LOCATION] Check-out API response body: ${response.body}');
          
          if (response.statusCode == 200) {
            debugPrint('✅ [BG_LOCATION] Auto check-out successful');
            debugPrint('💾 [BG_LOCATION] Updating check-out status in preferences...');
            await prefs.setBool('checked_out_today', true);
            
            // Show check-out notification with productivity summary
            final int hours = dailyProductivityMinutes ~/ 60;
            final int minutes = dailyProductivityMinutes % 60;
            final String productivityString = '${hours}h ${minutes}m';
            debugPrint('🔔 [BG_LOCATION] Showing auto check-out notification...');
            await NotificationService.showAttendanceNotification(
              id: NotificationIds.checkOut,
              title: 'Auto Check-out',
              body: 'You have been automatically checked out. Today\'s productivity: $productivityString',
            );
            debugPrint('✅ [BG_LOCATION] Check-out notification sent');
          } else {
            debugPrint('❌ [BG_LOCATION] Auto check-out failed: ${response.statusCode}');
          }
        }
      }

      // Handle check-in scenario (only if not already checked in)
      else if (!isCheckedIn && distanceInMeters <= OFFICE_RADIUS) {
        debugPrint('🚪 [BG_LOCATION] Employee is not checked in and within office radius');
        debugPrint('🔄 [BG_LOCATION] Attempting auto check-in...');
        
        final requestBody = {
          "employeeID": employeeId,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "camera": "false",
        };
        debugPrint('📤 [BG_LOCATION] Check-in request body: $requestBody');
        
        final response = await http.post(
          Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkin'),
          body: jsonEncode(requestBody),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'accessToken=$token',
          },
        ).timeout(const Duration(seconds: 30), onTimeout: () {
          debugPrint('⚠️ [BG_LOCATION] Check-in API request timed out');
          return http.Response('{"error": "timeout"}', 408);
        });
        
        debugPrint('📡 [BG_LOCATION] Check-in API response status: ${response.statusCode}');
        debugPrint('📡 [BG_LOCATION] Check-in API response body: ${response.body}');
        
        if (response.statusCode == 200) {
          debugPrint('✅ [BG_LOCATION] Auto check-in successful');
          debugPrint('💾 [BG_LOCATION] Updating check-in status in preferences...');
          await prefs.setString('last_checkin_date', today);
          await prefs.setBool('checked_out_today', false);
          await prefs.setBool('attendanceMarked', true);
          await prefs.setInt('daily_productivity_minutes', 5); // Start with 5 minutes on check-in
          await prefs.setString('last_productivity_date', today);
          
          debugPrint('🔔 [BG_LOCATION] Showing auto check-in notification...');
          await NotificationService.showAttendanceNotification(
            id: NotificationIds.checkIn,
            title: 'Attendance Marked',
            body: 'You have been automatically checked in. Productivity tracking started!',
          );
          debugPrint('✅ [BG_LOCATION] Check-in notification sent');
        } else {
          debugPrint('❌ [BG_LOCATION] Auto check-in failed: ${response.statusCode}');
        }
      } else {
        debugPrint('ℹ️ [BG_LOCATION] No action needed:');
        debugPrint(' └─ Is checked in: $isCheckedIn');
        debugPrint(' └─ Is checked out: $isCheckedOut');
        debugPrint(' └─ Distance: ${distanceInMeters.toStringAsFixed(2)}m');
      }
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  } catch (e) {
    debugPrint('❌ [BG_LOCATION] Error in background location check: $e');
    debugPrint('❌ [BG_LOCATION] Stack trace: ${StackTrace.current}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}

// **NEW: Helper method to fetch today's attendance status from server**
static Future<Map<String, dynamic>> _fetchTodayAttendanceStatus(String token, String employeeId, String today) async {
  try {
    debugPrint('🔍 [FETCH_STATUS] Fetching attendance status for date: $today');
    
    final response = await http.post(
      Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/view-employee-attendance'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cookie': 'accessToken=$token',
      },
      body: jsonEncode({'employeeID': employeeId}),
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      debugPrint('⚠️ [FETCH_STATUS] Attendance fetch request timed out');
      return http.Response('{"error": "timeout"}', 408);
    });

    debugPrint('📡 [FETCH_STATUS] Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (responseData['success'] == true) {
        List<dynamic> attendanceData = responseData['data'];
        debugPrint('📊 [FETCH_STATUS] Found ${attendanceData.length} attendance records');
        
        // Find today's attendance record
        for (var record in attendanceData) {
          if (record['checkInTime'] != null) {
            DateTime checkInTime = DateTime.parse(record['checkInTime']);
            String recordDate = DateFormat('yyyy-MM-dd').format(checkInTime);
            
            if (recordDate == today) {
              debugPrint('✅ [FETCH_STATUS] Found today\'s attendance record');
              debugPrint('📝 [FETCH_STATUS] Check-in time: ${record['checkInTime']}');
              debugPrint('📝 [FETCH_STATUS] Check-out time: ${record['checkOutTime'] ?? "Not checked out"}');
              
              return {
                'isCheckedIn': true,
                'isCheckedOut': record['checkOutTime'] != null,
                'checkInDate': recordDate,
                'checkInTime': record['checkInTime'],
                'checkOutTime': record['checkOutTime'],
              };
            }
          }
        }
        
        debugPrint('ℹ️ [FETCH_STATUS] No attendance record found for today');
        return {
          'isCheckedIn': false,
          'isCheckedOut': false,
          'checkInDate': null,
          'checkInTime': null,
          'checkOutTime': null,
        };
      } else {
        debugPrint('❌ [FETCH_STATUS] API returned success: false');
        return {
          'isCheckedIn': false,
          'isCheckedOut': false,
          'checkInDate': null,
          'checkInTime': null,
          'checkOutTime': null,
        };
      }
    } else {
      debugPrint('❌ [FETCH_STATUS] HTTP error: ${response.statusCode}');
      return {
        'isCheckedIn': false,
        'isCheckedOut': false,
        'checkInDate': null,
        'checkInTime': null,
        'checkOutTime': null,
      };
    }
  } catch (e) {
    debugPrint('❌ [FETCH_STATUS] Error fetching attendance status: $e');
    return {
      'isCheckedIn': false,
      'isCheckedOut': false,
      'checkInDate': null,
      'checkInTime': null,
      'checkOutTime': null,
    };
  }
}

  // Method to get current daily productivity (for UI display)
  Future<String> getDailyProductivity() async {
    debugPrint('📊 [PRODUCTIVITY] getDailyProductivity() called');
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final storedProductivityDate = prefs.getString('last_productivity_date');
    
    // If it's a new day, return 0
    if (storedProductivityDate != today) {
      return '0h 0m';
    }
    
    final totalMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  // Method to upload image to server
  Future<String?> _uploadImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final decodedToken = JwtDecoder.decode(token);
      final employeeId = decodedToken['_id'];

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/upload-attendance-photo'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Cookie': 'accessToken=$token',
      });

      // Add fields
      request.fields['employeeID'] = employeeId;

      // Add file
      File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            imagePath,
            filename: 'attendance_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else {
        throw Exception('Image file not found');
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']['photoUrl'] ?? responseData['data']['photo_url'];
        } else {
          throw Exception(responseData['message'] ?? 'Failed to upload image');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Method to check-in a user manually with optional photo
  Future<void> checkIn({String? imagePath}) async {
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      // Check location services and permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location services are disabled. Please enable them to check in.'
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          state = state.copyWith(
            isLoading: false, 
            errorMessage: 'Location permission is required to check-in'
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Check if within office radius
      double distanceInMeters = Geolocator.distanceBetween(
        OFFICE_LATITUDE, 
        OFFICE_LONGITUDE, 
        position.latitude, 
        position.longitude
      );

      if (distanceInMeters > OFFICE_RADIUS) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You are not within the office area. Please move closer to mark attendance.'
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication token not found'
        );
        return;
      }

      final decodedToken = JwtDecoder.decode(token);

      // Upload image if provided
      String? photoUrl;
      if (imagePath != null) {
        photoUrl = await _uploadImage(imagePath);
      }

      final requestBody = {
        "employeeID": decodedToken['_id'],
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
        "camera": imagePath != null ? "true" : "false"
      };

      // Add photo URL if available
      if (photoUrl != null) {
        requestBody["photoUrl"] = photoUrl;
      }

      final response = await http.post(
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkin'),
        body: jsonEncode(requestBody),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      );

      if (response.statusCode == 200) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await prefs.setString('last_checkin_date', today);
        await prefs.setBool('checked_out_today', false);
        
        // Initialize productivity tracking for the day
        await prefs.setInt('daily_productivity_minutes', 5);
        await prefs.setString('last_productivity_date', today);
        
        state = state.copyWith(
          isLoading: false, 
          successMessage: imagePath != null 
              ? 'Successfully checked in with photo' 
              : 'Successfully checked in'
        );
        
        // Refresh attendance records
        await fetchAttendanceRecords();

        // Use NotificationService for manual check-in notification
        await NotificationService.showAttendanceNotification(
          id: NotificationIds.checkIn,
          title: 'Successfully Checked In',
          body: imagePath != null 
              ? 'You have successfully checked in with photo. Productivity tracking started!'
              : 'You have successfully checked in. Productivity tracking started!',
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to check-in';
        state = state.copyWith(
          isLoading: false, 
          errorMessage: errorMessage
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Network error: ${e.toString()}'
      );
    }
  }

  // Check-out method with optional photo
  Future<void> checkOut({String? imagePath}) async {
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      LocationPermission permission = await _checkLocationPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Location permission is required to check-out'
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Check if within office radius
      double distanceInMeters = Geolocator.distanceBetween(
        OFFICE_LATITUDE, 
        OFFICE_LONGITUDE, 
        position.latitude, 
        position.longitude
      );

      if (distanceInMeters > OFFICE_RADIUS) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You are not within the office area. Please move closer to mark check-out.'
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication token not found'
        );
        return;
      }

      final decodedToken = JwtDecoder.decode(token);

      // Upload image if provided
      String? photoUrl;
      if (imagePath != null) {
        photoUrl = await _uploadImage(imagePath);
      }

      final requestBody = {
        'employeeID': decodedToken['_id'],
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      };

      // Add photo URL if available
      if (photoUrl != null) {
        requestBody["photoUrl"] = photoUrl;
      }

      final response = await http.post(
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkout'),
        body: jsonEncode(requestBody),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.setBool('checked_out_today', true);
        
        // Get final productivity for the day
        final finalProductivity = await getDailyProductivity();
        
        state = state.copyWith(
          isLoading: false, 
          successMessage: imagePath != null 
              ? 'Successfully checked out with photo'
              : 'Successfully checked out'
        );
        
        // Refresh attendance records
        await fetchAttendanceRecords();

        // Use NotificationService for manual check-out notification
        await NotificationService.showAttendanceNotification(
          id: NotificationIds.checkOut,
          title: 'Successfully Checked Out',
          body: 'You have successfully checked out. Daily productivity: $finalProductivity',
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to check-out';
        state = state.copyWith(
          isLoading: false, 
          errorMessage: errorMessage
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Network error: ${e.toString()}'
      );
    }
  }

  // Reset filters and fetch all attendance records
  Future<void> resetFiltersAndFetchAttendance() async {
    state = state.copyWith(
      selectedYear: null,
      selectedMonth: null,
      selectedDay: null,
      isLoading: true,
      errorMessage: '',
      successMessage: '',
    );

    await fetchAttendanceRecords();
  }

  // Fetch attendance records
  Future<void> fetchAttendanceRecords() async {
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication token not found'
        );
        return;
      }

      final decodedToken = JwtDecoder.decode(token);
      final employeeID = decodedToken['_id'];

      final response = await http.post(
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/view-employee-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
        body: jsonEncode({'employeeID': employeeID}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];

          if (data.isNotEmpty) {
            List<Attendance> attendanceRecords = 
                data.map((record) => Attendance.fromJson(record)).toList();

            // Apply filters
            if (state.selectedYear != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) => attendance.checkInTime.year.toString() == state.selectedYear)
                  .toList();
            }

            if (state.selectedMonth != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) {
                    String month = DateFormat('MMMM').format(attendance.checkInTime);
                    return month.toLowerCase() == state.selectedMonth!.toLowerCase();
                  })
                  .toList();
            }

            if (state.selectedDay != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) => attendance.checkInTime.day.toString() == state.selectedDay)
                  .toList();
            }

            state = state.copyWith(
              isLoading: false,
              attendanceList: attendanceRecords,
              successMessage: 'Attendance records fetched successfully'
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              attendanceList: [],
              successMessage: 'No attendance records found'
            );
          }
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: responseData['message'] ?? 'Failed to fetch attendance records',
          );
        }
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch attendance records';
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error: ${e.toString()}'
      );
    }
  }

  // Set filters
  void setSelectedYear(String? year) {
    state = state.copyWith(selectedYear: year);
  }

  void setSelectedMonth(String? month) {
    state = state.copyWith(selectedMonth: month);
  }

  void setSelectedDay(String? day) {
    state = state.copyWith(selectedDay: day);
  }

  // Location permission check and request
  Future<LocationPermission> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }
}

// Provider for the ViewModel
final attendanceViewModelProvider = StateNotifierProvider<AttendanceViewModel, AttendanceState>((ref) {
  return AttendanceViewModel();
});