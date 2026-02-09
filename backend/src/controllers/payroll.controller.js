import Employee from "../models/Employee.js";
import * as payrollService from "../services/payroll.service.js";

// Update Employee Salary Structure
export const updateSalaryStructure = async (req, res) => {
  const { employeeId } = req.params;
  const { basic, hra, allowances, deductions } = req.body;

  try {
    const employee = await Employee.findById(employeeId);
    if (!employee) {
      return res.status(404).json({ message: "Employee not found" });
    }

    // Update structure
    employee.salaryStructure = {
      basic: Number(basic),
      hra: Number(hra),
      allowances: allowances || [], // Expect array of objects {name, amount}
      deductions: deductions || [],
    };

    await employee.save();
    res.json({
      message: "Salary structure updated",
      salaryStructure: employee.salaryStructure,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Generate Monthly Payroll for All Employees (Batch)
export const generatePayroll = async (req, res) => {
  const { month, year } = req.body; // Expect numbers 1-12, 2026

  try {
    const employees = await Employee.find({ status: "ACTIVE" });
    const results = [];

    for (const emp of employees) {
      try {
        const payroll = await payrollService.runPayroll(emp, month, year);
        results.push(payroll);
      } catch (err) {
        console.error(`Failed for ${emp.name}:`, err);
      }
    }

    res.json({
      message: `Payroll generation completed for ${results.length} employees`,
      generated: results.length,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get Payroll History (For Employee or Admin viewing Specific Employee)
export const getEmployeePayroll = async (req, res) => {
  const { employeeId } = req.params;
  try {
    const history = await payrollService.getEmployeePayroll(employeeId);
    res.json(history);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get All Payroll History (Admin Dashboard View)
export const getAllPayrollHistory = async (req, res) => {
  try {
    // Implement logic to get all payrolls, maybe paginated or filtered by month
    // For simplicity, just fetch recent 100 or filter by query params?
    // Let's rely on service function
    const history = await payrollService.getPayrollHistory(); // We need to export this in service
    res.json(history);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
