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

export default { computeBMI, classifyBMIAsian, computeBMR, computeTDEE };
