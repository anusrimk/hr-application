import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/payroll.dart';
import '../../providers/auth_provider.dart';
import '../../services/payroll_service.dart';
import '../../config/theme.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  bool _isLoading = false;
  List<Payroll> _payrolls = [];

  // For admin generation
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchPayrolls();
  }

  Future<void> _fetchPayrolls() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final isAdmin = auth.user?.role == 'ADMIN' || auth.user?.role == 'HR';

      if (!isAdmin &&
          (auth.user?.employeeId == null || auth.user!.employeeId!.isEmpty)) {
        if (mounted) {
          setState(() {
            _payrolls = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No employee record linked to this account.'),
            ),
          );
        }
        return;
      }

      final data = isAdmin
          ? await PayrollService.getAllPayrollHistory()
          : await PayrollService.getEmployeePayroll(auth.user!.employeeId!);

      setState(() => _payrolls = data);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePayroll() async {
    int dialogMonth = _selectedMonth;
    int dialogYear = _selectedYear;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Generate Payroll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<int>(
                    value: dialogMonth,
                    items: List.generate(12, (index) => index + 1)
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              DateFormat('MMMM').format(DateTime(2024, m)),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => dialogMonth = val!),
                  ),
                  DropdownButton<int>(
                    value: dialogYear,
                    items: [2025, 2026, 2027, 2028]
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => dialogYear = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'This will calculate salary based on attendance for all active employees.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _selectedMonth = dialogMonth;
                _selectedYear = dialogYear;
                Navigator.pop(ctx, true);
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final result = await PayrollService.generatePayroll(
          _selectedMonth,
          _selectedYear,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Payroll generated!')),
          );
          _fetchPayrolls();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.user?.role == 'ADMIN' || auth.user?.role == 'HR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Management'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchPayrolls,
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _generatePayroll,
              label: const Text('Generate'),
              icon: const Icon(Icons.calculate),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payrolls.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAdmin
                        ? 'No payroll records found. Generate one!'
                        : 'No payslips available.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _payrolls.length,
              itemBuilder: (context, index) {
                final payroll = _payrolls[index];
                return _buildPayrollCard(payroll, isAdmin);
              },
            ),
    );
  }

  Widget _buildPayrollCard(Payroll payroll, bool isAdmin) {
    final date = DateTime(payroll.year, payroll.month);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withAlpha(25),
          child: Text(
            DateFormat('MMM').format(date),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Net Pay: ₹${NumberFormat('#,##,###').format(payroll.netSalary)} • ${payroll.status}',
          style: TextStyle(
            color: payroll.status == 'PAID'
                ? AppTheme.accentColor
                : Colors.orange,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow('Basic Pay', payroll.breakdown?.basic ?? 0),
                _buildRow('HRA', payroll.breakdown?.hra ?? 0),
                _buildRow('Allowances', payroll.breakdown?.allowances ?? 0),
                const Divider(),
                _buildRow(
                  'Gross Salary',
                  payroll.breakdown?.gross ?? 0,
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _buildRow(
                  'Deductions',
                  -(payroll.breakdown?.deductions ?? 0),
                  isDeduction: true,
                ),
                _buildRow(
                  'LOP Deduction (${payroll.attendanceSummary?.lopDays ?? 0} days)',
                  -(payroll.breakdown?.lopDeduction ?? 0),
                  isDeduction: true,
                ),
                const Divider(),
                _buildRow(
                  'Net Salary',
                  payroll.netSalary,
                  isBold: true,
                  color: AppTheme.accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
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
}
