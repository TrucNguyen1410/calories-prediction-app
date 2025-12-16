import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';

const router = express.Router();

// API: Đăng ký
router.post('/register', async (req, res) => {
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
router.post('/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'Email hoặc mật khẩu không chính xác' });
        }
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Email hoặc mật khẩu không chính xác' });
        }

        // Tạo payload cho token
        const payload = {
            user: { id: user.id }
        };
        
        // Tạo user object để trả về (đầy đủ thông tin)
        const userResponse = {
            id: user.id,
            name: user.name,
            email: user.email,
            gender: user.gender,
            height: user.height,
            weight: user.weight
        };

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
    const { height, weight, gender } = req.body;
    
    try {
        let user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'Không tìm thấy người dùng' });
        }
        
        // Cập nhật thông tin
        user.height = height ?? user.height;
        user.weight = weight ?? user.weight;
        user.gender = gender ?? user.gender;
        
        await user.save();
        
        // Trả về thông tin user đã cập nhật
        res.json({
            id: user.id,
            name: user.name,
            email: user.email,
            gender: user.gender,
            height: user.height,
            weight: user.weight
        });
        
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

export default router;