import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../models/User.js";

// 🔹 Đăng ký tài khoản
export const register = async (req, res) => {
  try {
    const { name, email, password, birth, gender } = req.body;

    // Kiểm tra email tồn tại
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ success: false, message: "Email đã tồn tại" });
    }

    // Mã hóa mật khẩu
    const hashed = await bcrypt.hash(password, 10);

    const newUser = new User({
      name,
      email,
      password: hashed,
      birth,
      gender,
    });

    await newUser.save();
    res.status(201).json({ success: true, message: "Đăng ký thành công" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 🔹 Đăng nhập
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user)
      return res.status(404).json({ success: false, message: "Không tìm thấy người dùng" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(400).json({ success: false, message: "Mật khẩu sai" });

    // Tạo token JWT
    const token = jwt.sign({ id: user._id }, "SECRET_KEY", { expiresIn: "7d" });

    res.json({
      success: true,
      message: "Đăng nhập thành công",
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        gender: user.gender,
        birth: user.birth,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
