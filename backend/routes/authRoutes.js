import express from 'express';
import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import HealthMetric from '../models/HealthMetric.js';
import Meal from '../models/Meal.js';
import CalorieRecord from '../models/CalorieRecord.js';
import ChatSession from '../models/ChatSession.js';
import Feedback from '../models/Feedback.js';
import WaterLog from '../models/WaterLog.js';
import { computeBMI } from '../utils/health.js';
import { validateRegister, validateLogin } from '../middleware/validate.js';
import { rateLimit } from '../middleware/rateLimit.js';
import { verifyToken } from '../middleware/authMiddleware.js';
import { syncGoogleFit } from '../controllers/googleFitController.js';


const router = express.Router();

// Chuẩn hóa object user trả về cho client (đầy đủ các trường hồ sơ)
function buildUserResponse(user) {
    return {
        id: user.id,
        name: user.name,
        email: user.email,
        gender: user.gender,
        height: user.height,
        weight: user.weight,
        dob: user.dob,
        goal: user.goal,
        activityLevel: user.activityLevel,
        onboarded: user.onboarded,
    };
}

// Chống dò mật khẩu / spam đăng ký: tối đa 20 lần / phút / IP
const authLimiter = rateLimit({ windowMs: 60_000, max: 20, message: 'Quá nhiều lần thử. Vui lòng đợi 1 phút.' });

// Giới hạn chặt hơn cho quên mật khẩu: 5 lần / 10 phút
const otpLimiter = rateLimit({ windowMs: 10 * 60_000, max: 5, message: 'Bạn đã yêu cầu quá nhiều lần. Vui lòng thử lại sau.' });

// Gửi email OTP qua Resend HTTP API (dùng chung cơ chế như feedback)
async function sendOTPEmail(toEmail, name, otp) {
    const resendApiKey = process.env.RESEND_API_KEY;
    if (!resendApiKey) {
        console.warn('⚠️ Thiếu RESEND_API_KEY — không gửi được email OTP.');
        return;
    }
    const emailBody = {
        from: 'HealthAI <onboarding@resend.dev>',
        to: toEmail,
        subject: '[HealthAI] Mã đặt lại mật khẩu (OTP)',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 520px; margin: auto; padding: 24px; border: 1px solid #eee; border-radius: 12px;">
            <h2 style="color:#8A2BE2; text-align:center;">Đặt lại mật khẩu HealthAI</h2>
            <p>Xin chào <b>${name || 'bạn'}</b>,</p>
            <p>Mã xác thực (OTP) để đặt lại mật khẩu của bạn là:</p>
            <div style="text-align:center; margin:20px 0;">
              <span style="font-size:32px; letter-spacing:8px; font-weight:bold; color:#4B0082;">${otp}</span>
            </div>
            <p style="color:#666; font-size:13px;">Mã có hiệu lực trong <b>10 phút</b>. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p>
          </div>`,
    };
    try {
        const r = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${resendApiKey}` },
            body: JSON.stringify(emailBody),
        });
        const data = await r.json();
        console.log('✅ Đã gửi OTP qua Resend:', data?.id || data);
    } catch (e) {
        console.error('❌ Lỗi gửi OTP:', e.message);
    }
}

// API: Đăng ký
router.post('/register', authLimiter, validateRegister, async (req, res) => {
    // (Code đăng ký của bạn. Hãy đảm bảo nó khớp)
    const { name, email, password, gender, birthdate } = req.body; 
    try {
        let user = await User.findOne({ email });
        if (user) {
            return res.status(400).json({ message: 'Email đã được sử dụng' });
        }
        // Parse birthdate (accept formats like 'dd/mm/yyyy' or 'yyyy-mm-dd')
        let dobValue = undefined;
        if (birthdate) {
            try {
                if (typeof birthdate === 'string') {
                    // try dd/mm/yyyy
                    const parts = birthdate.split(/[\/-]/).map(p => p.trim());
                    if (parts.length === 3) {
                        // detect if first part is day or year
                        if (parts[0].length === 4) {
                            // yyyy-mm-dd
                            dobValue = new Date(parts[0] + '-' + parts[1].padStart(2,'0') + '-' + parts[2].padStart(2,'0'));
                        } else {
                            // dd/mm/yyyy -> convert to yyyy-mm-dd
                            const d = parts[0].padStart(2,'0');
                            const m = parts[1].padStart(2,'0');
                            const y = parts[2];
                            dobValue = new Date(`${y}-${m}-${d}`);
                        }
                    } else {
                        dobValue = new Date(birthdate);
                    }
                    if (isNaN(dobValue.getTime())) {
                        dobValue = undefined;
                    }
                } else if (birthdate instanceof Date) {
                    dobValue = birthdate;
                }
            } catch (err) {
                dobValue = undefined;
            }
        }

        // Password will be automatically hashed by UserSchema.pre('save') middleware
        const userData = { name, email, password, gender };
        if (dobValue) userData.dob = dobValue;
        user = new User(userData);
        await user.save();
        res.status(201).json({ message: 'Đăng ký tài khoản thành công' });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ message: 'Lỗi máy chủ' });
    }
});

