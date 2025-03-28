import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_viewmodel.dart';
import 'dashboard_model.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('auth_token');
    
    if (authToken != null) {
      ref.read(dashboardViewModelProvider.notifier).fetchUserData(authToken);
    } 
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const CustomHeader(title: "Dashboard"),
      drawer: CustomDrawer(selectedScreen: "Dashboard", userName: '',),
      body: Center(
        child: dashboardState.isLoading
            ? const CircularProgressIndicator()
            : dashboardState.errorMessage.isNotEmpty
                ? _buildErrorWidget(dashboardState.errorMessage)
                : dashboardState.user != null
                    ? _buildDashboardContent(dashboardState.user!)
                    : const Text('No user data available'),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(User user) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildWelcomeBox(user),
          const SizedBox(height: 20),
          screenWidth > 600 ? _buildDetailsRow(user) : _buildDetailsBox(user),
        ],
      ),
    );
  }

  // Welcome Box with User Name
  Widget _buildWelcomeBox(User user) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Welcome ${user.name}",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 26 : 22, 
                fontWeight: FontWeight.bold, 
                color: Colors.green
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Details Box for User Information
  Widget _buildDetailsBox(User user) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoRow("Name", user.name),
            _buildInfoRow("Username", user.username),
            _buildSingleLineRow("Email", user.email),
            _buildInfoRow("Usertype", user.type),
            _buildInfoRow("Status", user.status),
            _buildInfoRow("Mobile", user.mobile),
            _buildInfoRow("Address", user.address),
            // Add profile image if needed
            user.image.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // Row layout for larger screens
  Widget _buildDetailsRow(User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoColumn("Name", user.name),
        _buildInfoColumn("Username", user.username),
        _buildInfoColumn("Email", user.email),
      ],
    );
  }

  // Info Row for Text Fields
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Flexible(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Info Column for larger screens
  Widget _buildInfoColumn(String title, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Single Line Row (For Email)
  Widget _buildSingleLineRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis, // Prevents text from wrapping
              maxLines: 1, // Ensures email remains in a single line
            ),
          ),
        ],
      ),
    );
  }
}
