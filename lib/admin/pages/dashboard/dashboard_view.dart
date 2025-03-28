import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';
import 'dashboard_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final dashboardViewModel = ref.read(dashboardViewModelProvider.notifier);

    // Get screen width for responsive layout
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const CustomHeader(title: "Dashboard"),
      drawer: CustomDrawer(
        selectedScreen: "Dashboard",
        userName: "Admin",  // Pass the userName to the CustomDrawer
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display loading indicator when data is being fetched
            if (dashboardState.isLoading) ...[
              const Center(child: CircularProgressIndicator())
            ] else ...[
              _buildDashboardCard(
                "Total Employees", 
                dashboardState.totalEmployees.toString(), 
                Icons.people,
                screenWidth
              ),
              _buildDashboardCard(
                "Total Leaders", 
                dashboardState.totalLeaders.toString(), 
                Icons.leaderboard,
                screenWidth
              ),
              _buildDashboardCard(
                "Total Admins", 
                dashboardState.totalAdmins.toString(), 
                Icons.admin_panel_settings,
                screenWidth
              ),
              _buildDashboardCard(
                "Total Teams", 
                dashboardState.totalTeams.toString(), 
                Icons.groups, 
                screenWidth // Pass screenWidth to adjust layout accordingly
              ),
            ],
            if (dashboardState.errorMessage.isNotEmpty) 
              Text(
                dashboardState.errorMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  // Updated _buildDashboardCard with responsive layout
  Widget _buildDashboardCard(String title, String count, IconData icon, double screenWidth) {
    // Adjusting the size based on screen width
    double cardHeight = screenWidth < 600 ? 100 : 110; // smaller height for small screens
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: SizedBox(
        height: cardHeight, // Responsive card height
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              // Green Icon Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Displaying the count
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
