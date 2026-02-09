class SalaryComponent {
  final String name;
  final double amount;

  SalaryComponent({required this.name, required this.amount});

  factory SalaryComponent.fromJson(Map<String, dynamic> json) {
    return SalaryComponent(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

class SalaryStructure {
  final double basic;
  final double hra;
  final List<SalaryComponent> allowances;
  final List<SalaryComponent> deductions;

  SalaryStructure({
    required this.basic,
    required this.hra,
    this.allowances = const [],
    this.deductions = const [],
  });

  factory SalaryStructure.fromJson(Map<String, dynamic> json) {
    return SalaryStructure(
      basic: (json['basic'] ?? 0).toDouble(),
      hra: (json['hra'] ?? 0).toDouble(),
      allowances:
          (json['allowances'] as List?)
              ?.map((e) => SalaryComponent.fromJson(e))
              .toList() ??
          [],
      deductions:
          (json['deductions'] as List?)
              ?.map((e) => SalaryComponent.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'basic': basic,
    'hra': hra,
    'allowances': allowances.map((e) => e.toJson()).toList(),
    'deductions': deductions.map((e) => e.toJson()).toList(),
  };

  double get totalAllowances =>
      allowances.fold(0, (sum, item) => sum + item.amount);
  double get totalDeductions =>
      deductions.fold(0, (sum, item) => sum + item.amount);
  double get grossSalary => basic + hra + totalAllowances;
  double get netEstimate => grossSalary - totalDeductions;
}

class Employee {
  final String id;
  final String name;
  final String email;
  final String department;
  final String designation;
  final DateTime joiningDate;
  final SalaryStructure salaryStructure;
  final String status;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
    required this.joiningDate,
    required this.salaryStructure,
    required this.status,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      joiningDate: DateTime.parse(
        json['joiningDate'] ?? DateTime.now().toIso8601String(),
      ),
      salaryStructure: json['salaryStructure'] != null
          ? SalaryStructure.fromJson(json['salaryStructure'])
          : SalaryStructure(
              basic: (json['salary'] ?? 0).toDouble(), // Fallback for legacy
              hra: 0,
            ),
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'designation': designation,
      'joiningDate': joiningDate.toIso8601String(),
      'salaryStructure': salaryStructure.toJson(),
      'status': status,
    };
  }

  // Backward compatibility getter if needed
  double get salary => salaryStructure.grossSalary;
}
