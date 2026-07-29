import jwt from "jsonwebtoken";
import User from "../models/User.js";

// Middleware xác thực JWT dùng chung cho toàn hệ thống.
// Gắn req.userId để controller lấy đúng người dùng thay vì tin vào body do client gửi.
export const verifyToken = (req, res, next) => {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
        return res.status(401).json({ success: false, message: "Không có token xác thực" });
    }
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || "your_secret_key_123");
        req.userId = decoded.user?.id || decoded.id;
        next();
    } catch (err) {
        return res.status(401).json({ success: false, message: "Token không hợp lệ hoặc đã hết hạn" });
    }
};

// Chỉ cho phép tài khoản quản trị (role='admin') đi tiếp. Dùng SAU verifyToken.
export const isAdmin = async (req, res, next) => {
    try {
        const user = await User.findById(req.userId).select("role");
        if (!user || user.role !== "admin") {
            return res.status(403).json({ success: false, message: "Chỉ quản trị viên mới có quyền truy cập" });
        }
        next();
    } catch (err) {
        return res.status(500).json({ success: false, message: "Lỗi kiểm tra quyền" });
    }
};

export default verifyToken;
