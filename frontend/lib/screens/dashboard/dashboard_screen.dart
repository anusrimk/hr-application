import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../config/theme.dart';
import '../attendance/check_in_screen.dart';
import '../attendance/daily_attendance_screen.dart';
import '../main_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().fetchStats();
        _checkAttendanceStatus();
      }
    });
  }

  void _checkAttendanceStatus() {
    final auth = context.read<AuthProvider>();
    if (auth.user?.employeeId != null) {
      context.read<AttendanceProvider>().fetchAttendanceHistory(
        auth.user!.employeeId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardProvider>().fetchStats();
              _checkAttendanceStatus();
            },
          ),
        ],
      ),
      body: Consumer3<AuthProvider, DashboardProvider, AttendanceProvider>(
        builder: (context, auth, dashboard, attendance, _) {
          final role = auth.user?.role ?? '';
          final canManage = role == 'ADMIN' || role == 'HR';

          // Check attendance status
          final today = DateTime.now();
          final isCheckedIn = attendance.attendanceHistory.any((r) {
            final rDate = r.date.toLocal();
            return rDate.year == today.year &&
                rDate.month == today.month &&
                rDate.day == today.day &&
                (r.status == 'PRESENT' || r.status == 'HALF_DAY');
          });

          return RefreshIndicator(
            onRefresh: () async {
              await dashboard.fetchStats();
              _checkAttendanceStatus();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(context, auth),
                  const SizedBox(height: 24),

                  // Attendance Action
                  const Text(
                    'Attendance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildAttendanceCard(context, isCheckedIn),
                  const SizedBox(height: 24),

                  // Overview Stats
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsGrid(context, dashboard),
                  const SizedBox(height: 24),

                  // Manage Employees Tile
                  _buildEmployeesTile(context, canManage),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthProvider auth) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Switch to Profile Tab (Index 3)
          final mainState = context.findAncestorStateOfType<MainScreenState>();
          if (mainState != null) {
            mainState.switchToTab(3);
          } else {
            // Fallback if not found (should not happen in MainScreen structure)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not switch tab')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  (auth.user?.name.isNotEmpty == true
                      ? auth.user!.name[0].toUpperCase()
                      : 'U'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      auth.user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      auth.user?.role ?? 'Employee',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, bool isCheckedIn) {
    if (isCheckedIn) {
      return Card(
        color: Colors.green.withAlpha(25),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checked In',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'You are present today.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 32, color: Colors.orange),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not Checked In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Mark your attendance now.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const CheckInScreen()),
                  ).then((_) {
                    final auth = context.read<AuthProvider>();
                    if (auth.user?.employeeId != null) {
                      context.read<AttendanceProvider>().fetchAttendanceHistory(
                        auth.user!.employeeId!,
                      );
                      context.read<DashboardProvider>().fetchStats();
                    }
                  });
                },
                child: const Text('Check In'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatsGrid(BuildContext context, DashboardProvider dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Employees',
          '${dashboard.stats['totalEmployees'] ?? 0}',
          Icons.people,
          AppTheme.primaryColor,
          onTap: () => Navigator.pushNamed(context, '/employees'),
        ),
        _buildStatCard(
          'Present Today',
          '${dashboard.stats['presentToday'] ?? 0}',
          Icons.check_circle,
          AppTheme.accentColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const DailyAttendanceScreen(initialFilter: 'PRESENT'),
            ),
          ),
        ),
        _buildStatCard(
          'On Leave',
          '${dashboard.stats['onLeave'] ?? 0}',
          Icons.event_busy,
          AppTheme.errorColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const DailyAttendanceScreen(initialFilter: 'ABSENT'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeesTile(BuildContext context, bool canManage) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.people_outline, color: AppTheme.primaryColor),
        ),
        title: Text(
          canManage ? 'Manage Employees' : 'View Employees',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          canManage
              ? 'Add and edit employee details'
              : 'View employee directory',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, '/employees'),
      ),
    );
  }
}
