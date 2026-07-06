import dotenv from "dotenv";
dotenv.config();

import express from "express";
import mongoose from "mongoose";
import cors from "cors";

// Import routes
import calorieRoutes from "./routes/calorieRoutes.js";
import authRoutes from "./routes/authRoutes.js";
import mealRoutes from "./routes/mealRoutes.js";
import aiRoutes from "./routes/aiRoutes.js";
import feedbackRoutes from "./routes/feedbackRoutes.js";
import recordRoutes from "./routes/recordRoutes.js";

const app = express();
const PORT = process.env.PORT || 3000;

// ====== Middleware ======
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// ====== Kết nối MongoDB (Đã sửa lỗi db_user) ======
const mongoURI = process.env.MONGODB_URI;

mongoose
  .connect(mongoURI)
  .then(() => console.log(`✅ DATABASE CLOUD ĐÃ KẾT NỐI THÀNH CÔNG!`))
  .catch((err) => {
    console.error("❌ LỖI KẾT NỐI DATABASE:", err.message);
  });

// ====== Routes ======
app.use("/api/calories", calorieRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/meals", mealRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/feedback", feedbackRoutes);
app.use("/api/records", recordRoutes);

// ====== Mặc định root ======
app.get("/", (req, res) => {
  res.send("🔥 API Health Assistant đang chạy mượt mà!");
});

// ====== Server khởi chạy ======
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});