import express from 'express';
import jwt from 'jsonwebtoken';
import Meal from '../models/Meal.js';

const router = express.Router();

// Middleware: Xác thực JWT token
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ success: false, message: 'Không có token' });
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key_123');
    req.userId = decoded.user?.id || decoded.id;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token không hợp lệ' });
  }
};

// API: Thêm bữa ăn
// POST /api/meals
router.post('/', verifyToken, async (req, res) => {
  try {
    const { name, calories, mealType, date } = req.body;
    if (!name || !calories || !mealType || !date) {
      return res.status(400).json({ success: false, message: 'Thiếu thông tin' });
    }

    const meal = new Meal({
      userId: req.userId,
      name,
      calories: parseFloat(calories),
      mealType,
      date,
      timestamp: new Date().toISOString(),
    });

    await meal.save();
    console.log(`✅ Meal added for user ${req.userId}`);
    res.status(201).json({ success: true, message: 'Đã lưu bữa ăn', meal });
  } catch (err) {
    console.error('❌ Lỗi POST /meals:', err);
    res.status(500).json({ success: false, message: 'Lỗi máy chủ' });
  }
});

// API: Lấy bữa ăn theo ngày
// GET /api/meals?date=YYYY-MM-DD
router.get('/', verifyToken, async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) {
      return res.status(400).json({ success: false, message: 'Thiếu tham số date' });
    }

    const meals = await Meal.find({ userId: req.userId, date }).sort({ timestamp: -1 });
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
