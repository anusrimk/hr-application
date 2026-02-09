import Employee from "../models/Employee.js";
import Leave from "../models/Leave.js";
import Attendance from "../models/Attendance.js";

export const getOverview = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // 1. Get all eligible employee IDs (Active + Inactive, exclude Terminated)
  const activeEmployees = await Employee.find({
    status: { $in: ["ACTIVE", "INACTIVE"] },
  }).select("_id");
  const activeEmployeeIds = new Set(
    activeEmployees.map((e) => e._id.toString()),
  );
  const totalActive = activeEmployeeIds.size;

  // 2. Get All Attendance records for today
  const todayAttendance = await Attendance.find({
    date: { $gte: today, $lt: tomorrow },
  }).select("employeeId status");

  // Filter attendance to strictly match only Active employees
  // (Prevents historical data of now-inactive employees from skewing daily stats)
  const activeAttendance = todayAttendance.filter((a) =>
    activeEmployeeIds.has(a.employeeId.toString()),
  );

  // 3. Count Explicit Statuses
  let presentToday = 0;
  let onLeave = 0;
  const markedIds = new Set();

  activeAttendance.forEach((record) => {
    markedIds.add(record.employeeId.toString());

    if (["PRESENT", "HALF_DAY"].includes(record.status)) {
      presentToday++;
    } else if (["ABSENT", "LEAVE"].includes(record.status)) {
      onLeave++;
    }
  });

  // 4. Return Stats
  // 'onLeave' now effectively includes Absents (default state) + Leaves

  // Also keep Pending Leaves count if needed elsewhere,
  // but for the card we will send 'unmarked'
  const pendingLeaves = await Leave.countDocuments({ status: "PENDING" });

  const totalEmployees = await Employee.countDocuments(); // Count of ALL (Active + Inactive) for 'Total Employees' card
  // Or user said "'total' is count of total emps in the employees collection"

  return {
    totalEmployees, // Displaying Total (Active+Inactive) as per convention, or switch to totalActive?
    // Usually "Total Employees" implies everyone.
    // But for attendance logic, we usually care about active.
    // Let's keep it as Total Count of collection as explicitly requested.
    presentToday,
    onLeave, // Includes ABSENT and LEAVE statuses
    pendingLeaves,
  };
};
