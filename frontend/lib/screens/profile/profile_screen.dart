import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../employees/employee_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, EmployeeProvider>(
      builder: (context, auth, employeeProvider, _) {
        final user = auth.user;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        if (employeeProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        try {
          // Find the employee object corresponding to the logged-in user
          // Assuming Auth user has employeeId or we match by email
          // The updated Auth model has employeeId.
          final employee = employeeProvider.employees.firstWhere(
            (e) => e.id == user.employeeId || e.email == user.email,
          );

          // Pass the employee to the detail screen which acts as the profile view
          return EmployeeDetailScreen(employee: employee);
        } catch (e) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Employee profile not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
