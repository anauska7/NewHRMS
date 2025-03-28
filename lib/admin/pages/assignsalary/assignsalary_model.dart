import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'assignsalary_viewmodel.dart';

class SalaryState {
  final bool isLoading;
  final List<String> employees;
  final String? selectedEmployee;
  final String? selectedSalaryType;
  final String? selectedStatus;
  final String errorMessage;

  SalaryState({
    required this.isLoading,
    required this.employees,
    this.selectedEmployee,
    this.selectedSalaryType,
    this.selectedStatus,
    required this.errorMessage,
  });

  SalaryState.initial()
      : isLoading = true,
        employees = [],
        selectedEmployee = null,
        selectedSalaryType = null,
        selectedStatus = null,
        errorMessage = '';

  // Helper method to create a copy with updated fields
  SalaryState copyWith({
    bool? isLoading,
    List<String>? employees,
    String? selectedEmployee,
    String? selectedSalaryType,
    String? selectedStatus,
    String? errorMessage,
  }) {
    return SalaryState(
      isLoading: isLoading ?? this.isLoading,
      employees: employees ?? this.employees,
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      selectedSalaryType: selectedSalaryType ?? this.selectedSalaryType,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SalaryViewModel extends StateNotifier<SalaryState> {
  final SalaryModel _salaryModel;

  SalaryViewModel(this._salaryModel) : super(SalaryState.initial()) {
    fetchEmployees();
  }

  // Fetch Employees for dropdown
  Future<void> fetchEmployees() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      final employees = await _salaryModel.fetchEmployees();
      state = state.copyWith(isLoading: false, employees: employees);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Set selected employee
  void setSelectedEmployee(String? employee) {
    state = state.copyWith(selectedEmployee: employee);
  }

  // Set selected salary type
  void setSelectedSalaryType(String? type) {
    state = state.copyWith(selectedSalaryType: type);
  }

  // Set selected status
  void setSelectedStatus(String? status) {
    state = state.copyWith(selectedStatus: status);
  }
}

final salaryModelProvider = Provider<SalaryModel>((ref) {
  return SalaryModel();
});

final salaryViewModelProvider = StateNotifierProvider<SalaryViewModel, SalaryState>((ref) {
  final salaryModel = ref.watch(salaryModelProvider);
  return SalaryViewModel(salaryModel);
});
