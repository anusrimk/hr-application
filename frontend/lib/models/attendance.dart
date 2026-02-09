class Attendance {
  final String id;
  final String employeeId;
  final DateTime date;
  final String status;
  final String? employeeName;
  final String? designation;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.employeeName,
    this.designation,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    String empId = '';
    String? empName;
    String? empDesig;

    if (json['employeeId'] is Map) {
      empId = json['employeeId']['_id'] ?? json['employeeId']['id'] ?? '';
      empName = json['employeeId']['name'];
      empDesig = json['employeeId']['designation'];
    } else {
      empId = json['employeeId']?.toString() ?? '';
    }

    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: empId,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'ABSENT',
      employeeName: empName,
      designation: empDesig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}
