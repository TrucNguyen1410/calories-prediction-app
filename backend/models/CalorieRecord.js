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
  date: { type: String, default: new Date().toISOString() },
});

export default mongoose.model("CalorieRecord", calorieRecordSchema);
