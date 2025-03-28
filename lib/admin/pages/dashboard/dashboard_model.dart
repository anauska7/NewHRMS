import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_viewmodel.dart';

class DashboardState {
  final bool isLoading;
  final int totalEmployees;
  final int totalLeaders;
  final int totalAdmins;
  final int totalTeams;
  final String errorMessage;

  DashboardState({
    required this.isLoading,
    required this.totalEmployees,
    required this.totalLeaders,
    required this.totalAdmins,
    required this.totalTeams,
    required this.errorMessage,
  });

  DashboardState.initial()
      : isLoading = false,
        totalEmployees = 0,
        totalLeaders = 0,
        totalAdmins = 0,
        totalTeams = 0,
        errorMessage = '';

  DashboardState copyWith({
    bool? isLoading,
    int? totalEmployees,
    int? totalLeaders,
    int? totalAdmins,
    int? totalTeams,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      totalLeaders: totalLeaders ?? this.totalLeaders,
      totalAdmins: totalAdmins ?? this.totalAdmins,
      totalTeams: totalTeams ?? this.totalTeams,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  final DashboardModel _dashboardModel;

  DashboardViewModel(this._dashboardModel) : super(DashboardState.initial()) {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true);

    try {
      final List<String> apiUrls = [
        "https://neoe2e.neophyte.live/hrms-api/api/admin/employees",
        "https://neoe2e.neophyte.live/hrms-api/api/admin/leaders",
        "https://neoe2e.neophyte.live/hrms-api/api/admin/admins",
        "https://neoe2e.neophyte.live/hrms-api/api/admin/teams", 
      ];

      final List<Future<int>> fetchData = apiUrls.map((url) => _dashboardModel.fetchCount(url)).toList();

      final responses = await Future.wait(fetchData);

      state = state.copyWith(
        isLoading: false,
        totalEmployees: responses[0],
        totalLeaders: responses[1],
        totalAdmins: responses[2],
        totalTeams: responses[3], 
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final dashboardModelProvider = Provider<DashboardModel>((ref) {
  return DashboardModel();
});

final dashboardViewModelProvider = StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  final dashboardModel = ref.watch(dashboardModelProvider);
  return DashboardViewModel(dashboardModel);
});
