import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'admins_model.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';

class AdminsScreen extends ConsumerStatefulWidget {
  const AdminsScreen({super.key});

  @override
  ConsumerState<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends ConsumerState<AdminsScreen> {
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();

    // Fetch admins on init
    Future.microtask(() {
      print("🔍 [DEBUG] AdminsScreen: Calling fetchAdmins in initState");
      ref.read(adminViewModelProvider.notifier).fetchAdmins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminViewModelProvider);
    print("🔍 [DEBUG] AdminsScreen: Building with state - isLoading: ${adminState.isLoading}, admins: ${adminState.adminData.length}, error: ${adminState.errorMessage}");

    // Get screen width and height for responsive layout
    double screenWidth = MediaQuery.of(context).size.width;

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
        appBar: const CustomHeader(title: "Admins"),
        drawer: CustomDrawer(
          selectedScreen: "Admins",
          userName: "Admin",
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            print("🔍 [DEBUG] AdminsScreen: Refresh triggered");
            await ref.read(adminViewModelProvider.notifier).fetchAdmins();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (adminState.isLoading) 
                  const Center(child: CircularProgressIndicator()),
                
                if (adminState.errorMessage.isNotEmpty) 
                  Center(child: Text("Error: ${adminState.errorMessage}", style: const TextStyle(color: Colors.red))),
                
                if (!adminState.isLoading && adminState.adminData.isNotEmpty) 
                  _AdminTable(title: "All Admins", data: adminState.adminData, screenWidth: screenWidth),
                
                if (!adminState.isLoading && adminState.adminData.isEmpty && adminState.errorMessage.isEmpty) 
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("No admins found"),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTable extends StatelessWidget {
  final String title;
  final List<Map<String, String>> data;
  final double screenWidth;

  const _AdminTable({super.key, required this.title, required this.data, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the layout based on screen width
        bool isNarrow = constraints.maxWidth < 600;
        bool isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        bool isWide = constraints.maxWidth >= 900;

        // Responsive font sizes
        double titleFontSize = isNarrow ? 18 : 22;
        double tableFontSize = isNarrow ? 12 : 14;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Title Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                ],
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),

            // Responsive Table
            if (isNarrow)
              // Vertical List View for Narrow Screens
              Column(
                children: data.map((admin) => _buildAdminCard(admin, tableFontSize)).toList(),
              )
            else
              // Horizontal DataTable for Wider Screens
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: isWide ? 40 : 20,
                  headingRowColor: MaterialStateProperty.all(Colors.green.shade50),
                  columns: [
                    _dataColumn("#", tableFontSize),
                    _dataColumn("Image", tableFontSize),
                    _dataColumn("Name", tableFontSize),
                    _dataColumn("Email", tableFontSize),
                  ],
                  rows: data.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    Map<String, String> admin = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text(index.toString(), style: TextStyle(fontSize: tableFontSize))),
                        DataCell(_buildAdminAvatar(admin)),
                        DataCell(Text(admin["name"] ?? "No Name", style: TextStyle(fontSize: tableFontSize))),
                        DataCell(Text(admin["email"] ?? "No Email", style: TextStyle(fontSize: tableFontSize))),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  // Helper method to create data columns with consistent styling
  DataColumn _dataColumn(String label, double fontSize) {
    return DataColumn(
      label: Text(
        label, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: fontSize
        )
      )
    );
  }

  // Method to build admin avatar
  Widget _buildAdminAvatar(Map<String, String> admin) {
    return CircleAvatar(
      backgroundImage: admin["image"]!.isNotEmpty
          ? NetworkImage(admin["image"]!)
          : null,
      backgroundColor: Colors.grey[300],
      radius: 18,
      child: admin["image"]!.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );
  }

  // Method to build card for narrow screens
  Widget _buildAdminCard(Map<String, String> admin, double fontSize) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        leading: _buildAdminAvatar(admin),
        title: Text(
          admin["name"] ?? "No Name", 
          style: TextStyle(
            fontSize: fontSize, 
            fontWeight: FontWeight.bold
          )
        ),
        subtitle: Text(
          admin["email"] ?? "No Email", 
          style: TextStyle(fontSize: fontSize - 2)
        ),
      ),
    );
  }
}