import mongoose from "mongoose";

const payrollSchema = new mongoose.Schema(
  {
    employeeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Employee",
      required: true,
    },
    month: Number,
    year: Number,

    // Attendance Summary
    attendanceSummary: {
      totalDays: { type: Number, default: 0 },
      presentDays: { type: Number, default: 0 }, // Includes Half Days (0.5)
      lopDays: { type: Number, default: 0 }, // Loss of Pay days
    },

    // Financial Breakdown
    breakdown: {
      basic: Number,
      hra: Number,
      allowances: Number,
      gross: Number,
      deductions: Number, // Standard deductions
      lopDeduction: Number, // Amount deducted for LOP
      netSalary: Number,
    },

    status: {
      type: String,
      default: "GENERATED", // GENERATED | PAID
    },
  },
  { timestamps: true },
);

export default mongoose.model("Payroll", payrollSchema);
