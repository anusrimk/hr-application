import { Router } from "express";
import * as controller from "../controllers/dashboard.controller.js";
import { authMiddleware, requireRole } from "../middlewares/auth.middleware.js";

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// View company-wide dashboard (All roles)
router.get("/overview", controller.getOverview);

export default router;
