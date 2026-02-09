import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../config/theme.dart';

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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardProvider>().fetchStats(),
            tooltip: 'Refresh Stats',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, DashboardProvider>(
        builder: (context, auth, dashboard, _) {
          final role = auth.user?.role ?? '';
          final canManage = role == 'ADMIN' || role == 'HR';

          return RefreshIndicator(
            onRefresh: () async {
              await dashboard.fetchStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              (auth.user?.name.isNotEmpty == true
                                  ? auth.user!.name
                                        .substring(0, 1)
                                        .toUpperCase()
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats cards
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.isLoading &&
                      dashboard.stats['totalEmployees'] == 0)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          context,
                          'Total Employees',
                          '${dashboard.stats['totalEmployees'] ?? 0}',
                          Icons.people,
                          AppTheme.primaryColor,
                          onTap: () =>
                              Navigator.pushNamed(
                                context,
                                '/attendance',
                                arguments: {'filter': 'TOTAL'},
                              ).then(
                                (_) => context
                                    .read<DashboardProvider>()
                                    .fetchStats(),
                              ),
                        ),
                        _buildStatCard(
                          context,
                          'Present Today',
                          '${dashboard.stats['presentToday'] ?? 0}',
                          Icons.check_circle,
                          AppTheme.accentColor,
                          onTap: () =>
                              Navigator.pushNamed(
                                context,
                                '/attendance',
                                arguments: {'filter': 'PRESENT'},
                              ).then(
                                (_) => context
                                    .read<DashboardProvider>()
                                    .fetchStats(),
                              ),
                        ),
                        _buildStatCard(
                          context,
                          'On Leave',
                          '${dashboard.stats['onLeave'] ?? 0}',
                          Icons.event_busy,
                          AppTheme.errorColor,
                          onTap: () =>
                              Navigator.pushNamed(
                                context,
                                '/attendance',
                                arguments: {'filter': 'ON_LEAVE'},
                              ).then(
                                (_) => context
                                    .read<DashboardProvider>()
                                    .fetchStats(),
                              ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Manage/View Employees
                  _buildActionTile(
                    context,
                    canManage ? 'Manage Employees' : 'View Employees',
                    canManage
                        ? 'Add, view, and edit employees'
                        : 'View employee directory',
                    Icons.person_add,
                    () => Navigator.pushNamed(context, '/employees').then(
                      (_) => context.read<DashboardProvider>().fetchStats(),
                    ),
                  ),

                  // Mark Attendance -> Self Check-in for ALL
                  _buildActionTile(
                    context,
                    'Mark Attendance',
                    'Record your daily attendance',
                    Icons.how_to_reg,
                    () => Navigator.pushNamed(context, '/check-in').then(
                      (_) => context.read<DashboardProvider>().fetchStats(),
                    ),
                  ),

                  _buildActionTile(
                    context,
                    'Leave Requests',
                    'Manage leave applications',
                    Icons.calendar_month,
                    () => Navigator.pushNamed(context, '/leaves'),
                  ),
                  _buildActionTile(
                    context,
                    'Payroll',
                    'Generate and view payroll',
                    Icons.payments,
                    () => Navigator.pushNamed(context, '/payroll'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias, // For ripple effect
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
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

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
