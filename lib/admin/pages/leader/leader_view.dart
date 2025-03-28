import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'leader_model.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';

class LeadersScreen extends ConsumerStatefulWidget {
  const LeadersScreen({super.key});

  @override
  ConsumerState<LeadersScreen> createState() => _LeadersScreenState();
}

class _LeadersScreenState extends ConsumerState<LeadersScreen> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final leaderState = ref.watch(leaderViewModelProvider);

    // Get screen width for responsive layout
    double screenWidth = MediaQuery.of(context).size.width;

    // Determine font size based on screen width
    double titleFontSize = screenWidth < 600 ? 18 : 22;
    double headerFontSize = screenWidth < 600 ? 14 : 16;
    double subtitleFontSize = screenWidth < 600 ? 12 : 14;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final DateTime now = DateTime.now();

        // If this is the first back button press or too much time has passed
        if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
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
        appBar: const CustomHeader(title: "Leaders"),
        drawer: CustomDrawer(
          selectedScreen: "Leaders",
          userName: "Admin",
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // Trigger a refresh
            ref.read(leaderViewModelProvider.notifier).fetchLeaders();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                    ],
                  ),
                  child: Text(
                    "All Leaders ${!leaderState.isLoading && leaderState.leadersData.isNotEmpty ? '(${leaderState.leadersData.length})' : ''}",
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (leaderState.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (leaderState.errorMessage.isNotEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "❌ ${leaderState.errorMessage}",
                          style: TextStyle(fontSize: subtitleFontSize, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(leaderViewModelProvider.notifier).retryFetch();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                if (!leaderState.isLoading && leaderState.leadersData.isNotEmpty)
                  ListView.builder(
                    itemCount: leaderState.leadersData.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      var leader = leaderState.leadersData[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            backgroundImage: leader['image'] != null && leader['image']!.isNotEmpty
                                ? NetworkImage(leader['image']!)
                                : null,
                            child: leader['image'] == null || leader['image']!.isEmpty
                                ? const Icon(Icons.person, color: Colors.green)
                                : null,
                          ),
                          title: Text(
                            leader['name'] ?? "No Name",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize),
                          ),
                          subtitle: Text(leader['email'] ?? "No Email", style: TextStyle(fontSize: subtitleFontSize)),
                        ),
                      );
                    },
                  ),
                if (!leaderState.isLoading && leaderState.leadersData.isEmpty && leaderState.errorMessage.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 100.0),
                      child: Text(
                        "No Leaders Found!",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  