// API: Đăng nhập (Cập nhật để trả về thêm dữ liệu)
router.post('/login', authLimiter, validateLogin, async (req, res) => {
    const { email, password } = req.body;
    try {
        let user = await User.findOne({ email });
        
        // --- GOOGLE AUTH AUTO-SIGNUP/LOGIN ---
        if (password === 'GOOGLE_AUTH_EXTERNAL') {
            if (!user) {
                // Auto-create user if not exists
                user = new User({
                    name: email.split('@')[0],
                    email: email,
                    password: await bcrypt.hash(Math.random().toString(36), 10), // Random password
                    gender: 'Khác'
                });
                await user.save();
            }
        } else {
            if (!user) {
                return res.status(400).json({ message: 'Email hoặc mật khẩu không chính xác' });
            }
            const isMatch = await bcrypt.compare(password, user.password);
            if (!isMatch) {
                return res.status(400).json({ message: 'Email hoặc mật khẩu không chính xác' });
            }
        }

        // Tạo payload cho token
        const payload = {
            user: { id: user.id }
        };
        
        // Tạo user object để trả về (đầy đủ thông tin)
        const userResponse = buildUserResponse(user);

        jwt.sign(
            payload,
                process.env.JWT_SECRET || 'your_secret_key_123',
            { expiresIn: '7d' }, 
            (err, token) => {
                if (err) throw err;
                res.json({
                    token: token,
                    user: userResponse // Trả về user object đầy đủ
                });
            }
        );
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ message: 'Lỗi máy chủ' });
    }
});

// --- API MỚI: CẬP NHẬT CHIỀU CAO/CÂN NẶNG ---
// PUT /api/auth/profile/:id (Giả sử bạn gắn route này trong server.js)
router.put('/profile/:id', async (req, res) => {
    const { name, height, weight, gender, age, goal, activityLevel, onboarded } = req.body;

    try {
        let user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'Không tìm thấy người dùng' });
        }

        const weightChanged =
            weight !== undefined && weight !== null && Number(weight) !== Number(user.weight);

        // Cập nhật thông tin
        if (name !== undefined && String(name).trim().length >= 2) user.name = String(name).trim();
        user.height = height ?? user.height;
        user.weight = weight ?? user.weight;
        user.gender = gender ?? user.gender;
        if (goal !== undefined && ['lose', 'maintain', 'gain'].includes(goal)) user.goal = goal;
        if (activityLevel !== undefined &&
            ['sedentary', 'light', 'moderate', 'active', 'very_active'].includes(activityLevel)) {
            user.activityLevel = activityLevel;
        }
        if (onboarded !== undefined) user.onboarded = !!onboarded;
        if (age !== undefined && age !== null) {
            const birthYear = new Date().getFullYear() - parseInt(age);
            user.dob = new Date(`${birthYear}-01-01`);
        }

        await user.save();

        // Nếu cân nặng thay đổi, ghi lại một mốc đo để dựng biểu đồ xu hướng thật
        if (weightChanged && user.weight > 0) {
            try {
                await HealthMetric.create({
                    userId: user._id,
                    weight: user.weight,
                    height: user.height || undefined,
                    bmi: computeBMI(user.weight, user.height) || undefined,
                    source: "profile",
                });
            } catch (metricErr) {
                console.error("Lỗi ghi HealthMetric từ profile:", metricErr.message);
            }
        }
        
        // Trả về thông tin user đã cập nhật
        res.json(buildUserResponse(user));

    } catch (err) {
        console.error(err.message);
        res.status(500).json({ message: 'Lỗi máy chủ' });
    }
});

