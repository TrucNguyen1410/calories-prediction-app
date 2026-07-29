import express from "express";
import User from "../models/User.js";
import Meal from "../models/Meal.js";
import CalorieRecord from "../models/CalorieRecord.js";
import ChatSession from "../models/ChatSession.js";
import HealthMetric from "../models/HealthMetric.js";
import WaterLog from "../models/WaterLog.js";
import Feedback from "../models/Feedback.js";
import { verifyToken, isAdmin } from "../middleware/authMiddleware.js";

const router = express.Router();

// Toàn bộ route admin yêu cầu đăng nhập + quyền admin
router.use(verifyToken, isAdmin);

// --- Thống kê tổng quan hệ thống ---
// GET /api/admin/stats
router.get("/stats", async (req, res) => {
    try {
        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);

        const [totalUsers, totalMeals, totalWorkouts, totalSessions, totalFeedback, newUsers, adminCount] =
            await Promise.all([
                User.countDocuments(),
                Meal.countDocuments(),
                CalorieRecord.countDocuments(),
                ChatSession.countDocuments(),
                Feedback.countDocuments(),
                User.countDocuments({ createdAt: { $gte: weekAgo } }),
                User.countDocuments({ role: "admin" }),
            ]);

        return res.status(200).json({
            success: true,
            data: { totalUsers, totalMeals, totalWorkouts, totalSessions, totalFeedback, newUsers, adminCount },
        });
    } catch (err) {
        console.error("ADMIN STATS ERROR:", err);
        return res.status(500).json({ success: false, message: "Lỗi lấy thống kê" });
    }
});

// --- Danh sách người dùng ---
// GET /api/admin/users?limit=100
router.get("/users", async (req, res) => {
    try {
        const limit = Math.min(parseInt(req.query.limit) || 200, 500);
        const users = await User.find()
            .select("name email gender height weight role onboarded createdAt")
            .sort({ createdAt: -1 })
            .limit(limit);
        return res.status(200).json({ success: true, data: users });
    } catch (err) {
        console.error("ADMIN USERS ERROR:", err);
        return res.status(500).json({ success: false, message: "Lỗi lấy danh sách người dùng" });
    }
});

// --- Danh sách phản hồi (kèm tên/email người gửi) ---
// GET /api/admin/feedback
router.get("/feedback", async (req, res) => {
    try {
        const feedbacks = await Feedback.find()
            .sort({ createdAt: -1 })
            .limit(200)
            .populate("userId", "name email");
        const data = feedbacks.map((f) => ({
            _id: f._id,
            content: f.content,
            createdAt: f.createdAt,
            userName: f.userId?.name || "Ẩn danh",
            userEmail: f.userId?.email || "",
        }));
        return res.status(200).json({ success: true, data });
    } catch (err) {
        console.error("ADMIN FEEDBACK ERROR:", err);
        return res.status(500).json({ success: false, message: "Lỗi lấy phản hồi" });
    }
});

// --- Xóa người dùng (và dữ liệu liên quan) ---
// DELETE /api/admin/users/:id
router.delete("/users/:id", async (req, res) => {
    try {
        const targetId = req.params.id;
        if (targetId === req.userId) {
            return res.status(400).json({ success: false, message: "Không thể tự xóa tài khoản admin đang đăng nhập" });
        }
        const target = await User.findById(targetId);
        if (!target) return res.status(404).json({ success: false, message: "Không tìm thấy người dùng" });
        if (target.role === "admin") {
            return res.status(403).json({ success: false, message: "Không thể xóa tài khoản admin khác" });
        }

        await Promise.all([
            Meal.deleteMany({ userId: targetId }),
            CalorieRecord.deleteMany({ userId: targetId }),
            ChatSession.deleteMany({ userId: targetId }),
            HealthMetric.deleteMany({ userId: targetId }),
            WaterLog.deleteMany({ userId: targetId }),
            Feedback.deleteMany({ userId: targetId }),
        ]);
        await User.findByIdAndDelete(targetId);

        return res.status(200).json({ success: true, message: "Đã xóa người dùng và toàn bộ dữ liệu liên quan" });
    } catch (err) {
        console.error("ADMIN DELETE USER ERROR:", err);
        return res.status(500).json({ success: false, message: "Lỗi xóa người dùng" });
    }
});

export default router;
