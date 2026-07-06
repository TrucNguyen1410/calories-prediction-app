import express from 'express';
import Meal from '../models/Meal.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// API: Thêm bữa ăn
// POST /api/meals
router.post('/', verifyToken, async (req, res) => {
  try {
    const { name, calories, mealType, date, imageUrl, servingSize } = req.body;
    if (!name || !calories || !mealType || !date) {
      return res.status(400).json({ success: false, message: 'Thiếu thông tin' });
    }

    const meal = new Meal({
      userId: req.userId,
      name,
      calories: parseFloat(calories),
      servingSize: servingSize || "",
      mealType,
      date,
      imageUrl: imageUrl || "",
      timestamp: new Date().toISOString(),
    });

    await meal.save();
    console.log(`✅ Meal added for user ${req.userId} with serving size: ${servingSize}`);
    res.status(201).json({ success: true, message: 'Đã lưu bữa ăn', meal });
  } catch (err) {
    console.error('❌ Lỗi POST /meals:', err);
    res.status(500).json({ success: false, message: 'Lỗi máy chủ' });
  }
});

// API: Lấy bữa ăn (nếu có date thì lọc theo ngày, nếu không thì lấy toàn bộ lịch sử)
// GET /api/meals
router.get('/', verifyToken, async (req, res) => {
  try {
    const { date } = req.query;
    const query = { userId: req.userId };
    if (date) {
      query.date = date;
    }

    const meals = await Meal.find(query).sort({ timestamp: -1 });
    res.json({ success: true, data: meals });
  } catch (err) {
    console.error('❌ Lỗi GET /meals:', err);
    res.status(500).json({ success: false, message: 'Lỗi máy chủ' });
  }
});

// API: Xóa bữa ăn
// DELETE /api/meals/:mealId
router.delete('/:mealId', verifyToken, async (req, res) => {
  try {
    const meal = await Meal.findById(req.params.mealId);
    if (!meal) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy bữa ăn' });
    }
    if (meal.userId.toString() !== req.userId) {
      return res.status(403).json({ success: false, message: 'Không có quyền' });
    }

    await Meal.findByIdAndDelete(req.params.mealId);
    console.log(`✅ Meal deleted: ${req.params.mealId}`);
    res.json({ success: true, message: 'Đã xóa bữa ăn' });
  } catch (err) {
    console.error('❌ Lỗi DELETE /meals:', err);
    res.status(500).json({ success: false, message: 'Lỗi máy chủ' });
  }
});

export default router;
