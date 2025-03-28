import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerUser {
  final String name;
  final String imageUrl;

  DrawerUser({required this.name, required this.imageUrl});
}

class CustomDrawer extends StatelessWidget {
  final String selectedScreen;

  const CustomDrawer({super.key, required this.selectedScreen, required String userName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User data from FutureBuilder
          FutureBuilder<DrawerUser>(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError || !snapshot.hasData) {
                return const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Center(child: Text('Error loading user data')),
                );
              } else {
                DrawerUser user = snapshot.data!;
                return DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.white, // Plain white background
                  ),
                  child: Center( // Wrap with Center widget
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile image centered
                        CircleAvatar(
                          radius: 35, // Slightly larger radius
                          backgroundImage: NetworkImage(user.imageUrl),
                        ),
                        const SizedBox(height: 8), // Increased space between image and text
                        // Text for "Hi" and the username
                        const Text(
                          "Hi",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
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
                  screenPath: '/admin/dashboard',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.group,
                  text: "Employees",
                  isSelected: selectedScreen == "Employees",
                  screenPath: '/admin/employees',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.supervisor_account,
                  text: "Leaders",
                  isSelected: selectedScreen == "Leaders",
                  screenPath: '/admin/leaders',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.admin_panel_settings,
                  text: "Admins",
                  isSelected: selectedScreen == "Admins",
                  screenPath: '/admin/admins',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.fireplace,
                  text: "Teams",
                  isSelected: selectedScreen == "Teams",
                  screenPath: '/admin/teams',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.access_time,
                  text: "Attendance",
                  isSelected: selectedScreen == "Attendance",
                  screenPath: '/admin/attendance',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.assignment,
                  text: "Leaves",
                  isSelected: selectedScreen == "Leaves",
                  screenPath: '/admin/leaves',
                ),
                _buildDisabledDrawerItem(
                  context: context,
                  icon: Icons.edit,
                  text: "Assign Salary",
                ),
                _buildDisabledDrawerItem(
                  context: context,
                  icon: Icons.account_balance_wallet,
                  text: "Salaries",
                ),
                _buildDrawerSectionHeader("STARTER"),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person_add,
                  text: "Add User",
                  isSelected: selectedScreen == "Add User",
                  screenPath: '/admin/adduser',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.group_add,
                  text: "Add Team",
                  isSelected: selectedScreen == "Add Team",
                  screenPath: '/admin/addteam',
                ),
              ],
            ),
          ),
          // Logout Button (Placed at the bottom)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _logout(context);
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

  // Function to get user data from SharedPreferences
  Future<DrawerUser> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('user_name');
    String? imageUrl = prefs.getString('user_image_url');

    return DrawerUser(
      name: name ?? 'Admin',
      imageUrl: imageUrl ?? 'https://neoe2e.neophyte.live/hrms-api/storage/images/profile/profile-1739164521363-6574707171000100896.jpg',
    );
  }

  // Drawer Item Widget with Navigation (GoRouter Compatible)
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String screenPath,
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
          context.go(screenPath); // Navigate to the route
        },
      ),
    );
  }

  // Disabled Drawer Item
  Widget _buildDisabledDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.normal,
          color: Colors.grey,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        context.go('/admin/comingsoon'); // Navigate to the Coming Soon page
      },
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

  // Logout Logic
  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored preferences

    // After logging out, navigate to the login screen
    context.go('/login'); // Assuming '/login' is the route for the login page
  }
}
