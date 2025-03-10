import 'package:flutter/material.dart';
import 'package:new_hrms/admin/screen/admindashboard.dart';
import 'package:new_hrms/admin/screen/admin_employee.dart';
import 'package:new_hrms/admin/screen/admin_leader.dart';
import 'package:new_hrms/admin/screen/admin.dart';
import 'package:new_hrms/admin/screen/admin_assignsalary.dart';
import 'package:new_hrms/admin/screen/admin_leave.dart';
import 'package:new_hrms/admin/screen/admin_attendance.dart';
import 'package:new_hrms/admin/screen/admin_team.dart';
import 'package:new_hrms/admin/screen/admin_adduser.dart';
import 'package:new_hrms/admin/screen/admin_addteam.dart';




class CustomDrawer extends StatelessWidget {
  final String selectedScreen;

  const CustomDrawer({super.key, required this.selectedScreen});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: Image.network(
                "https://www.neophyte.ai/assets/logo.png",
                height: 50,
              ),
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  text: "Dashboard",
                  isSelected: selectedScreen == "Dashboard",
                  screen: const DashboardScreen(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.group,
                  text: "Employees",
                  isSelected: selectedScreen == "Employees",
                  screen: const EmployeesScreen(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.supervisor_account,
                  text: "Leaders",
                  isSelected: selectedScreen == "Leaders",
                  screen: const LeadersScreen(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.admin_panel_settings,
                  text: "Admins",
                  isSelected: selectedScreen == "Admins",
                  screen: const AdminsScreen(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.fireplace,
                  text: "Teams",
                  isSelected: selectedScreen == "Teams",
                  screen: const TeamsScreen(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.access_time,
                  text: "Attendance",
                  isSelected: selectedScreen == "Attendance",
                  screen: const AttendanceScreen(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.assignment,
                  text: "Leaves",
                  isSelected: selectedScreen == "Leaves",
                  screen: const LeaveApplicationsPage(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.edit,
                  text: "Assign Salary",
                  isSelected: selectedScreen == "Assign Salary",
                  screen: const SalaryAssignmentScreen(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_balance_wallet,
                  text: "Salaries",
                  isSelected: selectedScreen == "Salaries",
                  screen: const DummyScreen(title: "Salaries"),
                ),

                _buildDrawerSectionHeader("STARTER"),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person_add,
                  text: "Add User",
                  isSelected: selectedScreen == "Add User",
                  screen: const AddUserScreen(),),
    
                _buildDrawerItem(
                  context: context,
                  icon: Icons.group_add,
                  text: "Add Team",
                  isSelected: selectedScreen == "Add Team",
                  screen: const AddTeamScreen(),
                ),
              ],
            ),
          ),

          // Settings Section
          _buildDrawerSectionHeader("SETTINGS"),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Drawer Item Widget with Navigation
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Widget screen,
    required bool isSelected,
  }) {
    return Container(
      color: isSelected ? Colors.green : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.black),
        title: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }

  // Section Header (STARTER, SETTINGS)
  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}



class DummyScreen extends StatelessWidget {
  final String title;

  const DummyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Text(
          "$title Screen",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
