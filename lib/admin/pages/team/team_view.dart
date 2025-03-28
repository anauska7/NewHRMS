import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';
import 'team_model.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final teamsState = ref.watch(teamsViewModelProvider);
    final teamsViewModel = ref.read(teamsViewModelProvider.notifier);

    // Get screen width for responsive design
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
        appBar: const CustomHeader(title: "Teams"),
        drawer: CustomDrawer(
          selectedScreen: "Teams",
          userName: "Admin",
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            print("🔍 [DEBUG] TeamsScreen: Refresh triggered");
            await ref.read(teamsViewModelProvider.notifier).fetchTeams();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (teamsState.isLoading) 
                  const Center(child: CircularProgressIndicator()),
                
                if (teamsState.errorMessage.isNotEmpty) 
                  Center(child: Text("Error: ${teamsState.errorMessage}", style: const TextStyle(color: Colors.red))),
                
                if (!teamsState.isLoading && teamsState.teamsData.isNotEmpty) 
                  _TeamsTable(teamsData: teamsState.teamsData, screenWidth: screenWidth),
                
                if (!teamsState.isLoading && teamsState.teamsData.isEmpty && teamsState.errorMessage.isEmpty) 
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("No teams found"),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamsTable extends StatelessWidget {
  final List<Map<String, String>> teamsData;
  final double screenWidth;

  const _TeamsTable({super.key, required this.teamsData, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: screenWidth < 600 ? 400 : 600,  // Dynamically adjust table width
        ),
        child: DataTable(
          columnSpacing: 20,
          border: TableBorder.all(color: Colors.grey.shade300),
          columns: const [
            DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Image", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Leader", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: teamsData.map((data) {
            return DataRow(cells: [
              DataCell(Text(data["id"] ?? "")),
              DataCell(CircleAvatar(
                backgroundImage: NetworkImage(data["image"]!),
                radius: 20,
              )),
              DataCell(Text(data["name"] ?? "")),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data["leader"] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data["status"] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              )),
              DataCell(ElevatedButton(
                onPressed: () {
                  // Navigate to team details page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text("Detail", style: TextStyle(color: Colors.black)),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
