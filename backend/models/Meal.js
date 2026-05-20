import mongoose from 'mongoose';

const mealSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  calories: { type: Number, required: true },
  servingSize: { type: String, default: '' }, // Ví dụ: '1 tô (250g)', '1 đĩa', '200g'
  mealType: { type: String, enum: ['Sáng', 'Trưa', 'Tối', 'Snack', 'AI Log'], required: true },
  imageUrl: { type: String, default: "" },
  date: { type: String, required: true }, // Format: YYYY-MM-DD
  timestamp: { type: String, default: () => new Date().toISOString() },
}, { timestamps: true });

export default mongoose.model('Meal', mealSchema);

