import express from "express";
import mongoose from "mongoose";
import cors from "cors";

// Import routes
import calorieRoutes from "./routes/calorieRoutes.js";
import authRoutes from "./routes/authRoutes.js";
import mealRoutes from "./routes/mealRoutes.js";

const app = express();
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

const PORT = process.env.PORT || 3000;

// ====== Middleware ======
app.use(cors());
app.use(express.json());

// ====== Kết nối MongoDB ======
mongoose
  .connect("mongodb://127.0.0.1:27017/calorieDB", {
  })
  .then(() => console.log("✅ MongoDB connected"))
  .catch((err) => console.error("❌ MongoDB connection error:", err));

// ====== Routes ======
app.use("/api/calories", calorieRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/meals", mealRoutes);

// ====== Mặc định root ======
app.get("/", (req, res) => {
  res.send("🔥 Calorie Prediction API đang chạy!");
});

// ====== Server khởi chạy ======
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
