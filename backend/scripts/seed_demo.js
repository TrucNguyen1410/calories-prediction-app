// Seed một TÀI KHOẢN DEMO có sẵn dữ liệu phong phú để trình diễn (demo cho giảng viên).
// Mô phỏng một người dùng thật sự dùng app mỗi ngày từ đầu tháng 7 tới hiện tại
// (ăn uống, tập luyện, uống nước, cân nặng giảm dần theo mục tiêu "lose").
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

// Lịch sử bắt đầu từ 01/07 năm nay tới hôm nay (mô phỏng dùng app liên tục ~8 tuần)
const HISTORY_START = new Date(new Date().getFullYear(), 6, 1); // 01/07

const pad = (n) => String(n).padStart(2, "0");
const dateStr = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const addDays = (d, n) => {
    const copy = new Date(d);
    copy.setDate(copy.getDate() + n);
    return copy;
};
const daysAgo = (n) => addDays(new Date(), -n);
const rand = (min, max) => Math.random() * (max - min) + min;
const randInt = (min, max) => Math.round(rand(min, max));
const pick = (arr, i) => arr[i % arr.length];
const roll = (prob) => Math.random() < prob;

function totalDaysInHistory() {
    return Math.floor((new Date().setHours(0, 0, 0, 0) - HISTORY_START.setHours(0, 0, 0, 0)) / 86400000) + 1;
}

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

    const NUM_DAYS = totalDaysInHistory();
    console.log(`📅 Mô phỏng ${NUM_DAYS} ngày dữ liệu (${dateStr(HISTORY_START)} → ${dateStr(new Date())})`);

    // 3) Lịch sử cân nặng: xu hướng giảm dần từ ~74kg xuống ~68kg, đo mỗi 2 ngày, có nhiễu tự nhiên
    const START_WEIGHT = 74.2;
    const END_WEIGHT = 68.0;
    const metrics = [];
    for (let i = 0; i < NUM_DAYS; i += 2) {
        const progress = i / (NUM_DAYS - 1);
        const trend = START_WEIGHT - (START_WEIGHT - END_WEIGHT) * progress;
        const w = Math.round((trend + rand(-0.35, 0.35)) * 10) / 10;
        const d = addDays(HISTORY_START, i);
        metrics.push({
            userId,
            weight: w,
            height: 172,
            bmi: computeBMI(w, 172),
            source: "manual",
            date: d,
        });
    }
    // Đảm bảo mốc cuối cùng khớp cân nặng hiện tại của hồ sơ
    metrics.push({
        userId, weight: END_WEIGHT, height: 172, bmi: computeBMI(END_WEIGHT, 172),
        source: "manual", date: new Date(),
    });
    await HealthMetric.insertMany(metrics);
    console.log(`✅ ${metrics.length} mốc cân nặng`);

    // 4) Bữa ăn — thư viện món đa dạng để không lặp y hệt theo tuần
    const breakfast = [
        ["Phở bò", 450, "1 tô (400g)"], ["Bánh mì trứng ốp la", 350, "1 ổ"],
        ["Bún riêu cua", 420, "1 tô"], ["Xôi gà", 480, "1 gói"],
        ["Cháo yến mạch + chuối", 300, "1 tô"], ["Bánh cuốn", 380, "1 đĩa"],
        ["Hủ tiếu", 430, "1 tô"], ["Bánh mì ốp la thịt nguội", 400, "1 ổ"],
        ["Bún bò Huế", 470, "1 tô"], ["Sandwich trứng + sữa", 340, "1 phần"],
        ["Cơm tấm sườn nhỏ", 500, "1 đĩa nhỏ"], ["Yến mạch sữa hạt + hạt chia", 320, "1 tô"],
        ["Bánh giò", 310, "1 cái"], ["Trứng ốp la + bánh mì đen", 360, "1 phần"],
    ];
    const lunch = [
        ["Cơm gà xối mỡ", 620, "1 phần"], ["Cơm tấm sườn", 680, "1 đĩa"],
        ["Bún chả", 550, "1 phần"], ["Cơm rang dưa bò", 600, "1 đĩa"],
        ["Salad ức gà", 380, "1 tô lớn"], ["Cơm cá kho + rau", 520, "1 phần"],
        ["Mì Ý sốt bò bằm", 590, "1 đĩa"], ["Cơm gà nướng + rau", 560, "1 phần"],
        ["Bún thịt nướng", 540, "1 tô"], ["Cơm sườn nướng + canh", 610, "1 phần"],
        ["Ức gà sốt tiêu đen + cơm gạo lứt", 500, "1 phần"], ["Bánh canh cua", 470, "1 tô"],
        ["Cơm chiên hải sản", 630, "1 đĩa"], ["Bún đậu mắm tôm", 580, "1 phần"],
    ];
    const dinner = [
        ["Ức gà áp chảo + salad", 400, "1 phần"], ["Cơm + canh cải + đậu hũ", 480, "1 phần"],
        ["Cá hồi nướng + rau củ", 450, "1 phần"], ["Cháo tôm", 350, "1 tô"],
        ["Bún trộn rau + thịt nạc", 430, "1 tô"], ["Cơm gạo lứt + trứng", 460, "1 phần"],
        ["Súp gà rau củ", 320, "1 tô"], ["Cá basa kho + rau muống", 440, "1 phần"],
        ["Ức gà luộc + khoai lang", 410, "1 phần"], ["Canh chua cá + cơm ít", 470, "1 phần"],
        ["Đậu hũ sốt cà + cơm gạo lứt", 380, "1 phần"], ["Salad cá ngừ", 360, "1 tô"],
        ["Tôm hấp + rau củ luộc", 340, "1 phần"],
    ];
    const snacks = [
        ["Sữa chua không đường", 100, "1 hũ"], ["Chuối", 90, "1 quả"],
        ["Hạt điều", 160, "30g"], ["Táo", 80, "1 quả"], ["Sữa hạt", 130, "1 ly"],
        ["Ức gà xé sấy", 120, "20g"], ["Sữa chua Hy Lạp + granola", 180, "1 hũ"],
        ["Bánh gạo lứt", 90, "3 cái"], ["Ổi", 60, "1 quả"],
    ];

    const meals = [];
    for (let i = NUM_DAYS - 1; i >= 0; i--) {
        const dayDate = addDays(HISTORY_START, NUM_DAYS - 1 - i);
        const d = dateStr(dayDate);
        const dayIdx = NUM_DAYS - 1 - i;
        const mk = (arr, type, hour, minute) => {
            const item = pick(arr, dayIdx);
            const ts = new Date(dayDate);
            ts.setHours(hour, minute, 0, 0);
            meals.push({
                userId, name: item[0], calories: item[1], servingSize: item[2],
                mealType: type, imageUrl: "", date: d, timestamp: ts.toISOString(),
            });
        };
        mk(breakfast, "Sáng", randInt(6, 8), randInt(0, 59));
        mk(lunch, "Trưa", randInt(11, 13), randInt(0, 59));
        mk(dinner, "Tối", randInt(18, 20), randInt(0, 59));
        // ~75% số ngày có thêm bữa phụ, như người dùng thật (không phải ngày nào cũng ăn vặt)
        if (roll(0.75)) mk(snacks, "Snack", randInt(14, 16), randInt(0, 59));
    }
    await Meal.insertMany(meals);
    console.log(`✅ ${meals.length} bữa ăn (${NUM_DAYS} ngày)`);

    // 5) Buổi tập — gần như mỗi ngày, chừa ~1 ngày nghỉ/tuần cho thực tế
    const activities = [
        ["Chạy bộ", 25, 45, 8], ["Gym / Tập tạ", 40, 60, 10], ["Đạp xe", 30, 50, 7],
        ["Yoga", 20, 40, 3], ["Bơi lội", 30, 45, 5], ["Đi bộ nhanh", 30, 60, 5],
        ["Nhảy dây", 15, 25, 4], ["HIIT", 20, 30, 4],
    ];
    const records = [];
    for (let i = 0; i < NUM_DAYS; i++) {
        const dayDate = addDays(HISTORY_START, i);
        // Nghỉ tập vào Chủ Nhật (khoảng 1 lần/tuần), thêm ~5% nghỉ ngẫu nhiên (ốm/bận)
        const isSunday = dayDate.getDay() === 0;
        if (isSunday && roll(0.7)) continue;
        if (roll(0.05)) continue;

        const [type, minDur, maxDur, calPerMin] = pick(activities, i);
        const duration = randInt(minDur, maxDur);
        const calories = Math.round(duration * calPerMin * rand(0.9, 1.1));
        const ts = new Date(dayDate);
        ts.setHours(randInt(6, 19), randInt(0, 59), 0, 0);

        records.push({
            userId, activityType: type, weight: Math.round((START_WEIGHT - (START_WEIGHT - END_WEIGHT) * (i / (NUM_DAYS - 1))) * 10) / 10,
            height: 172, age: 27, duration, heartRate: randInt(110, 155), calories,
            date: ts.toISOString(),
        });
    }
    await CalorieRecord.insertMany(records);
    console.log(`✅ ${records.length} buổi tập`);

    // 6) Nước uống — vài lần ghi mỗi ngày, tổng ~1.5-2.8L/ngày
    const waterLogs = [];
    for (let i = 0; i < NUM_DAYS; i++) {
        const dayDate = addDays(HISTORY_START, i);
        const d = dateStr(dayDate);
        const entries = randInt(3, 6);
        for (let e = 0; e < entries; e++) {
            waterLogs.push({
                userId,
                amountMl: pick([250, 250, 330, 500, 500, 250], e + i),
                date: d,
            });
        }
    }
    await WaterLog.insertMany(waterLogs);
    console.log(`✅ ${waterLogs.length} lượt uống nước (${NUM_DAYS} ngày)`);

    // 7) Vài phiên chat mẫu rải rác trong quá trình dùng app
    const chatSamples = [
        {
            title: "Làm sao để giảm cân hiệu quả?",
            qa: [
                "Làm sao để giảm cân hiệu quả?",
                "Để giảm cân hiệu quả, bạn nên duy trì thâm hụt calo khoảng 500 kcal/ngày, ưu tiên protein nạc, rau xanh, hạn chế đồ ngọt và tập luyện đều đặn 3-5 buổi/tuần. Hãy uống đủ nước và ngủ đủ giấc nhé!",
            ],
        },
        {
            title: "Ăn gì trước khi tập gym?",
            qa: [
                "Ăn gì trước khi tập gym?",
                "Trước khi tập khoảng 60-90 phút, bạn nên ăn nhẹ giàu carb dễ tiêu và một ít protein, ví dụ chuối + sữa hạt hoặc bánh mì trứng. Tránh đồ ăn nhiều dầu mỡ ngay trước buổi tập để không bị đầy bụng.",
            ],
        },
        {
            title: "Bị đau cơ sau khi tập có nên nghỉ không?",
            qa: [
                "Bị đau cơ sau khi tập có nên nghỉ không?",
                "Đau cơ nhẹ (DOMS) sau 1-2 ngày là bình thường, bạn có thể tập nhẹ nhàng nhóm cơ khác hoặc đi bộ, giãn cơ để phục hồi nhanh hơn. Nếu đau nhói hoặc sưng bất thường thì nên nghỉ và theo dõi thêm.",
            ],
        },
        {
            title: "Uống bao nhiêu nước mỗi ngày là đủ?",
            qa: [
                "Uống bao nhiêu nước mỗi ngày là đủ?",
                "Với cân nặng và mức vận động hiện tại của bạn, nên uống khoảng 2-2.5 lít nước/ngày, chia đều trong ngày và uống thêm sau khi tập luyện để bù nước đã mất.",
            ],
        },
        {
            title: "Giảm cân mà không giảm cơ được không?",
            qa: [
                "Giảm cân mà không giảm cơ được không?",
                "Có thể! Bạn nên giảm calo từ từ (không cắt quá sâu), ăn đủ protein (~1.6-2g/kg cân nặng) và duy trì tập kháng lực để giữ khối cơ trong lúc giảm mỡ.",
            ],
        },
    ];
    for (let s = 0; s < chatSamples.length; s++) {
        const sample = chatSamples[s];
        const ts = daysAgo(NUM_DAYS - Math.round(((s + 1) / (chatSamples.length + 1)) * NUM_DAYS));
        await ChatSession.create({
            userId,
            sessionTitle: sample.title,
            messages: [
                { id: `${s}-1`, role: "user", content: sample.qa[0], timestamp: ts },
                { id: `${s}-2`, role: "model", content: sample.qa[1], timestamp: ts },
            ],
            createdAt: ts,
            updatedAt: ts,
        });
    }
    console.log(`✅ ${chatSamples.length} phiên chat mẫu`);

    console.log("\n========================================");
    console.log("🎉 SEED HOÀN TẤT — Tài khoản demo:");
    console.log(`   Email:    ${DEMO_EMAIL}`);
    console.log(`   Mật khẩu: ${DEMO_PASSWORD}`);
    console.log(`   Dữ liệu:  ${dateStr(HISTORY_START)} → ${dateStr(new Date())} (${NUM_DAYS} ngày)`);
    console.log("========================================\n");

    await mongoose.disconnect();
    process.exit(0);
}

run().catch((err) => {
    console.error("❌ Lỗi seed:", err);
    process.exit(1);
});
