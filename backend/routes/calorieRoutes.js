import express from "express";
import { spawn } from "child_process";
import CalorieRecord from "../models/CalorieRecord.js";
import { verifyToken } from "../middleware/authMiddleware.js";
import { validatePredictInput } from "../middleware/validate.js";

const router = express.Router();

// ===========================
// 🔹 API: DỰ ĐOÁN CALO
// ===========================
router.post("/predict", verifyToken, validatePredictInput, async (req, res) => {
  try {
    const { activityType, weight, height, age, duration, heartRate } = req.body;

    if (!activityType) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng chọn loại bài tập!",
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

// ===========================
// 🔹 API: LƯU TRỰC TIẾP HOẠT ĐỘNG (Từ Chatbot AI)
// ===========================
router.post("/add", verifyToken, async (req, res) => {
  try {
    const { activityName, duration, caloriesBurned } = req.body;

    if (!activityName || !duration || !caloriesBurned) {
      return res.status(400).json({
        success: false,
        message: "Thiếu thông tin hoạt động!",
      });
    }

    const record = new CalorieRecord({
      userId: req.userId,
      activityType: activityName,
      duration: duration,
      calories: caloriesBurned,
      date: new Date().toISOString(),
    });

    await record.save();
    console.log(`✅ Đã lưu hoạt động ${activityName} (${caloriesBurned} kcal) vào DB!`);

    res.json({
      success: true,
      message: "Lưu hoạt động thành công!",
      data: record
    });
  } catch (err) {
    console.error("❌ Lỗi /add:", err);
    res.status(500).json({ success: false, message: "Lỗi server khi lưu hoạt động." });
  }
});

export default router;
