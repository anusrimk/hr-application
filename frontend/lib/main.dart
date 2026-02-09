import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_screen.dart'; // New Main Screen with Tabs
import 'screens/employees/employee_list_screen.dart';
import 'screens/employees/add_employee_screen.dart';
import 'screens/employees/employee_detail_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/attendance/check_in_screen.dart';
import 'screens/leaves/leave_screen.dart';
import 'screens/payroll/payroll_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'HR Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) =>
              const MainScreen(), // Points to Tabbed Interface
          '/employees': (context) => const EmployeeListScreen(),
          '/employees/add': (context) => const AddEmployeeScreen(),
          '/employees/detail': (context) => const EmployeeDetailScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/check-in': (context) => const CheckInScreen(),
          '/leaves': (context) => const LeaveScreen(),
          '/payroll': (context) => const PayrollScreen(),
          '/profile': (context) => const ProfileScreen(), // Optional route
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await context.read<AuthProvider>().initialize();
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn) {
          return const MainScreen(); // Redirect to Tabs
        }
        return const LoginScreen();
      },
    );
  }
}
