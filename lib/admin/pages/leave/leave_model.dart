import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'leave_viewmodel.dart';

class LeaveState {
  final bool isLoading;
  final List<Map<String, String>> leaveApplications;
  final List<Map<String, String>> filteredLeaveApplications;
  final List<String> employeeNames;
  final String errorMessage;
  final String? selectedEmployee;

  LeaveState({
    required this.isLoading,
    required this.leaveApplications,
    required this.filteredLeaveApplications,
    required this.employeeNames,
    required this.errorMessage,
    this.selectedEmployee,
  });

  // Corrected initial constructor
  LeaveState.initial() : 
    isLoading = true,
    leaveApplications = [],
    filteredLeaveApplications = [],
    employeeNames = [],
    errorMessage = '',
    selectedEmployee = null;

  LeaveState copyWith({
    bool? isLoading,
    List<Map<String, String>>? leaveApplications,
    List<Map<String, String>>? filteredLeaveApplications,
    List<String>? employeeNames,
    String? errorMessage,
    String? selectedEmployee,
  }) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      leaveApplications: leaveApplications ?? this.leaveApplications,
      filteredLeaveApplications: filteredLeaveApplications ?? this.filteredLeaveApplications,
      employeeNames: employeeNames ?? this.employeeNames,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
    );
  }
}

class LeaveViewModel extends StateNotifier<LeaveState> {
  final LeaveModel _leaveModel;

  LeaveViewModel(this._leaveModel) : super(LeaveState.initial()) {
    fetchLeaveApplications();
    fetchEmployeeNames();
  }

  Future<void> fetchEmployeeNames() async {
    try {
      final employeeNames = await _leaveModel.fetchEmployeeNames();
      state = state.copyWith(employeeNames: employeeNames);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> fetchLeaveApplications() async {
    try {
      state = state.copyWith(
        isLoading: true, 
        errorMessage: '',
        selectedEmployee: null  // Reset selected employee
      );
      
      final leaveApplications = await _leaveModel.fetchLeaveApplications();
      
      state = state.copyWith(
        isLoading: false,
        leaveApplications: leaveApplications,
        filteredLeaveApplications: leaveApplications,
        errorMessage: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString(),
        selectedEmployee: null
      );
    }
  }

  void setSelectedEmployee(String? employee) {
    state = state.copyWith(selectedEmployee: employee);
    filterLeaveApplications();
  }

  void filterLeaveApplications() {
    List<Map<String, String>> filteredList = List.from(state.leaveApplications);

    // Filter by Employee Name
    if (state.selectedEmployee != null && state.selectedEmployee!.isNotEmpty) {
      filteredList = filteredList
          .where((leave) => leave['employeename'] == state.selectedEmployee)
          .toList();
    }
    
    state = state.copyWith(
      filteredLeaveApplications: filteredList,
    );
  }
}

final leaveModelProvider = Provider<LeaveModel>((ref) {
  return LeaveModel();
});

final leaveViewModelProvider = StateNotifierProvider<LeaveViewModel, LeaveState>((ref) {
  final leaveModel = ref.watch(leaveModelProvider);
  return LeaveViewModel(leaveModel);
});