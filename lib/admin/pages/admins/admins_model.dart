import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admins_viewmodel.dart';

class AdminState {
  final bool isLoading;
  final List<Map<String, String>> adminData;
  final String errorMessage;

  AdminState({
    required this.isLoading,
    required this.adminData,
    required this.errorMessage,
  });

  AdminState.initial()
      : isLoading = true,
        adminData = [],
        errorMessage = '';

  AdminState copyWith({
    bool? isLoading,
    List<Map<String, String>>? adminData,
    String? errorMessage,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      adminData: adminData ?? this.adminData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AdminViewModel extends StateNotifier<AdminState> {
  final AdminModel _adminModel;

  AdminViewModel(this._adminModel) : super(AdminState.initial()) {
    print("🔍 [DEBUG] AdminViewModel: Initialized");
    // We'll call fetchAdmins manually to ensure it's triggered
  }

  Future<void> fetchAdmins() async {
    try {
      print("🔍 [DEBUG] AdminViewModel: Starting to fetch admins");
      state = state.copyWith(isLoading: true, errorMessage: '');
      print("🔍 [DEBUG] AdminViewModel: State updated to loading");
      
      final admins = await _adminModel.fetchAdmins();
      print("🔍 [DEBUG] AdminViewModel: Admins fetched successfully: ${admins.length}");
      
      state = state.copyWith(
        isLoading: false,
        adminData: admins,
        errorMessage: '',
      );
      print("🔍 [DEBUG] AdminViewModel: State updated with admin data");
    } catch (e) {
      print("❌ [DEBUG] AdminViewModel: Error fetching admins: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      print("❌ [DEBUG] AdminViewModel: State updated with error");
    }
  }

  // Method to retry fetching admins
  void retryFetch() {
    print("🔍 [DEBUG] AdminViewModel: Retrying fetch");
    fetchAdmins();
  }
}

// Create the providers
final adminModelProvider = Provider<AdminModel>((ref) {
  print("🔍 [DEBUG] Creating AdminModel Provider");
  return AdminModel();
});

final adminViewModelProvider = StateNotifierProvider<AdminViewModel, AdminState>((ref) {
  print("🔍 [DEBUG] Creating AdminViewModel Provider");
  final adminModel = ref.watch(adminModelProvider);
  final viewModel = AdminViewModel(adminModel);
  
  // Call fetchAdmins explicitly when the provider is created
  Future.microtask(() {
    print("🔍 [DEBUG] Provider: Calling fetchAdmins via microtask");
    viewModel.fetchAdmins();
  });
  
  return viewModel;
});