import 'package:flutter/material.dart';
import 'package:new_hrms/employee/screen/employee_dashboard.dart';
import 'package:new_hrms/employee/screen/employee_team.dart';
import 'package:new_hrms/employee/screen/employee_attendance.dart';
import 'package:new_hrms/employee/screen/employee_leaveapplication.dart';
import 'package:new_hrms/employee/screen/employee_applyleave.dart';
import 'package:new_hrms/employee/screen/employee_salary.dart';
import 'package:new_hrms/employee/screen/employee_payslip.dart';
import 'package:new_hrms/employee/screen/employee_contactus.dart';



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
                  screen: DashboardPage(),
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.people,
                  text: "Teams",
                  isSelected: selectedScreen == "Teams",
                  screen: TeamsPage(),
                ),
                
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  text: "Attendance",
                  isSelected: selectedScreen == "Attendance",
                  screen: AttendancePage(),
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  text: "Apply Leave",
                  isSelected: selectedScreen == "Apply Leave",
                  screen: LeaveListPage(),
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  text: "Leave Applications",
                  isSelected: selectedScreen == "Leave Applications",
                  screen: LeaveApplicationPage(),
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  text: "Salary",
                  isSelected: selectedScreen == "Salary",
                  screen: DummyScreen(title: '',),
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  text: "Payslip",
                  isSelected: selectedScreen == "Payslip",
                  screen: DummyScreen(title: '',),
                ),

                _buildDrawerSectionHeader("SETTINGS"),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  text: "Contact Us",
                  isSelected: selectedScreen == "Contact Us",
                  screen: ContactPage(),
                ),
                
              ],
            ),
          ),


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
