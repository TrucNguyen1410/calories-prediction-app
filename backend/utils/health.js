// Các hàm tính toán sức khỏe dùng chung cho toàn hệ thống.
// Tách riêng & thuần (pure function) để dễ kiểm thử đơn vị (unit test).

/**
 * Tính chỉ số khối cơ thể (BMI).
 * @param {number} weightKg cân nặng (kg)
 * @param {number} heightCm chiều cao (cm)
 * @returns {number|null} BMI làm tròn 1 chữ số, hoặc null nếu dữ liệu không hợp lệ
 */
export function computeBMI(weightKg, heightCm) {
    if (!weightKg || !heightCm || weightKg <= 0 || heightCm <= 0) return null;
    const hM = heightCm / 100;
    return Math.round((weightKg / (hM * hM)) * 10) / 10;
}

/**
 * Phân loại BMI theo chuẩn dành cho người châu Á (WHO/IDI & WPRO).
 * @param {number} bmi
 * @returns {string}
 */
export function classifyBMIAsian(bmi) {
    if (bmi == null || Number.isNaN(bmi)) return "Không xác định";
    if (bmi < 18.5) return "Thiếu cân";
    if (bmi < 23) return "Bình thường";
    if (bmi < 25) return "Thừa cân";
    if (bmi < 30) return "Béo phì độ I";
    return "Béo phì độ II";
}

/**
 * Tính tỉ lệ trao đổi chất cơ bản (BMR) theo công thức Mifflin-St Jeor.
 * @param {number} weightKg
 * @param {number} heightCm
 * @param {number} age tuổi (năm)
 * @param {string} gender "Nam" | "Nữ" | ...
 * @returns {number|null} BMR (kcal/ngày) làm tròn
 */
export function computeBMR(weightKg, heightCm, age, gender) {
    if (!weightKg || !heightCm || !age) return null;
    const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    const bmr = gender === "Nam" ? base + 5 : base - 161;
    return Math.round(bmr);
}

/**
 * Ước lượng tổng năng lượng tiêu hao hằng ngày (TDEE) từ BMR & mức vận động.
 * @param {number} bmr
 * @param {number} activityFactor hệ số vận động (mặc định 1.375 - vận động nhẹ)
 * @returns {number|null}
 */
export function computeTDEE(bmr, activityFactor = 1.375) {
    if (!bmr) return null;
    return Math.round(bmr * activityFactor);
}

// Hệ số vận động tương ứng mức độ hoạt động
export const ACTIVITY_FACTORS = {
    sedentary: 1.2, // ít vận động
    light: 1.375, // vận động nhẹ (1-3 buổi/tuần)
    moderate: 1.55, // vận động vừa (3-5 buổi/tuần)
    active: 1.725, // vận động nhiều (6-7 buổi/tuần)
    very_active: 1.9, // vận động rất nhiều / lao động nặng
};

/**
 * Tính mục tiêu calo nạp hằng ngày cá nhân hóa từ hồ sơ + mục tiêu.
 * @returns {number|null} mục tiêu kcal/ngày (đã điều chỉnh theo mục tiêu, clamp tối thiểu 1200)
 */
export function computeDailyCalorieTarget({ weightKg, heightCm, age, gender, goal = "maintain", activityLevel = "light" }) {
    const bmr = computeBMR(weightKg, heightCm, age, gender);
    if (!bmr) return null;
    const factor = ACTIVITY_FACTORS[activityLevel] || ACTIVITY_FACTORS.light;
    let tdee = Math.round(bmr * factor);
    if (goal === "lose") tdee -= 500;
    else if (goal === "gain") tdee += 500;
    return Math.max(1200, tdee);
}

export default {
    computeBMI,
    classifyBMIAsian,
    computeBMR,
    computeTDEE,
    computeDailyCalorieTarget,
    ACTIVITY_FACTORS,
};
