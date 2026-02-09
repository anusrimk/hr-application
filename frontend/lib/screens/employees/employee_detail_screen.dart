import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../models/payroll.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/payroll_service.dart';
import '../../config/theme.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  // Payroll History Future
  Future<List<Payroll>>? _payrollHistoryFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Employee) {
      _payrollHistoryFuture = PayrollService.getEmployeePayroll(args.id);
    }
  }

  void _showEditProfileDialog(BuildContext context, Employee employee) {
    final nameController = TextEditingController(text: employee.name);
    final departmentController = TextEditingController(
      text: employee.department,
    );
    final designationController = TextEditingController(
      text: employee.designation,
    );
    String status = employee.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextField(
                  controller: designationController,
                  decoration: const InputDecoration(labelText: 'Designation'),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Status'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      isDense: true,
                      onChanged: (val) => setState(() => status = val!),
                      items: ['ACTIVE', 'INACTIVE', 'TERMINATED']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final provider = ctx.read<EmployeeProvider>();
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(ctx);

                final success = await provider.updateEmployee(employee.id, {
                  'name': nameController.text,
                  'department': departmentController.text,
                  'designation': designationController.text,
                  'status': status,
                  // Salary is managed in Salary Tab
                });

                if (success) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Employee)
      return const Scaffold(
        body: Center(child: Text('Error: No employee selected')),
      );

    final argEmployee = args;

    return Consumer2<AuthProvider, EmployeeProvider>(
      builder: (context, auth, employeeProvider, _) {
        final employee = employeeProvider.employees.firstWhere(
          (e) => e.id == argEmployee.id,
          orElse: () => argEmployee,
        );

        final role = auth.user?.role ?? '';
        final isAdmin = role == 'ADMIN' || role == 'HR';

        return DefaultTabController(
          length: isAdmin ? 2 : 1,
          child: Scaffold(
            appBar: AppBar(
              title: Text(employee.name),
              bottom: TabBar(
                tabs: [
                  const Tab(text: 'Overview'),
                  if (isAdmin) const Tab(text: 'Payroll & Salary'),
                ],
              ),
              actions: isAdmin
                  ? [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showEditProfileDialog(context, employee),
                      ),
                    ]
                  : null,
            ),
            body: TabBarView(
              children: [
                _buildOverviewTab(context, employee, isAdmin),
                if (isAdmin) _buildPayrollTab(context, employee),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Employee employee,
    bool isAdmin,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(context, employee),
          const SizedBox(height: 16),
          // Info Cards
          _buildInfoCard(context, 'Personal Information', [
            _buildInfoRow('Email', employee.email, Icons.email_outlined),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard(context, 'Employment Details', [
            _buildInfoRow('Department', employee.department, Icons.business),
            _buildInfoRow(
              'Designation',
              employee.designation,
              Icons.work_outline,
            ),
            _buildInfoRow(
              'Joining Date',
              DateFormat('MMM dd, yyyy').format(employee.joiningDate),
              Icons.calendar_today,
            ),
          ]),
          const SizedBox(height: 12),
          // Salary Summary (Read Only here)
          _buildInfoCard(context, 'Current Salary', [
            _buildInfoRow(
              'Gross Salary',
              '₹${NumberFormat('#,##,###').format(employee.salaryStructure.grossSalary)}',
              Icons.payments_outlined,
            ),
            if (isAdmin)
              Text(
                'Manage structure in Payroll tab',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              employee.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              employee.designation,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            // Today's Attendance Logic (Same as before)
            FutureBuilder<List<Attendance>>(
              future: AttendanceService.getEmployeeAttendance(employee.id),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final latest = snapshot.data!.first;
                  final now = DateTime.now();
                  final localDate = latest.date.toLocal();
                  final isToday =
                      localDate.year == now.year &&
                      localDate.month == now.month &&
                      localDate.day == now.day;

                  if (isToday) {
                    Color color;
                    switch (latest.status) {
                      case 'PRESENT':
                        color = AppTheme.accentColor;
                        break;
                      case 'ABSENT':
                        color = AppTheme.errorColor;
                        break;
                      case 'HALF_DAY':
                        color = AppTheme.warningColor;
                        break;
                      case 'LEAVE':
                        color = Colors.purple;
                        break;
                      default:
                        color = Colors.grey;
                    }
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withAlpha(50)),
                      ),
                      child: Text(
                        'Today: ${latest.status}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollTab(BuildContext context, Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalaryStructureCard(context, employee),
          const SizedBox(height: 24),
          Text(
            'Payroll History',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Payroll>>(
            future: _payrollHistoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              final history = snapshot.data ?? [];
              if (history.isEmpty)
                return const Text('No payroll records generated yet.');

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final payroll = history[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withAlpha(25),
                        child: Icon(
                          Icons.receipt_long,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        '${DateFormat('MMMM yyyy').format(DateTime(payroll.year, payroll.month))}',
                      ),
                      subtitle: Text(
                        'Net Pay: ₹${NumberFormat('#,##,###').format(payroll.netSalary)}',
                      ),
                      trailing: Chip(
                        label: Text(
                          payroll.status,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: payroll.status == 'PAID'
                            ? AppTheme.accentColor
                            : Colors.orange,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryStructureCard(BuildContext context, Employee employee) {
    final structure = employee.salaryStructure;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Salary Structure',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_note,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => _showEditSalaryDialog(context, employee),
                ),
              ],
            ),
            const Divider(),
            _buildSalaryRow('Basic Pay', structure.basic),
            _buildSalaryRow('HRA', structure.hra),
            if (structure.allowances.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Allowances',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              ...structure.allowances.map(
                (a) => _buildSalaryRow(a.name, a.amount),
              ),
            ],
            if (structure.deductions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Deductions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              ...structure.deductions.map(
                (d) => _buildSalaryRow(d.name, -d.amount, isDeduction: true),
              ),
            ],
            const Divider(),
            _buildSalaryRow(
              'Gross Salary',
              structure.grossSalary,
              isBold: true,
            ),
            _buildSalaryRow(
              'Net Estimate',
              structure.netEstimate,
              isBold: true,
              color: AppTheme.accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryRow(
    String label,
    double amount, {
    bool isDeduction = false,
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            '${isDeduction ? '-' : ''}₹${NumberFormat('#,##,###').format(amount.abs())}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDeduction ? AppTheme.errorColor : color,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSalaryDialog(BuildContext context, Employee employee) {
    // This would be a more complex dialog with dynamic lists for allowances
    // For MVP, simplify to Basic + HRA editing.
    final basicController = TextEditingController(
      text: employee.salaryStructure.basic.toString(),
    );
    final hraController = TextEditingController(
      text: employee.salaryStructure.hra.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Salary Structure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: basicController,
              decoration: const InputDecoration(labelText: 'Basic Pay'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: hraController,
              decoration: const InputDecoration(labelText: 'HRA'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Detailed allowances editing coming soon.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newStructure = SalaryStructure(
                basic: double.tryParse(basicController.text) ?? 0,
                hra: double.tryParse(hraController.text) ?? 0,
                allowances:
                    employee.salaryStructure.allowances, // Keep existing
                deductions: employee.salaryStructure.deductions,
              );

              try {
                await PayrollService.updateSalaryStructure(
                  employee.id,
                  newStructure,
                );
                // Refresh employee
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ctx
                      .read<EmployeeProvider>()
                      .fetchEmployees(); // Refresh list to update detail view
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Salary structure updated!')),
                  );
                }
              } catch (e) {
                if (ctx.mounted)
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
