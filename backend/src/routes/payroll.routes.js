import { Router } from "express";
import * as controller from "../controllers/payroll.controller.js";
import { authMiddleware, requireRole } from "../middlewares/auth.middleware.js";

const router = Router();
router.use(authMiddleware);

// Admin/HR: Generate Monthly Payroll (Batch)
router.post(
  "/generate",
  requireRole("ADMIN", "HR"),
  controller.generatePayroll,
);

// Admin/HR: Update Salary Structure for an Employee
router.post(
  "/salary/:employeeId",
  requireRole("ADMIN", "HR"),
  controller.updateSalaryStructure,
);

// Admin/HR: Get All Payroll History
router.get(
  "/history",
  requireRole("ADMIN", "HR"),
  controller.getAllPayrollHistory,
);

// Authenticated: Get Specific Employee Payroll
// Ideally should verify if req.user matches employeeId or is Admin
router.get("/:employeeId", controller.getEmployeePayroll);

export default router;
