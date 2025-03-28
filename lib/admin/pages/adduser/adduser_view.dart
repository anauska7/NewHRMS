import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';
import 'adduser_model.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedType;
  DateTime? _lastBackPressed;

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Function to handle add user
  void _addUser() {
    final userViewModel = ref.read(userViewModelProvider.notifier);
    final userData = {
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "mobile": _mobileController.text.trim(),
      "password": _passwordController.text.trim(),
      "type": _selectedType ?? "Employee",
      "address": _addressController.text.trim(),
    };
    userViewModel.addUser(userData);
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userViewModelProvider);

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
        appBar: const CustomHeader(title: "Add User"),
        drawer: CustomDrawer(
          selectedScreen: "Add User",
          userName: userState.isSuccess ? "User added" : "Admin",
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/user_icon.png'),
              ),
              const SizedBox(height: 20),
              customTextField(
                  controller: _nameController, hintText: "Enter Name", icon: Icons.person),
              customTextField(
                  controller: _emailController, hintText: "Enter Email", icon: Icons.email),
              customTextField(
                  controller: _mobileController, hintText: "Enter Mobile Number", icon: Icons.phone),
              customTextField(
                  controller: _passwordController, hintText: "Enter Password", icon: Icons.lock, obscureText: true),

              // Dropdown for User Type
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  ),
                  hint: const Text("Select Type"),
                  value: _selectedType,
                  items: ["Admin", "Employee", "Manager"]
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
              ),

              // Address Field
              customTextField(
                  controller: _addressController, hintText: "Enter Address", icon: Icons.location_on),

              const SizedBox(height: 10),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: userState.isLoading ? null : _addUser,
                  child: userState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Add User", style: TextStyle(color: Colors.white)),
                ),
              ),
              if (userState.errorMessage.isNotEmpty) 
                Text(
                  userState.errorMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              if (userState.isSuccess) 
                const Text(
                  "User added successfully!",
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
