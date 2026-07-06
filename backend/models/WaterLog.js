import mongoose from "mongoose";

// Ghi nhận lượng nước uống theo ngày của người dùng.
const waterLogSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        amountMl: { type: Number, required: true }, // lượng nước mỗi lần ghi (ml)
        date: { type: String, required: true }, // YYYY-MM-DD (theo ngày local của người dùng)
        createdAt: { type: Date, default: () => new Date() },
    }
);

waterLogSchema.index({ userId: 1, date: -1 });

export default mongoose.model("WaterLog", waterLogSchema);