// API: Đổi mật khẩu
// POST /api/auth/change-password
router.post('/change-password', async (req, res) => {
    const { userId, oldPassword, newPassword } = req.body;
    console.log('change-password request body:', req.body);
    if (!userId || !oldPassword || !newPassword) {
        return res.status(400).json({ success: false, message: 'Thiếu thông tin' });
    }

    try {
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });

        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) return res.status(400).json({ success: false, message: 'Mật khẩu hiện tại không đúng' });

        // Set new password - will be automatically hashed by UserSchema.pre('save') middleware
        user.password = newPassword;
        await user.save();

        console.log(`Password changed for user ${userId}`);
        return res.json({ success: true, message: 'Đổi mật khẩu thành công' });
    } catch (err) {
        console.error('Error in change-password:', err);
        return res.status(500).json({ success: false, message: 'Lỗi máy chủ' });
    }
});

// --- API MỚI: ĐỒNG BỘ GOOGLE FIT ---
router.post('/google-sync', syncGoogleFit);

// --- API: QUÊN MẬT KHẨU (gửi OTP qua email) ---
// POST /api/auth/forgot-password  { email }
router.post('/forgot-password', otpLimiter, async (req, res) => {
    const { email } = req.body;
    try {
        const user = await User.findOne({ email });
        // Luôn trả về thông báo giống nhau để tránh lộ email nào tồn tại
        if (user) {
            const otp = ('' + crypto.randomInt(0, 1000000)).padStart(6, '0');
            user.resetOTPHash = await bcrypt.hash(otp, 10);
            user.resetOTPExpires = new Date(Date.now() + 10 * 60_000); // 10 phút
            await user.save();
            await sendOTPEmail(user.email, user.name, otp);
        }
        return res.json({
            success: true,
            message: 'Nếu email tồn tại, mã OTP đã được gửi. Vui lòng kiểm tra hộp thư.',
        });
    } catch (err) {
        console.error('forgot-password error:', err);
        return res.status(500).json({ success: false, message: 'Lỗi máy chủ' });
    }
});

// --- API: ĐẶT LẠI MẬT KHẨU bằng OTP ---
// POST /api/auth/reset-password  { email, otp, newPassword }
router.post('/reset-password', otpLimiter, async (req, res) => {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) {
        return res.status(400).json({ success: false, message: 'Thiếu thông tin' });
    }
    if (String(newPassword).length < 6) {
        return res.status(400).json({ success: false, message: 'Mật khẩu mới phải có ít nhất 6 ký tự' });
    }
    try {
        const user = await User.findOne({ email });
        if (!user || !user.resetOTPHash || !user.resetOTPExpires) {
            return res.status(400).json({ success: false, message: 'Yêu cầu không hợp lệ hoặc đã hết hạn' });
        }
        if (user.resetOTPExpires.getTime() < Date.now()) {
            return res.status(400).json({ success: false, message: 'Mã OTP đã hết hạn. Vui lòng yêu cầu lại.' });
        }
        const match = await bcrypt.compare(String(otp), user.resetOTPHash);
        if (!match) {
            return res.status(400).json({ success: false, message: 'Mã OTP không chính xác' });
        }
        user.password = newPassword; // sẽ được hash tự động bởi pre('save')
        user.resetOTPHash = undefined;
        user.resetOTPExpires = undefined;
        await user.save();
        return res.json({ success: true, message: 'Đặt lại mật khẩu thành công. Vui lòng đăng nhập.' });
    } catch (err) {
        console.error('reset-password error:', err);
        return res.status(500).json({ success: false, message: 'Lỗi máy chủ' });
    }
});

// --- API: XÓA TÀI KHOẢN (và toàn bộ dữ liệu liên quan) ---
// DELETE /api/auth/account  (yêu cầu JWT)
router.delete('/account', verifyToken, async (req, res) => {
    try {
        const userId = req.userId;
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });

        await Promise.all([
            Meal.deleteMany({ userId }),
            CalorieRecord.deleteMany({ userId }),
            ChatSession.deleteMany({ userId }),
            HealthMetric.deleteMany({ userId }),
            Feedback.deleteMany({ userId }),
            WaterLog.deleteMany({ userId }),
        ]);
        await User.findByIdAndDelete(userId);

        console.log(`🗑️ Đã xóa tài khoản ${userId} và toàn bộ dữ liệu liên quan.`);
        return res.json({ success: true, message: 'Đã xóa tài khoản và toàn bộ dữ liệu của bạn.' });
    } catch (err) {
        console.error('delete account error:', err);
        return res.status(500).json({ success: false, message: 'Lỗi máy chủ khi xóa tài khoản' });
    }
});


export default router;