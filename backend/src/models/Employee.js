import mongoose from "mongoose";
import { EMPLOYEE_STATUS } from "../config/constants.js";

const employeeSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Employee name is required"],
      trim: true,
      maxlength: [100, "Name cannot exceed 100 characters"],
    },
    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,
      lowercase: true,
      trim: true,
    },
    department: {
      type: String,
      required: [true, "Department is required"],
      trim: true,
    },
    designation: {
      type: String,
      required: [true, "Designation is required"],
      trim: true,
    },
    joiningDate: {
      type: Date,
      required: [true, "Joining date is required"],
    },
    salaryStructure: {
      basic: {
        type: Number,
        required: [true, "Basic salary is required"],
        min: [0, "Basic salary cannot be negative"],
      },
      hra: {
        type: Number,
        default: 0,
        min: [0, "HRA cannot be negative"],
      },
      allowances: [
        {
          name: { type: String, required: true },
          amount: { type: Number, required: true, min: 0 },
        },
      ],
      deductions: [
        {
          name: { type: String, required: true },
          amount: { type: Number, required: true, min: 0 },
        },
      ],
    },
    status: {
      type: String,
      enum: {
        values: EMPLOYEE_STATUS,
        message: "Status must be one of: {VALUE}",
      },
      default: "INACTIVE",
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

export default mongoose.model("Employee", employeeSchema);
