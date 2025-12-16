import mongoose from 'mongoose';

const mealSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  calories: { type: Number, required: true },
  mealType: { type: String, enum: ['Sáng', 'Trưa', 'Tối', 'Snack'], required: true },
  date: { type: String, required: true }, // Format: YYYY-MM-DD
  timestamp: { type: String, default: () => new Date().toISOString() },
}, { timestamps: true });

export default mongoose.model('Meal', mealSchema);
