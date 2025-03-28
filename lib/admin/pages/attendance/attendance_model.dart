import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'attendance_viewmodel.dart';

class AttendanceState {
  final bool isLoading;
  final List<Map<String, String>> attendanceData;
  final List<String> employeeNames;
  final String errorMessage;

  AttendanceState({
    required this.isLoading,
    required this.attendanceData,
    required this.employeeNames,
    required this.errorMessage,
  });

  AttendanceState.initial()
      : isLoading = true,
        attendanceData = [],
        employeeNames = [],
        errorMessage = '';

  AttendanceState copyWith({
    bool? isLoading,
    List<Map<String, String>>? attendanceData,
    List<String>? employeeNames,
    String? errorMessage,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      attendanceData: attendanceData ?? this.attendanceData,
      employeeNames: employeeNames ?? this.employeeNames,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AttendanceViewModel extends StateNotifier<AttendanceState> {
  final AttendanceModel _attendanceModel;

  AttendanceViewModel(this._attendanceModel) : super(AttendanceState.initial()) {
    fetchAttendanceData();
  }

  // Fetch Attendance Data
  Future<void> fetchAttendanceData() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      final attendanceResult = await _attendanceModel.fetchAttendanceData();
      state = state.copyWith(
        isLoading: false, 
        attendanceData: attendanceResult['attendanceData'], 
        employeeNames: attendanceResult['employeeNames'],
        errorMessage: ''
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final attendanceModelProvider = Provider<AttendanceModel>((ref) {
  return AttendanceModel();
});

final attendanceViewModelProvider =
    StateNotifierProvider<AttendanceViewModel, AttendanceState>((ref) {
  final attendanceModel = ref.watch(attendanceModelProvider);
  return AttendanceViewModel(attendanceModel);
});