import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'leader_viewmodel.dart';

class LeaderState {
  final bool isLoading;
  final List<Map<String, String>> leadersData;
  final String errorMessage;

  LeaderState({
    required this.isLoading,
    required this.leadersData,
    required this.errorMessage,
  });

  LeaderState.initial()
      : isLoading = true,
        leadersData = [],
        errorMessage = '';

  // Helper method to create a copy with updated fields
  LeaderState copyWith({
    bool? isLoading,
    List<Map<String, String>>? leadersData,
    String? errorMessage,
  }) {
    return LeaderState(
      isLoading: isLoading ?? this.isLoading,
      leadersData: leadersData ?? this.leadersData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LeaderViewModel extends StateNotifier<LeaderState> {
  final LeaderModel _leaderModel;

  LeaderViewModel(this._leaderModel) : super(LeaderState.initial()) {
    print("🔍 [DEBUG] LeaderViewModel initialized");
    fetchLeaders(); // Initialize fetch operation when ViewModel is created
  }

  Future<void> fetchLeaders() async {
    try {
      print("🔍 [DEBUG] ViewModel: Fetching Leaders...");
      // Only update loading state, preserve other state values
      state = state.copyWith(isLoading: true, errorMessage: '');

      final leaders = await _leaderModel.fetchLeaders();
      
      print("🔍 [DEBUG] ViewModel: Leaders Fetched Successfully: ${leaders.length} leaders");
      state = state.copyWith(
        isLoading: false,
        leadersData: leaders,
        errorMessage: '',
      );
    } catch (e) {
      print("❌ [DEBUG] ViewModel: Error fetching leaders: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Method to retry fetching leaders
  void retryFetch() {
    fetchLeaders();
  }
}

final leaderModelProvider = Provider<LeaderModel>((ref) {
  return LeaderModel();
});

final leaderViewModelProvider = StateNotifierProvider<LeaderViewModel, LeaderState>((ref) {
  final leaderModel = ref.watch(leaderModelProvider);
  return LeaderViewModel(leaderModel);
});