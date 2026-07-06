// Kiểm thử đơn vị cho các hàm tính toán sức khỏe.
// Chạy bằng: npm test  (dùng test runner tích hợp của Node >= 18, không cần thư viện ngoài)
import { test } from "node:test";
import assert from "node:assert/strict";
import {
    computeBMI,
    classifyBMIAsian,
    computeBMR,
    computeTDEE,
    computeDailyCalorieTarget,
} from "../utils/health.js";

test("computeBMI tính đúng chỉ số BMI", () => {
    // 70kg, 175cm -> 70 / 1.75^2 = 22.857 -> 22.9
    assert.equal(computeBMI(70, 175), 22.9);
    assert.equal(computeBMI(50, 160), 19.5);
});

test("computeBMI trả về null với dữ liệu không hợp lệ", () => {
    assert.equal(computeBMI(0, 175), null);
    assert.equal(computeBMI(70, 0), null);
    assert.equal(computeBMI(-5, 175), null);
});

test("classifyBMIAsian phân loại theo chuẩn châu Á", () => {
    assert.equal(classifyBMIAsian(17), "Thiếu cân");
    assert.equal(classifyBMIAsian(21), "Bình thường");
    assert.equal(classifyBMIAsian(24), "Thừa cân");
    assert.equal(classifyBMIAsian(27), "Béo phì độ I");
    assert.equal(classifyBMIAsian(32), "Béo phì độ II");
    assert.equal(classifyBMIAsian(null), "Không xác định");
});

test("computeBMR theo công thức Mifflin-St Jeor", () => {
    // Nam 70kg/175cm/25t: 10*70 + 6.25*175 - 5*25 + 5 = 1673.75 -> 1674
    assert.equal(computeBMR(70, 175, 25, "Nam"), 1674);
    // Nữ cùng thông số: ... - 161 = 1507.75 -> 1508
    assert.equal(computeBMR(70, 175, 25, "Nữ"), 1508);
    assert.equal(computeBMR(0, 175, 25, "Nam"), null);
});

test("computeTDEE nhân BMR với hệ số vận động", () => {
    assert.equal(computeTDEE(1674), Math.round(1674 * 1.375));
    assert.equal(computeTDEE(1674, 1.55), Math.round(1674 * 1.55));
    assert.equal(computeTDEE(0), null);
});

test("computeDailyCalorieTarget điều chỉnh theo mục tiêu", () => {
    const profile = { weightKg: 70, heightCm: 175, age: 25, gender: "Nam", activityLevel: "light" };
    const maintain = computeDailyCalorieTarget({ ...profile, goal: "maintain" });
    const lose = computeDailyCalorieTarget({ ...profile, goal: "lose" });
    const gain = computeDailyCalorieTarget({ ...profile, goal: "gain" });

    // BMR 1674 * 1.375 = 2302 (maintain)
    assert.equal(maintain, 2302);
    assert.equal(lose, 2302 - 500); // giảm cân: -500
    assert.equal(gain, 2302 + 500); // tăng cân: +500
});

test("computeDailyCalorieTarget không xuống dưới 1200 và trả null khi thiếu dữ liệu", () => {
    const tiny = computeDailyCalorieTarget({ weightKg: 30, heightCm: 120, age: 80, gender: "Nữ", goal: "lose", activityLevel: "sedentary" });
    assert.ok(tiny >= 1200);
    assert.equal(computeDailyCalorieTarget({ weightKg: 0, heightCm: 175, age: 25, gender: "Nam" }), null);
});
