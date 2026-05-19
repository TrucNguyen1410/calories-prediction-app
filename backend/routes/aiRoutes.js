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

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

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
