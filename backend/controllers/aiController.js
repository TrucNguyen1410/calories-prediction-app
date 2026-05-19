import Groq from "groq-sdk";
import ChatMessage from "../models/ChatMessage.js";
import User from "../models/User.js";
import dotenv from "dotenv";
import { GoogleGenerativeAI } from "@google/generative-ai";


dotenv.config();

const groq = new Groq({
    apiKey: process.env.GROQ_API_KEY || "dummy_key_to_prevent_startup_crash",
});

// --- 1. CHAT VỚI AI (Dùng Groq Llama 3) ---
export const chatWithAI = async (req, res) => {
    try {
        const { userId, message } = req.body;

        // Lấy lịch sử 10 tin nhắn gần nhất
        const history = await ChatMessage.find({ userId }).sort({ createdAt: -1 }).limit(10);
        const chatHistory = history.reverse().map(msg => ({
            role: msg.role === 'user' ? 'user' : 'assistant',
            content: msg.content,
        }));

        // Gọi API Groq
        const completion = await groq.chat.completions.create({
            messages: [
                { role: "system", content: "Bạn là một trợ lý sức khỏe thông minh. Hãy trả lời ngắn gọn, hữu ích bằng tiếng Việt." },
                ...chatHistory,
                { role: "user", content: message }
            ],
            model: "llama-3.3-70b-versatile",
            temperature: 0.7,
            max_tokens: 1024,
        });

        const reply = completion.choices[0]?.message?.content || "Xin lỗi, mình không thể trả lời lúc này.";

        // Lưu vào DB
        await ChatMessage.create({ userId, role: 'user', content: message });
        await ChatMessage.create({ userId, role: 'model', content: reply });

        res.status(200).json({ success: true, reply });
    } catch (error) {
        console.error("GROQ ERROR:", error);
        res.status(500).json({ success: false, message: "Lỗi kết nối AI (Groq)" });
    }
};

// --- 2. TẠO THỰC ĐƠN & BÀI TẬP ---
export const generateHealthPlan = async (req, res) => {
    try {
        const { userId } = req.body;
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: "Không tìm thấy người dùng" });

        const { name, gender, height, weight, dob } = user;
        const age = new Date().getFullYear() - new Date(dob).getFullYear();
        const bmi = (weight / ((height / 100) ** 2)).toFixed(1);

        const prompt = `
            Dựa trên thông tin: Tên ${name}, ${gender}, ${age} tuổi, BMI ${bmi}.
            Hãy tạo thực đơn 7 ngày và 5 bài tập.
            TRẢ VỀ ĐỊNH DẠNG JSON:
            {
                "bmi_status": "...",
                "advice": "...",
                "meal_plan": [{ "day": 1, "breakfast": "...", "lunch": "...", "dinner": "...", "snack": "..." }],
                "exercises": [{ "name": "...", "sets": 3, "reps": 12, "benefit": "..." }]
            }
            CHỈ TRẢ VỀ JSON.
        `;

        const completion = await groq.chat.completions.create({
            messages: [{ role: "user", content: prompt }],
            model: "llama-3.3-70b-versatile",
            response_format: { type: "json_object" }
        });

        const data = JSON.parse(completion.choices[0].message.content);
        res.status(200).json({ success: true, data });
    } catch (error) {
        res.status(500).json({ success: false, message: "Lỗi khi tạo kế hoạch sức khỏe" });
    }
};

// --- 3. THUẬT TOÁN AHP ---
export const getWorkoutIntensityAHP = async (req, res) => {
    try {
        const { userId, sleepHours, stressLevel } = req.body; 
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: "User not found" });

        const bmi = user.weight / ((user.height / 100) ** 2);
        let score = (bmi >= 18.5 && bmi <= 25) ? 40 : 25;
        score += sleepHours >= 7 ? 30 : 15;
        score += (11 - stressLevel) * 3;

        let intensity = score > 80 ? "Cao" : (score > 50 ? "Trung bình" : "Thấp");

        res.status(200).json({ success: true, score, intensity });
    } catch (error) {
        res.status(500).json({ success: false, message: "Lỗi AHP" });
    }
};

// --- 4. PHÂN TÍCH DINH DƯỠNG TỪ TEXT/IMAGE ---
export const analyzeFood = async (req, res) => {
    try {
        const { text } = req.body;
        const imageFile = req.file; 

        let nutritionData = null;

        if (imageFile) {
            const genAI = new GoogleGenerativeAI(process.env.SUPER_GEMINI_KEY);
            const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

            const imageData = {
                inlineData: {
                    data: imageFile.buffer.toString("base64"),
                    mimeType: imageFile.mimetype,
                },
            };

            const prompt = "Hãy phân tích hình ảnh món ăn này và trả về JSON: { \"foodName\": \"...\", \"estimatedCalories\": 0, \"protein\": 0, \"carbs\": 0, \"fat\": 0 }. Chỉ trả về JSON.";
            const result = await model.generateContent([prompt, imageData]);
            const response = await result.response;
            const textResponse = response.text().replace(/```json|```/g, "").trim();
            nutritionData = JSON.parse(textResponse);
        } else if (text) {
            const prompt = `Hãy phân tích mô tả món ăn sau: "${text}". Trả về JSON: { "foodName": "...", "estimatedCalories": 0, "protein": 0, "carbs": 0, "fat": 0 }. Chỉ trả về JSON.`;
            const completion = await groq.chat.completions.create({
                messages: [{ role: "user", content: prompt }],
                model: "llama-3.3-70b-versatile",
                response_format: { type: "json_object" }
            });
            nutritionData = JSON.parse(completion.choices[0].message.content);
        }

        res.status(200).json({ success: true, data: nutritionData });
    } catch (error) {
        console.error("ANALYZE FOOD ERROR:", error);
        res.status(500).json({ success: false, message: "Không thể phân tích món ăn" });
    }
};

