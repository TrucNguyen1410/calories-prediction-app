// Seed một TÀI KHOẢN DEMO có sẵn dữ liệu phong phú để trình diễn (demo cho giảng viên).
// Chạy:  cd backend && node scripts/seed_demo.js
//
// Tài khoản demo:  email = demo@healthai.app   |   mật khẩu = demo1234
import dotenv from "dotenv";
dotenv.config();
import mongoose from "mongoose";

import User from "../models/User.js";
import Meal from "../models/Meal.js";
import CalorieRecord from "../models/CalorieRecord.js";
import HealthMetric from "../models/HealthMetric.js";
import WaterLog from "../models/WaterLog.js";
import ChatSession from "../models/ChatSession.js";
import { computeBMI } from "../utils/health.js";

const DEMO_EMAIL = "demo@healthai.app";
const DEMO_PASSWORD = "demo1234";

const pad = (n) => String(n).padStart(2, "0");
const dateStr = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const daysAgo = (n) => {
    const d = new Date();
    d.setDate(d.getDate() - n);
    return d;
};

async function run() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Đã kết nối MongoDB");

    // 1) Tạo / cập nhật user demo
    let user = await User.findOne({ email: DEMO_EMAIL });
    if (!user) user = new User({ email: DEMO_EMAIL });
    user.name = "Nguyễn Văn Demo";
    user.password = DEMO_PASSWORD; // sẽ được hash bởi pre('save')
    user.gender = "Nam";
    user.height = 172;
    user.weight = 68;
    user.dob = new Date("1999-05-20");
    user.goal = "lose";
    user.activityLevel = "moderate";
    user.onboarded = true;
    await user.save();
    const userId = user._id;
    console.log("✅ User demo:", DEMO_EMAIL);

    // 2) Xóa dữ liệu cũ của user demo (để chạy lại nhiều lần vẫn sạch)
    await Promise.all([
        Meal.deleteMany({ userId }),
        CalorieRecord.deleteMany({ userId }),
        HealthMetric.deleteMany({ userId }),
        WaterLog.deleteMany({ userId }),
        ChatSession.deleteMany({ userId }),
    ]);

    // 3) Lịch sử cân nặng: xu hướng giảm 72 -> 68 trong ~8 tuần
    const weights = [72.0, 71.4, 70.8, 70.1, 69.6, 69.0, 68.5, 68.0];
    const metrics = weights.map((w, i) => ({
        userId,
        weight: w,
        height: 172,
        bmi: computeBMI(w, 172),
        source: i === weights.length - 1 ? "manual" : "profile",
        date: daysAgo((weights.length - 1 - i) * 7),
    }));
    await HealthMetric.insertMany(metrics);
    console.log(`✅ ${metrics.length} mốc cân nặng`);

    // 4) Bữa ăn 7 ngày gần nhất
    const breakfast = [
        ["Phở bò", 450, "1 tô (400g)"], ["Bánh mì trứng ốp la", 350, "1 ổ"],
        ["Bún riêu cua", 420, "1 tô"], ["Xôi gà", 480, "1 gói"],
        ["Cháo yến mạch + chuối", 300, "1 tô"], ["Bánh cuốn", 380, "1 đĩa"], ["Hủ tiếu", 430, "1 tô"],
    ];
    const lunch = [
        ["Cơm gà xối mỡ", 620, "1 phần"], ["Cơm tấm sườn", 680, "1 đĩa"],
        ["Bún chả", 550, "1 phần"], ["Cơm rang dưa bò", 600, "1 đĩa"],
        ["Salad ức gà", 380, "1 tô lớn"], ["Cơm cá kho + rau", 520, "1 phần"], ["Mì Ý sốt bò bằm", 590, "1 đĩa"],
    ];
    const dinner = [
        ["Ức gà áp chảo + salad", 400, "1 phần"], ["Cơm + canh cải + đậu hũ", 480, "1 phần"],
        ["Cá hồi nướng + rau củ", 450, "1 phần"], ["Cháo tôm", 350, "1 tô"],
        ["Bún trộn rau + thịt nạc", 430, "1 tô"], ["Cơm gạo lứt + trứng", 460, "1 phần"], ["Súp gà rau củ", 320, "1 tô"],
    ];
    const snacks = [
        ["Sữa chua không đường", 100, "1 hũ"], ["Chuối", 90, "1 quả"],
        ["Hạt điều", 160, "30g"], ["Táo", 80, "1 quả"], ["Sữa hạt", 130, "1 ly"],
    ];

    const meals = [];
    for (let i = 6; i >= 0; i--) {
        const d = dateStr(daysAgo(i));
        const ts = daysAgo(i).toISOString();
        const push = (arr, type, hourOffset) => {
            const item = arr[(6 - i) % arr.length];
            meals.push({
                userId, name: item[0], calories: item[1], servingSize: item[2],
                mealType: type, imageUrl: "", date: d, timestamp: ts,
            });
        };
        push(breakfast, "Sáng");
        push(lunch, "Trưa");
        push(dinner, "Tối");
        push(snacks, "Snack");
    }
    await Meal.insertMany(meals);
    console.log(`✅ ${meals.length} bữa ăn (7 ngày)`);

    // 5) Buổi tập (calorie records) rải rác 7 ngày
    const workouts = [
        [0, "Chạy bộ", 30, 310], [1, "Gym", 45, 360], [2, "Đạp xe", 40, 300],
        [3, "Yoga", 30, 120], [5, "Chạy bộ", 25, 260], [6, "Đi bộ nhanh", 50, 200],
    ];
    const records = workouts.map(([ago, type, dur, cal]) => ({
        userId, activityType: type, weight: 68, height: 172, age: 26,
        duration: dur, heartRate: 130, calories: cal, date: daysAgo(ago).toISOString(),
    }));
    await CalorieRecord.insertMany(records);
    console.log(`✅ ${records.length} buổi tập`);

    // 6) Nước uống hôm nay
    const today = dateStr(new Date());
    await WaterLog.insertMany([
        { userId, amountMl: 500, date: today },
        { userId, amountMl: 500, date: today },
        { userId, amountMl: 250, date: today },
    ]);
    console.log("✅ Nước uống hôm nay: 1250ml");

    // 7) Một phiên chat mẫu với trợ lý AI
    await ChatSession.create({
        userId,
        sessionTitle: "Làm sao để giảm cân hiệu quả?",
        messages: [
            { id: "1", role: "user", content: "Làm sao để giảm cân hiệu quả?", timestamp: daysAgo(1) },
            {
                id: "2", role: "model",
                content:
                    "Để giảm cân hiệu quả, bạn nên duy trì thâm hụt calo khoảng 500 kcal/ngày, ưu tiên protein nạc, rau xanh, hạn chế đồ ngọt và tập luyện đều đặn 3-5 buổi/tuần. Hãy uống đủ nước và ngủ đủ giấc nhé!",
                timestamp: daysAgo(1),
            },
        ],
    });
    console.log("✅ 1 phiên chat mẫu");

    console.log("\n========================================");
    console.log("🎉 SEED HOÀN TẤT — Tài khoản demo:");
    console.log(`   Email:    ${DEMO_EMAIL}`);
    console.log(`   Mật khẩu: ${DEMO_PASSWORD}`);
    console.log("========================================\n");

    await mongoose.disconnect();
    process.exit(0);
}

run().catch((err) => {
    console.error("❌ Lỗi seed:", err);
    process.exit(1);
});
