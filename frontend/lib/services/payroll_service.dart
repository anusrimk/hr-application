import 'api_service.dart';
import '../models/payroll.dart';
import '../models/employee.dart';

class PayrollService {
  static Future<List<Payroll>> getEmployeePayroll(String employeeId) async {
    try {
      final dynamic responseData = await ApiService.get('/payroll/$employeeId');
      if (responseData is List) {
        return responseData.map((json) => Payroll.fromJson(json)).toList();
      } else if (responseData is Map && responseData['data'] is List) {
        return (responseData['data'] as List)
            .map((json) => Payroll.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load payroll history: $e');
    }
  }

  static Future<List<Payroll>> getAllPayrollHistory() async {
    try {
      final dynamic responseData = await ApiService.get('/payroll/history');
      if (responseData is List) {
        return responseData.map((json) => Payroll.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load all payroll history: $e');
    }
  }

  static Future<Map<String, dynamic>> generatePayroll(
    int month,
    int year,
  ) async {
    try {
      final dynamic response = await ApiService.post('/payroll/generate', {
        'month': month,
        'year': year,
      });
      return response is Map<String, dynamic>
          ? response
          : {'message': 'Success'};
    } catch (e) {
      throw Exception('Failed to generate payroll: $e');
    }
  }

  static Future<void> updateSalaryStructure(
    String employeeId,
    SalaryStructure structure,
  ) async {
    try {
      await ApiService.post('/payroll/salary/$employeeId', structure.toJson());
    } catch (e) {
      throw Exception('Failed to update salary structure: $e');
    }
  }
}
