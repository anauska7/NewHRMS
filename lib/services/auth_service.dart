import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_hrms/providers/auth_providers.dart'; // Import the providers

class AuthService {
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }
  
  // Get user type
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type'); // Default to employee
  }
  
  // Logout user
  static Future<void> logout(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_type');
    
    // Update providers
    ref.read(authProvider.notifier).state = false;
    ref.read(userTypeProvider.notifier).state = '';
  }
}