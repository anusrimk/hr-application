import "dotenv/config";
import app from "./app.js";
import connectDB from "./config/db.js";
import { PORT } from "./config/constants.js";
import initCron from "./jobs/attendance.job.js";

connectDB();
initCron();

app.listen(PORT, () => {
  console.log("Server running on port", PORT);
});
