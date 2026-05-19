import express from "express";
import jwt from "jsonwebtoken";
import Feedback from "../models/Feedback.js";
import User from "../models/User.js";

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

// API: Gửi đóng góp ý kiến
router.post("/submit", verifyToken, async (req, res) => {
  try {
    const { content } = req.body;
    if (!content || content.trim() === '') {
      return res.status(400).json({
        success: false,
        message: "Nội dung phản hồi không được để trống!"
      });
    }

    // 1. Lưu vào Database MongoDB
    const feedback = new Feedback({
      userId: req.userId,
      content: content.trim()
    });
    await feedback.save();

    // Lấy thông tin user gửi phản hồi
    const user = await User.findById(req.userId);
    const emailSender = user ? user.email : "Không rõ email";
    const nameSender = user ? user.name : "Người dùng ẩn danh";

    // 2. Gửi email qua Resend HTTP API (Cổng 443 - Không bị Render chặn)
    const resendApiKey = process.env.RESEND_API_KEY;

    if (resendApiKey) {
      const timeString = new Date().toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" });

      const emailBody = {
        from: 'HealthAI <onboarding@resend.dev>',
        to: 'truc141004@gmail.com',
        subject: `[HealthAI] Đóng góp ý kiến mới từ người dùng: ${nameSender}`,
        html: `
          <div style="font-family: Arial, sans-serif; line-height: 1.6; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px; background-color: #ffffff; color: #333333;">
            <div style="text-align: center; border-bottom: 2px solid #8A2BE2; padding-bottom: 15px;">
              <h2 style="color: #8A2BE2; margin: 0;">📩 Ý kiến đóng góp mới</h2>
              <p style="color: #666666; font-size: 14px; margin: 5px 0 0 0;">Hệ thống HealthAI đã nhận phản hồi mới từ người dùng</p>
            </div>
            
            <div style="margin-top: 20px;">
              <table style="width: 100%; border-collapse: collapse;">
                <tr style="background-color: #f9f9f9;">
                  <td style="padding: 10px; font-weight: bold; width: 35%; border-bottom: 1px solid #eee;">Người gửi:</td>
                  <td style="padding: 10px; border-bottom: 1px solid #eee;">${nameSender}</td>
                </tr>
                <tr>
                  <td style="padding: 10px; font-weight: bold; border-bottom: 1px solid #eee;">Email tài khoản:</td>
                  <td style="padding: 10px; border-bottom: 1px solid #eee;">${emailSender}</td>
                </tr>
                <tr style="background-color: #f9f9f9;">
                  <td style="padding: 10px; font-weight: bold; border-bottom: 1px solid #eee;">ID Người dùng:</td>
                  <td style="padding: 10px; border-bottom: 1px solid #eee;">${req.userId}</td>
                </tr>
                <tr>
                  <td style="padding: 10px; font-weight: bold; border-bottom: 1px solid #eee;">Thời gian gửi:</td>
                  <td style="padding: 10px; border-bottom: 1px solid #eee;">${timeString} (Giờ Việt Nam)</td>
                </tr>
              </table>
            </div>

            <div style="margin-top: 25px; padding: 20px; background-color: #f6f0ff; border-left: 5px solid #8A2BE2; border-radius: 4px;">
              <h4 style="margin: 0 0 10px 0; color: #4B0082; font-size: 15px;">📝 Nội dung góp ý:</h4>
              <p style="margin: 0; white-space: pre-wrap; font-size: 14px; color: #333333;">${content}</p>
            </div>

            <div style="margin-top: 30px; font-size: 11px; color: #888888; text-align: center; border-top: 1px solid #eeeeee; padding-top: 15px;">
              Đây là thư được gửi tự động từ máy chủ hệ thống HealthAI qua Resend API.
            </div>
          </div>
        `
      };

      // Gửi request HTTP POST không đồng bộ tới Resend
      fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${resendApiKey}`
        },
        body: JSON.stringify(emailBody)
      })
      .then(res => res.json())
      .then(data => {
        console.log("✅ Đã gửi email phản hồi qua Resend API thành công:", data);
      })
      .catch(error => {
        console.error("❌ Lỗi gửi email qua Resend API:", error.message);
      });
    } else {
      console.warn("⚠️ Không cấu hình RESEND_API_KEY trong .env nên không gửi email.");
    }

    return res.status(200).json({
      success: true,
      message: "Đóng góp ý kiến của bạn đã được gửi thành công!"
    });

  } catch (err) {
    console.error("❌ Lỗi API /feedback/submit:", err);
    return res.status(500).json({
      success: false,
      message: "Có lỗi xảy ra tại máy chủ khi gửi đóng góp ý kiến."
    });
  }
});

export default router;
