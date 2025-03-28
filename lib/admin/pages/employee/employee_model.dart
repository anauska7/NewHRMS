import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'employee_viewmodel.dart';

// State class to hold the employee state
class EmployeeState {
  final bool isLoading;
  final List<Map<String, String>> employeeData;
  final String errorMessage;

  EmployeeState({
    required this.isLoading,
    required this.employeeData,
    required this.errorMessage,
  });

  // Initial state with loading set to true
  EmployeeState.initial()
      : isLoading = true,
        employeeData = [],
        errorMessage = '';
        
  // Helper method to create a copy with updated fields
  EmployeeState copyWith({
    bool? isLoading,
    List<Map<String, String>>? employeeData,
    String? errorMessage,
  }) {
    return EmployeeState(
      isLoading: isLoading ?? this.isLoading,
      employeeData: employeeData ?? this.employeeData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ViewModel class that fetches employee data and updates the state
class EmployeeViewModel extends StateNotifier<EmployeeState> {
  final EmployeeModel _employeeModel;

  EmployeeViewModel(this._employeeModel) : super(EmployeeState.initial()) {
    print("🔍 [DEBUG] EmployeeViewModel initialized");
    fetchEmployees(); // Ensure fetchEmployees is called in the constructor
  }

  // Fetch employees from the model
  Future<void> fetchEmployees() async {
    try {
      print("🔍 [DEBUG] ViewModel: Fetching Employees...");
      // Only update loading state, preserve other state values
      state = state.copyWith(isLoading: true, errorMessage: '');

      final employees = await _employeeModel.fetchEmployees();
      
      print("🔍 [DEBUG] ViewModel: Employees Fetched Successfully: ${employees.length} employees");
      state = state.copyWith(
        isLoading: false,
        employeeData: employees,
        errorMessage: '',
      );
    } catch (e) {
      print("❌ [DEBUG] ViewModel: Error fetching employees: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Method to retry fetching employees
  void retryFetch() {
    fetchEmployees();
  }
}

// Creating a provider for the Employee Model
final employeeModelProvider = Provider<EmployeeModel>((ref) {
  return EmployeeModel();
});

// Creating a provider for the Employee ViewModel using the Employee Model
final employeeViewModelProvider = StateNotifierProvider<EmployeeViewModel, EmployeeState>((ref) {
  final employeeModel = ref.watch(employeeModelProvider);
  return EmployeeViewModel(employeeModel);
});