// Tạo / cập nhật TÀI KHOẢN ADMIN để demo trang quản trị.
// Chạy:  cd backend && node scripts/seed_admin.js
//
// Tài khoản admin:  email = admin@healthai.app  |  mật khẩu = admin1234
import dotenv from "dotenv";
dotenv.config();
import mongoose from "mongoose";
import User from "../models/User.js";

const ADMIN_EMAIL = "admin@healthai.app";
const ADMIN_PASSWORD = "admin1234";

async function run() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Đã kết nối MongoDB");

    let user = await User.findOne({ email: ADMIN_EMAIL });
    if (!user) user = new User({ email: ADMIN_EMAIL });
    user.name = "Quản trị viên";
    user.password = ADMIN_PASSWORD; // sẽ được hash bởi pre('save')
    user.gender = "Khác";
    user.role = "admin";
    user.onboarded = true;
    user.height = 170;
    user.weight = 65;
    await user.save();

    console.log("\n========================================");
    console.log("🎉 Tài khoản ADMIN đã sẵn sàng:");
    console.log(`   Email:    ${ADMIN_EMAIL}`);
    console.log(`   Mật khẩu: ${ADMIN_PASSWORD}`);
    console.log(`   Role:     ${user.role}`);
    console.log("========================================\n");

    await mongoose.disconnect();
    process.exit(0);
}

run().catch((err) => {
    console.error("❌ Lỗi seed admin:", err);
    process.exit(1);
});
