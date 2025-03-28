import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_hrms/employee/pages/leaveapplication/leaveapplication_viewmodel.dart';

class LeaveViewModel extends StateNotifier<LeaveState> {
  LeaveViewModel() : super(LeaveState());

  final LeaveModel _leaveModel = LeaveModel();

  Future<void> applyLeave(
    String title,
    String leaveType,
    String period,
    String startDate,
    String endDate,
    String reason,
  ) async {
    state = state.copyWith(isLoading: true);
    
    final success = await _leaveModel.applyLeave(
      title,
      leaveType,
      period,
      startDate,
      endDate,
      reason,
    );

    state = state.copyWith(isLoading: false, isSuccess: success);

    // If application fails, set error message
    if (!success) {
      state = state.copyWith(errorMessage: "Failed to apply for leave. Please try again.");
    }
  }
}

// State class to handle Leave application state
class LeaveState {
  final bool isLoading;
  final bool isSuccess;
  final String errorMessage;

  LeaveState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage = '',
  });

  LeaveState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final leaveViewModelProvider =
    StateNotifierProvider<LeaveViewModel, LeaveState>((ref) {
  return LeaveViewModel();
});
