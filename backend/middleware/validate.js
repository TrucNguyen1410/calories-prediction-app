// Các middleware kiểm tra & làm sạch dữ liệu đầu vào (input validation).
// Trả về 400 kèm thông báo tiếng Việt rõ ràng khi dữ liệu không hợp lệ.

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateRegister(req, res, next) {
    const { name, email, password } = req.body;
    const errors = [];

    if (!name || String(name).trim().length < 2) {
        errors.push("Họ tên phải có ít nhất 2 ký tự.");
    }
    if (!email || !EMAIL_REGEX.test(String(email).trim())) {
        errors.push("Email không đúng định dạng.");
    }
    if (!password || String(password).length < 6) {
        errors.push("Mật khẩu phải có ít nhất 6 ký tự.");
    }

    if (errors.length > 0) {
        return res.status(400).json({ message: errors.join(" ") });
    }
    next();
}

export function validateLogin(req, res, next) {
    const { email, password } = req.body;
    if (!email || !password) {
        return res.status(400).json({ message: "Vui lòng nhập đầy đủ email và mật khẩu." });
    }
    // Bỏ qua kiểm tra định dạng cho luồng đăng nhập Google nội bộ
    if (password !== "GOOGLE_AUTH_EXTERNAL" && !EMAIL_REGEX.test(String(email).trim())) {
        return res.status(400).json({ message: "Email không đúng định dạng." });
    }
    next();
}

// Kiểm tra dữ liệu dự đoán calo nằm trong khoảng hợp lý
export function validatePredictInput(req, res, next) {
    const { weight, height, age, duration, heartRate } = req.body;
    const num = (v) => (v === undefined || v === null ? NaN : Number(v));

    const bounds = [
        ["weight", num(weight), 20, 400, "Cân nặng"],
        ["height", num(height), 50, 260, "Chiều cao"],
        ["age", num(age), 5, 120, "Tuổi"],
        ["duration", num(duration), 1, 600, "Thời gian tập"],
        ["heartRate", num(heartRate), 30, 240, "Nhịp tim"],
    ];

    for (const [, value, min, max, label] of bounds) {
        if (Number.isNaN(value)) {
            return res.status(400).json({ success: false, message: `${label} không hợp lệ.` });
        }
        if (value < min || value > max) {
            return res.status(400).json({
                success: false,
                message: `${label} phải nằm trong khoảng ${min} - ${max}.`,
            });
        }
    }
    next();
}

export default { validateRegister, validateLogin, validatePredictInput };
