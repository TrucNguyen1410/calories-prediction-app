import mongoose from "mongoose";

// Lưu lại từng lần đo chỉ số cơ thể của người dùng theo thời gian,
// phục vụ vẽ biểu đồ xu hướng cân nặng / BMI thật (thay cho dữ liệu giả lập).
const healthMetricSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        weight: { type: Number, required: true }, // kg
        height: { type: Number }, // cm
        bmi: { type: Number }, // chỉ số khối cơ thể tại thời điểm đo
        note: { type: String, default: "" },
        source: { type: String, enum: ["manual", "profile"], default: "manual" },
        date: { type: Date, default: () => new Date() },
    },
    { timestamps: true }
);

healthMetricSchema.index({ userId: 1, date: -1 });

export default mongoose.model("HealthMetric", healthMetricSchema);
