import path from "path";
import { exec } from "child_process";
import { fileURLToPath } from "url";
import CalorieRecord from "../models/CalorieRecord.js";

// === Cấu hình đường dẫn tuyệt đối ===
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// === API DỰ ĐOÁN LƯỢNG CALO TIÊU HAO ===
export const predictCalories = async (req, res) => {
  try {
    const { age, weight, height, duration, heart_rate } = req.body;

    if (!age || !weight || !height || !duration || !heart_rate) {
      return res.status(400).json({
        success: false,
        message: "Thiếu dữ liệu đầu vào.",
      });
    }

    // Đường dẫn tuyệt đối đến file Python
    const scriptPath = path.resolve(__dirname, "../ml/predict.py");

    // Tạo lệnh chạy Python
    const command = `python "${scriptPath}" ${age} ${weight} ${height} ${duration} ${heart_rate}`;
    console.log("🚀 Chạy Python:", command);

    // Gọi file predict.py
    exec(command, async (error, stdout, stderr) => {
      if (error) {
        console.error("❌ Lỗi khi chạy Python:", error.message);
        return res.status(500).json({
          success: false,
          message: "Lỗi khi chạy Python script",
        });
      }
      if (stderr) console.warn("⚠️ Python stderr:", stderr);

      // Kết quả từ Python
      const calories = parseFloat(stdout.trim());
      console.log("✅ Kết quả Python:", calories);

      if (isNaN(calories)) {
        return res.status(500).json({
          success: false,
          message: "Không đọc được kết quả từ mô hình Python.",
        });
      }

      // Lưu vào MongoDB
      const record = new CalorieRecord({
        age,
        weight,
        height,
        duration,
        heart_rate,
        predictedCalories: calories,
      });
      await record.save();

      return res.json({
        success: true,
        calories,
        message: "Dự đoán thành công và đã lưu dữ liệu.",
      });
    });
  } catch (err) {
    console.error("🔥 Lỗi server:", err);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// === API LẤY TOÀN BỘ LỊCH SỬ ===
export const getAllRecords = async (req, res) => {
  try {
    const records = await CalorieRecord.find().sort({ createdAt: -1 });
    res.json({ success: true, data: records });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
