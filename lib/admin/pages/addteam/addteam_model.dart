import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'addteam_viewmodel.dart';

class TeamState {
  final bool isLoading;
  final String errorMessage;
  final bool isSuccess;

  TeamState({
    required this.isLoading,
    required this.errorMessage,
    required this.isSuccess,
  });

  // Initial State
  TeamState.initial()
      : isLoading = false,
        errorMessage = '',
        isSuccess = false;

  // Helper method to create a copy with updated fields
  TeamState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return TeamState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class TeamViewModel extends StateNotifier<TeamState> {
  final TeamModel _teamModel;

  TeamViewModel(this._teamModel) : super(TeamState.initial());

  // Add Team API Call
  Future<void> addTeam(Map<String, String> teamData) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      final response = await _teamModel.addTeam(teamData);
      
      if (response['success']) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Method to retry adding team
  void retryAddTeam(Map<String, String> teamData) {
    addTeam(teamData);
  }
}

// Team Model Provider
final teamModelProvider = Provider<TeamModel>((ref) {
  return TeamModel();
});

// Team ViewModel Provider
final teamViewModelProvider = StateNotifierProvider<TeamViewModel, TeamState>((ref) {
  final teamModel = ref.watch(teamModelProvider);
  return TeamViewModel(teamModel);
});
