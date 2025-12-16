import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";

// Import routes
import calorieRoutes from "./routes/calorieRoutes.js";
import authRoutes from "./routes/authRoutes.js";
import mealRoutes from "./routes/mealRoutes.js";

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// ====== Middleware ======
app.use(cors());
app.use(express.json());

// ====== Kết nối MongoDB (QUAN TRỌNG: Đã sửa lỗi) ======
// Logic: Ưu tiên đọc biến MONGODB_URI từ file .env (hoặc Render)
// Nếu không tìm thấy thì mới dùng localhost (để chạy máy nhà)
const mongoURI = process.env.MONGODB_URI || "mongodb://127.0.0.1:27017/calorieDB";

mongoose
  .connect(mongoURI)
  .then(() => console.log(`✅ MongoDB connected successfully to ${mongoURI.includes('127.0.0.1') ? 'Localhost' : 'Atlas Cloud'}`))
  .catch((err) => console.error("❌ MongoDB connection error:", err));

// ====== Routes ======
app.use("/api/calories", calorieRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/meals", mealRoutes);

// ====== Mặc định root (Để kiểm tra Server sống hay chết) ======
app.get("/", (req, res) => {
  res.send("🔥 Calorie Prediction API đang chạy ngon lành!");
});

// ====== Server khởi chạy ======
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});