import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adduser_viewmodel.dart';

class UserState {
  final bool isLoading;
  final String errorMessage;
  final bool isSuccess;

  UserState({
    required this.isLoading,
    required this.errorMessage,
    required this.isSuccess,
  });

  // Initial State
  UserState.initial()
      : isLoading = false,
        errorMessage = '',
        isSuccess = false;

  // Helper method to create a copy with updated fields
  UserState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class UserViewModel extends StateNotifier<UserState> {
  final UserModel _userModel;

  UserViewModel(this._userModel) : super(UserState.initial());

  // Add User API Call
  Future<void> addUser(Map<String, String> userData) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      final response = await _userModel.addUser(userData);
      
      if (response['success']) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// User Model Provider
final userModelProvider = Provider<UserModel>((ref) {
  return UserModel();
});

// User ViewModel Provider
final userViewModelProvider = StateNotifierProvider<UserViewModel, UserState>((ref) {
  final userModel = ref.watch(userModelProvider);
  return UserViewModel(userModel);
});
