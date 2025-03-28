import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_hrms/admin/pages/ComingSoon/ComingSoon.dart';
import 'package:new_hrms/admin/pages/addteam/addteam_view.dart';
import 'package:new_hrms/admin/pages/adduser/adduser_view.dart';
import 'package:new_hrms/admin/pages/admins/admins_view.dart';
import 'package:new_hrms/admin/pages/assignsalary/assignsalary_view.dart';
import 'package:new_hrms/admin/pages/attendance/attendance_view.dart';
import 'package:new_hrms/admin/pages/employee/employee_view.dart';
import 'package:new_hrms/admin/pages/leader/leader_view.dart';
import 'package:new_hrms/admin/pages/leave/leave_view.dart';
import 'package:new_hrms/admin/pages/team/team_view.dart';
import 'package:new_hrms/employee/pages/ComingSoon/comingsoon.dart';
import 'package:new_hrms/employee/pages/viewleave/viewleave_view.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_view.dart';
import 'package:new_hrms/employee/pages/contactus/contactus_view.dart';
import 'package:new_hrms/employee/pages/leaveapplication/leaveapplication_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_hrms/login/screens/loginPage.dart';
import 'package:new_hrms/admin/pages/dashboard/dashboard_view.dart';
import 'package:new_hrms/employee/pages/dashboard/dashboard_view.dart';
import 'package:new_hrms/providers/auth_providers.dart'; // Import providers

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',  // Start at '/'
    redirect: (context, state) async {
      // Get auth status
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final isLoggedIn = token != null;
      final storedUserType = prefs.getString('user_type') ?? '';

      // Update providers with stored values
      if (isLoggedIn && ref.read(authProvider.notifier).state != isLoggedIn) {
        ref.read(authProvider.notifier).state = isLoggedIn;
      }

      if (storedUserType.isNotEmpty && ref.read(userTypeProvider.notifier).state != storedUserType) {
        ref.read(userTypeProvider.notifier).state = storedUserType;
      }

      // Check if we're heading to the login page
      final isGoingToLogin = state.location == '/login';

      // If not logged in and not going to login, redirect to login
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      // If logged in and going to login, redirect to appropriate dashboard
      if (isLoggedIn && isGoingToLogin) {
        if (storedUserType == 'Admin') {
          return '/admin/dashboard';
        } else {
          return '/employee/dashboard';
        }
      }

      // If logged in and at root, redirect to appropriate dashboard
      if (isLoggedIn && state.location == '/') {
        if (storedUserType == 'Admin') {
          return '/admin/dashboard';
        } else if (storedUserType == 'employee') {
        return '/employee/dashboard';
    } else {
        return '/login'; // Fallback for invalid user types
    }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthCheckScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/employee/dashboard',
        builder: (context, state) =>  DashboardPage(),
      ),
      GoRoute(
        path: '/admin/employees',
        builder: (context, state) => const EmployeesScreen(),
      ),

      GoRoute(
        path: '/admin/leaders',
        builder: (context, state) => const LeadersScreen(),
      ),
      
      GoRoute(
        path: '/admin/admins',
        builder: (context, state) => const AdminsScreen(),
      ),

      GoRoute(
        path: '/admin/teams',
        builder: (context, state) => const TeamsScreen(),
      ),

      GoRoute(
        path: '/admin/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),

      GoRoute(
        path: '/admin/leaves',
        builder: (context, state) => const LeaveApplicationsPage(),
      ),

      GoRoute(
        path: '/admin/assignsalary',
        builder: (context, state) => const SalaryAssignmentScreen(),
      ),

      GoRoute(
        path: '/admin/adduser',
        builder: (context, state) => const AddUserScreen(),
      ),

      GoRoute(
        path: '/admin/addteam',
        builder: (context, state) => const AddTeamScreen(),
      ),

      GoRoute(
        path: '/employee/attendance',
        builder: (context, state) => AttendancePage(),
      ),

      GoRoute(
        path: '/employee/apply-leave',
        builder: (context, state) => ViewLeavePage(),
      ),

      GoRoute(
        path: '/employee/leave-applications',
        builder: (context, state) => LeaveApplicationPage(),
      ),

      GoRoute(
        path: '/employee/contact-us',
        builder: (context, state) => ContactPage(),
      ),

      GoRoute(
         path: '/admin/comingsoon',
          builder: (context, state) => const ComingSoonPage(),
          ),

           GoRoute(
         path: '/employee/comingsoon',
          builder: (context, state) => const ComingsoonPage(),
          ),


    ],
  );
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Flutter HRMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

/// **AuthCheckScreen: Checks JWT Authentication**
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    return token != null;
  }

  Future<String?> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');  // Fetch the role of the logged-in user (e.g., 'admin', 'employee')
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()), // Loading screen
          );
        }

        // Check the snapshot data (user role)
        if (snapshot.hasData && snapshot.data != null) {
          String userRole = snapshot.data!;

          if (userRole == 'Admin') {
            // Redirect to Admin Dashboard if the role is admin
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/admin/dashboard');
            });
          } else if (userRole == 'employee') {
            // Redirect to Employee Dashboard if the role is employee
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/employee/dashboard');
            });
          } else {
            // If the role is not valid, show login page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
          }
        } else {
          // If there's no role found, navigate to the login page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
        }

        // Default loading screen if no user role is found yet
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
