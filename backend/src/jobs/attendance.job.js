import cron from "node-cron";
import Employee from "../models/Employee.js";
import Attendance from "../models/Attendance.js";
import Leave from "../models/Leave.js";

// Run at 00:00 every day
// Syntax: second(optional) minute hour day-of-month month day-of-week
const initCron = () => {
  console.log("Initializing Attendance Cron Job (Runs daily at 00:00)");

  cron.schedule("0 0 * * *", async () => {
    console.log("Running Daily Attendance Reset Job...");
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      // 1. Get all ACTIVE employees
      const activeEmployees = await Employee.find({ status: "ACTIVE" });

      if (activeEmployees.length === 0) {
        console.log("No active employees found. Skipping attendance reset.");
        return;
      }

      console.log(
        `Processing attendance reset for ${activeEmployees.length} active employees.`,
      );

      // 2. Fetch all APPROVED leaves that cover today
      const activeLeaves = await Leave.find({
        startDate: { $lte: today },
        endDate: { $gte: today },
        status: "APPROVED",
      });

      const employeesOnLeave = new Set(
        activeLeaves.map((l) => l.employeeId.toString()),
      );

      let absentCount = 0;
      let leaveCount = 0;

      for (const employee of activeEmployees) {
        const empId = employee._id.toString();

        // 3. Mark as LEAVE if on approved leave, else ABSENT
        const status = employeesOnLeave.has(empId) ? "LEAVE" : "ABSENT";

        // Check if record already exists (e.g. if script ran twice or manual entry)
        const existingRecord = await Attendance.findOne({
          employeeId: empId,
          date: { $gte: today, $lt: tomorrow },
        });

        if (!existingRecord) {
          await Attendance.create({
            employeeId: empId,
            date: today,
            status: status,
          });

          if (status === "LEAVE") leaveCount++;
          else absentCount++;
        }
      }

      console.log(`Daily Attendance Reset Complete.`);
      console.log(`- Marked Absent: ${absentCount}`);
      console.log(`- Marked On Leave: ${leaveCount}`);
    } catch (error) {
      console.error("Error in Attendance Cron Job:", error);
    }
  });
};

export default initCron;
