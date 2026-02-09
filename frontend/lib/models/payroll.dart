class AttendanceSummary {
  final int totalDays;
  final double presentDays;
  final double lopDays;

  AttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.lopDays,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: json['totalDays'] ?? 0,
      presentDays: (json['presentDays'] ?? 0).toDouble(),
      lopDays: (json['lopDays'] ?? 0).toDouble(),
    );
  }
}

class PayrollBreakdown {
  final double basic;
  final double hra;
  final double allowances;
  final double gross;
  final double deductions;
  final double lopDeduction;
  final double netSalary;

  PayrollBreakdown({
    required this.basic,
    required this.hra,
    required this.allowances,
    required this.gross,
    required this.deductions,
    required this.lopDeduction,
    required this.netSalary,
  });

  factory PayrollBreakdown.fromJson(Map<String, dynamic> json) {
    return PayrollBreakdown(
      basic: (json['basic'] ?? 0).toDouble(),
      hra: (json['hra'] ?? 0).toDouble(),
      allowances: (json['allowances'] ?? 0).toDouble(),
      gross: (json['gross'] ?? 0).toDouble(),
      deductions: (json['deductions'] ?? 0).toDouble(),
      lopDeduction: (json['lopDeduction'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
    );
  }
}

class Payroll {
  final String id;
  final String employeeId;
  final int month;
  final int year;
  final AttendanceSummary? attendanceSummary;
  final PayrollBreakdown? breakdown;
  final String status;

  // Computed helpers for display
  double get netSalary => breakdown?.netSalary ?? 0;
  String get period => '$month/$year';

  Payroll({
    required this.id,
    required this.employeeId,
    required this.month,
    required this.year,
    this.attendanceSummary,
    this.breakdown,
    required this.status,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) {
    return Payroll(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] is String
          ? json['employeeId']
          : (json['employeeId']?['id'] ?? json['employeeId']?['_id'] ?? ''),
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      attendanceSummary: json['attendanceSummary'] != null
          ? AttendanceSummary.fromJson(json['attendanceSummary'])
          : null,
      breakdown: json['breakdown'] != null
          ? PayrollBreakdown.fromJson(json['breakdown'])
          : null,
      status: json['status'] ?? 'GENERATED',
    );
  }
}
