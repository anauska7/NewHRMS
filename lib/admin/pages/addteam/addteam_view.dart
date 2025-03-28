import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';
import 'addteam_model.dart';

class AddTeamScreen extends ConsumerStatefulWidget {
  const AddTeamScreen({super.key});

  @override
  ConsumerState<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends ConsumerState<AddTeamScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _lastBackPressed;

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to handle adding the team
  void _addTeam() {
    final teamViewModel = ref.read(teamViewModelProvider.notifier);
    final teamData = {
      "name": _nameController.text.trim(),
      "description": _descriptionController.text.trim(),
    };
    teamViewModel.addTeam(teamData);
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamViewModelProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final DateTime now = DateTime.now();
        
        // If this is the first back button press or too much time has passed
        if (_lastBackPressed == null || 
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          // Show snackbar to indicate first back press
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to go to dashboard'),
              duration: Duration(seconds: 2),
            ),
          );
          
          // Update last back pressed time
          _lastBackPressed = now;
          
          return;
        }
        
        // If back is pressed twice in quick succession
        if (now.difference(_lastBackPressed!) <= const Duration(seconds: 2)) {
          // Use GoRouter to go to dashboard
          context.go('/admin/dashboard');
        }
      },
      child: Scaffold(
        appBar: const CustomHeader(title: "Add Team"),
        drawer: CustomDrawer(
          selectedScreen: "Add Team",
          userName: teamState.isSuccess ? "Team added" : "Admin",
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/team_icon.png'),
              ),
              const SizedBox(height: 20),
              customTextField(controller: _nameController, hintText: "Enter Team Name", icon: Icons.group),
              customTextField(controller: _descriptionController, hintText: "Enter Team Description", icon: Icons.description),
              const SizedBox(height: 10),
              // Submit Button with responsiveness
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: teamState.isLoading ? null : _addTeam,
                  child: teamState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Add Team", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              // Success or Error Message
              if (teamState.errorMessage.isNotEmpty)
                Text(
                  teamState.errorMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              if (teamState.isSuccess)
                const Text(
                  "Team added successfully!",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Custom Text Field**
  Widget customTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        ),
      ),
    );
  }
}
