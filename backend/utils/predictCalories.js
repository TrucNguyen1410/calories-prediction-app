import { spawn } from "child_process";

// Gọi model học máy (Gradient Boosting, đã huấn luyện trên gym_members_exercise
// dataset, R² ≈ 0.99) để dự đoán calo tiêu hao từ chỉ số cơ thể + thời lượng
// vận động — dùng chung cho cả màn hình "Dự đoán calo" (predict_screen) và
// tính năng ghi nhận tập luyện qua chatbot AI (chatWithAI/LOG_WORKOUT), để mô
// hình học máy thật sự đứng sau con số calo người dùng thấy, không chỉ nằm ở
// 1 màn hình riêng ít người dùng.
// Trả về null nếu tiến trình Python lỗi — caller tự quyết định fallback (vd
// công thức MET, hoặc số LLM tự ước lượng).
export function predictCaloriesML({ weight, height, age, duration, heartRate, activityType = "Khác" }) {
    return new Promise((resolve) => {
        const py = spawn("python", [
            "./ml/predict.py",
            String(weight),
            String(height),
            String(age),
            String(duration),
            String(heartRate),
            String(activityType),
        ]);

        let result = "";
        py.stdout.on("data", (data) => {
            result += data.toString();
        });
        py.stderr.on("data", (data) => {
            console.error("⚠️ Python stderr (predictCaloriesML):", data.toString());
        });

        py.on("close", () => {
            try {
                const output = JSON.parse(result);
                if (output.success) {
                    resolve({ calories: parseFloat(output.calories), source: output.source });
                } else {
                    resolve(null);
                }
            } catch (err) {
                console.error("❌ Lỗi parse kết quả predictCaloriesML:", err, "raw:", result);
                resolve(null);
            }
        });

        py.on("error", (err) => {
            console.error("❌ Lỗi spawn python (predictCaloriesML):", err);
            resolve(null);
        });
    });
}
