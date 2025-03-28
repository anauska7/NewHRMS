import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardState {
  final bool isLoading;
  final User? user;
  final String errorMessage;

  DashboardState({
    required this.isLoading,
    this.user,
    required this.errorMessage,
  });

  DashboardState.initial()
      : isLoading = true,
        user = null,
        errorMessage = '';

  DashboardState copyWith({
    bool? isLoading,
    User? user,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  DashboardViewModel() : super(DashboardState.initial());

  void setError(String message) {
    state = state.copyWith(isLoading: false, errorMessage: message);
  }

  Future<void> fetchUserData(String token) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      
      // First try to get data from SharedPreferences
      final user = await _getUserFromPrefs();
      if (user != null) {
        state = state.copyWith(isLoading: false, user: user);
        return;
      }

      // If not in prefs, fetch from API
      final response = await http.get(
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true && data.containsKey('user')) {
          final user = User.fromJson(data['user']);
          
          // Save to SharedPreferences for offline access
          await _saveUserToPrefs(data['user']);
          
          state = state.copyWith(isLoading: false, user: user, errorMessage: '');
        } else {
          state = state.copyWith(
            isLoading: false, 
            errorMessage: 'Invalid response format: ${data['message'] ?? 'Unknown error'}'
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Failed to fetch data: ${response.statusCode}'
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Network Error: $e');
    }
  }

  Future<void> _saveUserToPrefs(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save each field individually
      await prefs.setString('user_id', userData['id'] ?? '');
      await prefs.setString('user_name', userData['name'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_username', userData['username'] ?? '');
      await prefs.setString('user_mobile', userData['mobile'].toString());
      await prefs.setString('user_image', userData['image'] ?? '');
      await prefs.setString('user_type', userData['type'] ?? '');
      await prefs.setString('user_address', userData['address'] ?? '');
      await prefs.setString('user_status', userData['status'] ?? '');
      
      // Save the entire user object as JSON for future use
      await prefs.setString('user_data', jsonEncode(userData));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<User?> _getUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        return User.fromJson(userMap);
      }
      
      // If complete user_data not found, try to build from individual fields
      final String? id = prefs.getString('user_id');
      final String? name = prefs.getString('user_name');
      final String? email = prefs.getString('user_email');
      final String? username = prefs.getString('user_username');
      final String? mobile = prefs.getString('user_mobile');
      final String? image = prefs.getString('user_image');
      final String? type = prefs.getString('user_type');
      final String? address = prefs.getString('user_address');
      final String? status = prefs.getString('user_status');
      
      if (id != null && name != null) {
        return User(
          id: id,
          name: name,
          email: email ?? '',
          username: username ?? '',
          mobile: mobile ?? '',
          image: image ?? '',
          type: type ?? 'Employee',
          address: address ?? '',
          status: status ?? 'Active',
        );
      }
      
      return null;
    } catch (e) {
      print('Error retrieving user data: $e');
      return null;
    }
  }
}

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  return DashboardViewModel();
});