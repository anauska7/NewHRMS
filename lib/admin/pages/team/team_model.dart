import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'team_viewmodel.dart';

class TeamsState {
  final bool isLoading;
  final List<Map<String, String>> teamsData;
  final String errorMessage;

  TeamsState({
    required this.isLoading,
    required this.teamsData,
    required this.errorMessage,
  });

  TeamsState.initial()
      : isLoading = false,
        teamsData = [],
        errorMessage = '';

  TeamsState copyWith({
    bool? isLoading,
    List<Map<String, String>>? teamsData,
    String? errorMessage,
  }) {
    return TeamsState(
      isLoading: isLoading ?? this.isLoading,
      teamsData: teamsData ?? this.teamsData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TeamsViewModel extends StateNotifier<TeamsState> {
  final TeamsModel _teamsModel;

  TeamsViewModel(this._teamsModel) : super(TeamsState.initial()) {
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final teams = await _teamsModel.fetchTeams();
      state = state.copyWith(isLoading: false, teamsData: teams, errorMessage: '');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final teamsModelProvider = Provider<TeamsModel>((ref) {
  return TeamsModel();
});

final teamsViewModelProvider = StateNotifierProvider<TeamsViewModel, TeamsState>((ref) {
  final teamsModel = ref.watch(teamsModelProvider);
  return TeamsViewModel(teamsModel);
});
