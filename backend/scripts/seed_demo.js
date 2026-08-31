// Seed một TÀI KHOẢN DEMO có sẵn dữ liệu phong phú để trình diễn (demo cho giảng viên).
// Mô phỏng một người dùng thật sự dùng app mỗi ngày từ đầu tháng 7 tới hiện tại
// (ăn uống, tập luyện, uống nước, cân nặng giảm dần theo mục tiêu "lose").
// Chạy:  cd backend && node scripts/seed_demo.js
//
// Tài khoản demo:  email = demo@healthai.app   |   mật khẩu = demo1234
//
// Logic seed nằm ở utils/demoSeeder.js, dùng chung với route
// POST /api/admin/seed-demo (cho phép trigger từ xa, không cần máy có Node).
import dotenv from "dotenv";
dotenv.config();
import mongoose from "mongoose";
import { seedDemoUser } from "../utils/demoSeeder.js";

async function run() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Đã kết nối MongoDB");

    const summary = await seedDemoUser();

    console.log(`📅 Mô phỏng ${summary.numDays} ngày dữ liệu (${summary.rangeStart} → ${summary.rangeEnd})`);
    console.log(`✅ ${summary.weightMetrics} mốc cân nặng`);
    console.log(`✅ ${summary.meals} bữa ăn`);
    console.log(`✅ ${summary.workouts} buổi tập`);
    console.log(`✅ ${summary.waterLogs} lượt uống nước`);
    console.log(`✅ ${summary.chatSessions} phiên chat mẫu`);

    console.log("\n========================================");
    console.log("🎉 SEED HOÀN TẤT — Tài khoản demo:");
    console.log(`   Email:    ${summary.email}`);
    console.log(`   Mật khẩu: ${summary.password}`);
    console.log(`   Dữ liệu:  ${summary.rangeStart} → ${summary.rangeEnd} (${summary.numDays} ngày)`);
    console.log("========================================\n");

    await mongoose.disconnect();
    process.exit(0);
}

run().catch((err) => {
    console.error("❌ Lỗi seed:", err);
    process.exit(1);
});
