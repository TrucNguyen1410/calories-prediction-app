import express from "express";
import HealthMetric from "../models/HealthMetric.js";
import User from "../models/User.js";
import { verifyToken } from "../middleware/authMiddleware.js";
import { computeBMI, classifyBMIAsian } from "../utils/health.js";

const router = express.Router();

// Mọi route đều yêu cầu đăng nhập
router.use(verifyToken);

// --- Ghi nhận một lần đo cân nặng mới ---
// POST /api/records/weight  { weight, height?, note? }
router.post("/weight", async (req, res) => {
    try {
        const { weight, height, note } = req.body;
        const w = parseFloat(weight);

        if (Number.isNaN(w) || w < 20 || w > 400) {
            return res.status(400).json({
                success: false,
                message: "Cân nặng không hợp lệ (phải trong khoảng 20 - 400 kg).",
            });
        }

        // Lấy chiều cao: ưu tiên giá trị gửi lên, nếu không có thì lấy từ hồ sơ user
        const user = await User.findById(req.userId);
        let h = parseFloat(height);
        if (Number.isNaN(h) || h <= 0) {
            h = user?.height || 0;
        }
        if (h && (h < 50 || h > 260)) {
            return res.status(400).json({
                success: false,
                message: "Chiều cao không hợp lệ (phải trong khoảng 50 - 260 cm).",
            });
        }

        const bmi = computeBMI(w, h);

        const record = await HealthMetric.create({
            userId: req.userId,
            weight: w,
            height: h || undefined,
            bmi: bmi || undefined,
            note: note || "",
            source: "manual",
        });

        // Đồng bộ cân nặng mới nhất vào hồ sơ người dùng
        if (user) {
            user.weight = w;
            if (h) user.height = h;
            await user.save();
        }

        return res.status(201).json({
            success: true,
            message: "Đã lưu chỉ số cân nặng.",
            data: {
                ...record.toObject(),
                bmiStatus: bmi ? classifyBMIAsian(bmi) : "Không xác định",
            },
        });
    } catch (err) {
        console.error("ADD WEIGHT RECORD ERROR:", err);
        return res.status(500).json({ success: false, message: "Lỗi lưu chỉ số sức khỏe." });
    }
});

// --- Lấy lịch sử đo (mặc định 90 ngày gần nhất) ---
// GET /api/records/weight?limit=100
router.get("/weight", async (req, res) => {
    try {
        const limit = Math.min(parseInt(req.query.limit) || 100, 500);
        const records = await HealthMetric.find({ userId: req.userId })
            .sort({ date: -1 })
            .limit(limit);

        return res.status(200).json({
            success: true,
            data: records.map((r) => ({
                _id: r._id,
                weight: r.weight,
                height: r.height,
                bmi: r.bmi,
                bmiStatus: r.bmi ? classifyBMIAsian(r.bmi) : "Không xác định",
                note: r.note,
                date: r.date,
            })),
        });
    } catch (err) {
        console.error("GET WEIGHT RECORDS ERROR:", err);
        return res.status(500).json({ success: false, message: "Lỗi lấy lịch sử sức khỏe." });
    }
});

// --- Xóa một bản ghi ---
// DELETE /api/records/weight/:id
router.delete("/weight/:id", async (req, res) => {
    try {
        const record = await HealthMetric.findOneAndDelete({
            _id: req.params.id,
            userId: req.userId,
        });
        if (!record) {
            return res.status(404).json({ success: false, message: "Không tìm thấy bản ghi." });
        }
        return res.status(200).json({ success: true, message: "Đã xóa bản ghi." });
    } catch (err) {
        console.error("DELETE WEIGHT RECORD ERROR:", err);
        return res.status(500).json({ success: false, message: "Lỗi xóa bản ghi." });
    }
});

export default router;
