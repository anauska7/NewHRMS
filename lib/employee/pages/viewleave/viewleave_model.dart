// applyleave_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'viewleave_viewmodel.dart';

class ViewLeaveState {
  final bool isLoading;
  final List<ViewLeave> leaveRecords;
  final String errorMessage;

  ViewLeaveState({
    required this.isLoading,
    required this.leaveRecords,
    required this.errorMessage,
  });

  ViewLeaveState.initial()
      : isLoading = false,
        leaveRecords = [],
        errorMessage = '';

  ViewLeaveState copyWith({
    bool? isLoading,
    List<ViewLeave>? leaveRecords,
    String? errorMessage,
  }) {
    return ViewLeaveState(
      isLoading: isLoading ?? this.isLoading,
      leaveRecords: leaveRecords ?? this.leaveRecords,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ViewLeaveViewModel extends StateNotifier<ViewLeaveState> {
  final ViewLeaveModel _leaveModel;

  ViewLeaveViewModel(this._leaveModel) : super(ViewLeaveState.initial());

  Future<void> fetchLeaveRecords(String token) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');

      // Use the token to fetch the leave records
      final leaveRecords = await _leaveModel.fetchLeaveRecords(token);

      state = state.copyWith(isLoading: false, leaveRecords: leaveRecords);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final ViewleaveModelProvider = Provider<ViewLeaveModel>((ref) {
  return ViewLeaveModel();
});

final ViewleaveViewModelProvider = StateNotifierProvider<ViewLeaveViewModel, ViewLeaveState>((ref) {
  final ViewleaveModel = ref.watch(ViewleaveModelProvider);
  return ViewLeaveViewModel(ViewleaveModel);
});
