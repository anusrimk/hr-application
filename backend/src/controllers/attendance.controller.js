import * as attendanceService from "../services/attendance.service.js";
import Attendance from "../models/Attendance.js";

export const markAttendance = async (req, res) => {
  const { employeeId, date, status } = req.body;
  const user = req.user;

  // Employees can only mark their own attendance
  // ADMIN/HR can mark anyone's attendance
  if (user.role === "EMPLOYEE") {
    // Check if user is trying to mark their own attendance
    if (user.employeeId?.toString() !== employeeId) {
      return res.status(403).json({
        message: "You can only mark your own attendance",
      });
    }
  }

  const attendance = await attendanceService.markAttendance({
    employeeId,
    date,
    status,
  });
  res.json({
    message: "Attendance marked successfully",
    data: attendance,
  });
};

export const getEmployeeAttendance = async (req, res) => {
  const user = req.user;
  const { employeeId } = req.params;

  // Employees can only view their own attendance
  if (user.role === "EMPLOYEE") {
    if (user.employeeId?.toString() !== employeeId) {
      return res.status(403).json({
        message: "You can only view your own attendance",
      });
    }
  }

  const attendance = await attendanceService.getByEmployee(employeeId);
  res.json({ data: attendance });
};

// Get daily attendance for all employees (Admin/HR)
export const getDailyAttendance = async (req, res) => {
  const { date } = req.query;
  // Date string YYYY-MM-DD

  if (!date) {
    return res.status(400).json({ message: "Date is required" });
  }

  const d = new Date(date);
  const startOfDay = new Date(d);
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date(d);
  endOfDay.setHours(23, 59, 59, 999);

  const attendanceList = await Attendance.find({
    date: { $gte: startOfDay, $lte: endOfDay },
  }).populate("employeeId", "name designation department");

  res.json({ data: attendanceList });
};

// Self check-in for employees (marks today as PRESENT)
export const selfCheckIn = async (req, res) => {
  const user = req.user;

  if (!user.employeeId) {
    return res.status(400).json({
      message: "No employee profile linked to your account",
    });
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const attendance = await attendanceService.markAttendance({
    employeeId: user.employeeId,
    date: today.toISOString(),
    status: "PRESENT",
  });

  res.json({
    message: "Check-in successful",
    data: attendance,
  });
};
