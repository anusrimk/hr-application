import Payroll from "../models/Payroll.js";
import Attendance from "../models/Attendance.js";

export const runPayroll = async (employee, month, year) => {
  // 1. Calculate Days in Month
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 0); // Last day of month
  const totalDays = endDate.getDate();

  // 2. Fetch Attendance for the Month
  const attendanceRecords = await Attendance.find({
    employeeId: employee._id,
    date: { $gte: startDate, $lte: endDate },
  });

  // 3. Analyze Attendance
  let presentDays = 0;
  let lopDays = 0;

  attendanceRecords.forEach((record) => {
    if (record.status === "PRESENT") presentDays += 1;
    else if (record.status === "HALF_DAY") presentDays += 0.5;
    else if (record.status === "ABSENT") lopDays += 1;
    // LEAVE is authorized, so not added to Present OR LOP.
  });

  // 4. Financial Calculations
  const { basic, hra, allowances, deductions } = employee.salaryStructure;

  const totalAllowances = allowances.reduce(
    (sum, item) => sum + item.amount,
    0,
  );
  const totalDeductions = deductions.reduce(
    (sum, item) => sum + item.amount,
    0,
  );

  const grossSalary = basic + hra + totalAllowances;
  const perDaySalary = grossSalary / totalDays;

  const lopDeduction = lopDays * perDaySalary;
  const netSalary = grossSalary - totalDeductions - lopDeduction;

  // 5. Create/Update Payroll Record
  // Check if already exists to update instead of duplicate
  const payrollData = {
    employeeId: employee._id,
    month,
    year,
    attendanceSummary: {
      totalDays,
      presentDays,
      lopDays,
    },
    breakdown: {
      basic,
      hra,
      allowances: totalAllowances,
      gross: grossSalary,
      deductions: totalDeductions,
      lopDeduction: parseFloat(lopDeduction.toFixed(2)),
      netSalary: parseFloat(netSalary.toFixed(2)),
    },
    status: "GENERATED",
  };

  const payroll = await Payroll.findOneAndUpdate(
    { employeeId: employee._id, month, year },
    payrollData,
    { new: true, upsert: true }, // Create if not exists
  );

  return payroll;
};

export const getEmployeePayroll = async (employeeId) => {
  return await Payroll.find({ employeeId }).sort({ year: -1, month: -1 });
};

export const getPayrollHistory = async () => {
  // Admin view: All payrolls
  // Potentially populate employee details
  return await Payroll.find()
    .sort({ year: -1, month: -1 })
    .populate("employeeId", "name department designation");
};
