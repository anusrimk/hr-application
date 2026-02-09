import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class DailyAttendanceScreen extends StatefulWidget {
  final String initialFilter; // 'ALL', 'PRESENT', 'ABSENT'

  const DailyAttendanceScreen({super.key, this.initialFilter = 'ALL'});

  @override
  State<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends State<DailyAttendanceScreen> {
  bool _isLoading = true;
  List<Attendance> _allAttendance = [];
  List<Attendance> _filteredAttendance = [];
  String _currentFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _fetchDailyAttendance();
  }

  Future<void> _fetchDailyAttendance() async {
    setState(() => _isLoading = true);
    try {
      final data = await AttendanceService.getDailyAttendance(DateTime.now());
      if (mounted) {
        setState(() {
          _allAttendance = data;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading attendance: $e')));
      }
    }
  }

  void _applyFilter() {
    if (_currentFilter == 'ALL') {
      _filteredAttendance = List.from(_allAttendance);
    } else if (_currentFilter == 'PRESENT') {
      _filteredAttendance = _allAttendance
          .where((a) => a.status == 'PRESENT' || a.status == 'HALF_DAY')
          .toList();
    } else if (_currentFilter == 'ABSENT') {
      // 'On Leave' includes ABSENT and LEAVE
      _filteredAttendance = _allAttendance
          .where((a) => a.status == 'ABSENT' || a.status == 'LEAVE')
          .toList();
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _currentFilter = filter;
      _applyFilter();
    });
  }

  Future<void> _updateStatus(Attendance record, String status) async {
    Navigator.pop(context); // Close bottom sheet
    setState(() => _isLoading = true);
    try {
      await AttendanceService.markAttendance(
        employeeId: record.employeeId,
        date: record.date,
        status: status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance updated successfully')),
        );
        _fetchDailyAttendance(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  void _showEditSheet(Attendance record) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark Present'),
                onTap: () => _updateStatus(record, 'PRESENT'),
              ),
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.orange),
                title: const Text('Mark Half Day'),
                onTap: () => _updateStatus(record, 'HALF_DAY'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Mark Absent'),
                onTap: () => _updateStatus(record, 'ABSENT'),
              ),
              ListTile(
                leading: const Icon(Icons.event_busy, color: Colors.blue),
                title: const Text('Mark Leave'),
                onTap: () => _updateStatus(record, 'LEAVE'),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PRESENT':
        return Colors.green;
      case 'HALF_DAY':
        return Colors.orange;
      case 'ABSENT':
        return Colors.red;
      case 'LEAVE':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check role
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.user?.role == 'ADMIN' || auth.user?.role == 'HR';

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Attendance')),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('Present', 'PRESENT'),
                const SizedBox(width: 8),
                _buildFilterChip('On Leave', 'ABSENT'),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAttendance.isEmpty
                ? const Center(child: Text('No records found.'))
                : ListView.builder(
                    itemCount: _filteredAttendance.length,
                    itemBuilder: (context, index) {
                      final record = _filteredAttendance[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          onTap: isAdmin ? () => _showEditSheet(record) : null,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              (record.employeeName?.isNotEmpty == true
                                      ? record.employeeName![0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            record.employeeName ?? 'Unknown Employee',
                          ),
                          subtitle: Text(
                            record.designation ?? 'No Designation',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                record.status,
                              ).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              record.status,
                              style: TextStyle(
                                color: _getStatusColor(record.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _onFilterChanged(value);
      },
      selectedColor: AppTheme.primaryColor.withAlpha(50),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
