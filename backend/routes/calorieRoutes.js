import express from "express";
import { spawn } from "child_process";
import jwt from "jsonwebtoken";
import CalorieRecord from "../models/CalorieRecord.js";

const router = express.Router();

// Middleware: Xác thực JWT token
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ success: false, message: 'Không có token' });
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key_123');
    req.userId = decoded.user?.id || decoded.id;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token không hợp lệ' });
  }
};

// ===========================
// 🔹 API: DỰ ĐOÁN CALO
// ===========================
router.post("/predict", verifyToken, async (req, res) => {
  try {
    const { activityType, weight, height, age, duration, heartRate } = req.body;

    if (!activityType || !weight || !height || !age || !duration || !heartRate) {
      return res.status(400).json({
        success: false,
        message: "Thiếu dữ liệu đầu vào!",
      });
    }

    console.log("📥 Nhận dữ liệu dự đoán:", req.body);

    const py = spawn("python", [
      "./ml/predict.py",
      weight.toString(),
      height.toString(),
      age.toString(),
      duration.toString(),
      heartRate.toString(),
      activityType.toString(),
    ]);

    let result = "";

    py.stdout.on("data", (data) => {
      result += data.toString();
    });

    py.stderr.on("data", (data) => {
      console.error("⚠️ Python stderr:", data.toString());
    });

    py.on("close", async () => {
      try {
        console.log("📤 Raw Python output:", result);
        const output = JSON.parse(result);

        if (output.success) {
          const calories = parseFloat(output.calories);

          // ✅ Lưu MongoDB với userId
          const record = new CalorieRecord({
            userId: req.userId,
            activityType,
            weight,
            height,
            age,
            duration,
            heartRate,
            calories,
            date: new Date().toISOString(),
          });

          await record.save();
          console.log("✅ Dự đoán thành công, lưu MongoDB:", calories, "kcal");

          return res.json({
            success: true,
            message: "Dự đoán thành công!",
            calories,
          });
        } else {
          console.error("❌ Python báo lỗi:", output.message);
          return res.status(400).json({
            success: false,
            message: output.message || "Không thể dự đoán calo.",
          });
        }
      } catch (err) {
        console.error("❌ Parse lỗi:", err);
        return res.status(500).json({
          success: false,
          message: "Lỗi xử lý dữ liệu đầu ra từ Python.",
        });
      }
    });
  } catch (err) {
    console.error("❌ Lỗi /predict:", err);
    return res.status(500).json({
      success: false,
      message: "Lỗi server khi dự đoán.",
    });
  }
});

// ===========================
// 🔹 API: LỊCH SỬ TẬP LUYỆN
// ===========================
router.get("/history", verifyToken, async (req, res) => {
  try {
    const history = await CalorieRecord.find({ userId: req.userId }).sort({ date: -1 });
    res.json({ success: true, data: history });
  } catch (err) {
    console.error("❌ Lỗi /history:", err);
    res.status(500).json({ success: false, message: "Lỗi khi lấy lịch sử." });
  }
});

export default router;
