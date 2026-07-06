import express from 'express';
import { 
    chatWithAI, 
    generateHealthPlan, 
    getWorkoutIntensityAHP, 
    analyzeFood,
    getUserSessions,
    getSessionDetail,
    createNewSession,
    deleteSession
} from '../controllers/aiController.js';
import multer from 'multer';
import { verifyToken } from '../middleware/authMiddleware.js';
import { rateLimit } from '../middleware/rateLimit.js';

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// Tất cả các route AI đều yêu cầu xác thực JWT (bảo vệ quota API & dữ liệu cá nhân)
router.use(verifyToken);

// Giới hạn tần suất gọi LLM để tránh cạn quota Groq: 20 request / phút / người dùng
router.use(rateLimit({ windowMs: 60_000, max: 20, message: 'Bạn đang gửi yêu cầu quá nhanh tới AI. Vui lòng đợi một chút.' }));

// --- CÁC ROUTE PHIÊN CHAT (SESSIONS) ---
router.get('/sessions', getUserSessions);
router.get('/sessions/:sessionId', getSessionDetail);
router.post('/sessions', createNewSession);
router.delete('/sessions/:sessionId', deleteSession);

// Route chat với AI
router.post('/chat', chatWithAI);

// Route tạo thực đơn & bài tập AI
router.post('/plan', generateHealthPlan);

// Route tính toán cường độ AHP
router.post('/ahp-suggestion', getWorkoutIntensityAHP);

// Route phân tích món ăn (Text/Image)
router.post('/analyze-food', upload.single('image'), analyzeFood);

export default router;
