import mongoose from "mongoose";

const calorieRecordSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  activityType: { type: String, required: true },
  weight: Number,
  height: Number,
  age: Number,
  duration: Number,
  heartRate: Number,
  calories: Number,
  date: { type: String, default: () => new Date().toISOString() },
});

// Tăng tốc truy vấn lịch sử theo người dùng & thời gian
calorieRecordSchema.index({ userId: 1, date: -1 });

export default mongoose.model("CalorieRecord", calorieRecordSchema);
