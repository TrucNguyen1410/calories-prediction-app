import Groq from "groq-sdk";
import ChatMessage from "../models/ChatMessage.js";
import ChatSession from "../models/ChatSession.js";
import User from "../models/User.js";
import dotenv from "dotenv";
import { GoogleGenerativeAI } from "@google/generative-ai";


dotenv.config();

const groq = new Groq({
    apiKey: process.env.GROQ_API_KEY || "dummy_key_to_prevent_startup_crash",
});

// --- 1. CHAT VỚI AI (Hỗ trợ Đa phiên Chat Sessions) ---
export const chatWithAI = async (req, res) => {
    try {
        const { userId, message, sessionId } = req.body;

        // Lấy thông tin thể chất của người dùng từ Database để cá nhân hóa
        const user = await User.findById(userId);
        let weight = 65;
        let height = 170;
        let gender = "Nam";
        let age = 25;

        if (user) {
            weight = user.weight || 65;
            height = user.height || 170;
            gender = user.gender || "Nam";
            if (user.dob) {
                age = new Date().getFullYear() - new Date(user.dob).getFullYear();
            }
        }

        // Tìm hoặc khởi tạo phiên chat (ChatSession)
        let session;
        if (sessionId) {
            session = await ChatSession.findById(sessionId);
        }
        
        if (!session) {
            session = new ChatSession({
                userId,
                sessionTitle: "Cuộc trò chuyện mới",
                messages: []
            });
        }

        // Lấy lịch sử 10 tin nhắn gần nhất từ phiên chat này
        const chatHistory = session.messages.slice(-10).map(msg => ({
            role: msg.role === 'user' ? 'user' : 'assistant',
            content: msg.content,
        }));

        const systemPrompt = `Bạn là Trợ lý Sức khỏe AI (HealthAI) và huấn luyện viên thể thao thông minh bằng tiếng Việt.
Hồ sơ thể chất người dùng:
- Giới tính: ${gender}
- Cân nặng: ${weight} kg
- Chiều cao: ${height} cm
- Tuổi: ${age} tuổi

Quy định bảo mật nội dung (Guardrails):
Bạn CHỈ ĐƯỢC PHÉP trả lời các câu hỏi liên quan đến sức khỏe, dinh dưỡng, tập luyện, chỉ số BMI, BMR.
Nếu người dùng hỏi bất kỳ chủ đề nào khác ngoài phạm vi trên (Ví dụ: lập trình, toán học, tin tức xã hội, v.v.), bạn KHÔNG ĐƯỢC TRẢ LỜI nội dung đó. Hãy từ chối một cách lịch sự bằng câu chính xác: "Tôi là trợ lý sức khỏe và thể thao, tôi không thể giúp bạn giải đáp các vấn đề ngoài phạm vi này." và dừng lại ngay lập tức.

Nhiệm vụ đặc biệt:
1. Nếu người dùng kể hoặc chia sẻ về việc họ vừa hoàn thành một hoạt động vận động, thể thao, tập luyện hoặc hoạt động thể chất (ví dụ: "Tôi vừa chạy bộ 30 phút", "Nay đá bóng 1 tiếng", "Tôi mới tập gym 45 phút"), bạn BẮT BUỘC phải tính toán gần đúng lượng calo tiêu thụ của họ dựa trên hồ sơ thể chất (nặng ${weight}kg, tuổi ${age}) và loại hoạt động đó. Bạn chỉ được phép trả về DUY NHẤT một chuỗi JSON có cấu trúc chính xác như sau, không được phép kèm bất kỳ lời giải thích, chào hỏi hay ký tự thừa nào ngoài JSON:
{
  "action": "LOG_WORKOUT",
  "activityName": "Tên môn thể thao/hoạt động bằng tiếng Việt (ví dụ: Chạy bộ, Đá bóng, Thể hình...)",
  "duration": số phút vận động (number, ví dụ: 30),
  "caloriesBurned": số calo đốt cháy ước tính (number, ví dụ: 320),
  "message": "Lời chúc mừng/động viên ngắn gọn, truyền năng lượng bằng tiếng Việt kèm con số calo vừa đốt cháy (ví dụ: Tuyệt vời! Bạn đã đốt cháy 320 kcal từ việc Chạy bộ.)"
}

2. Nếu người dùng chỉ nhắn tin hỏi đáp, tư vấn sức khỏe, dinh dưỡng hoặc trò chuyện bình thường trong phạm vi sức khỏe và thể chất (ví dụ: "Xin chào", "Làm sao để giảm cân?", "Tôi nên ăn gì?"), bạn hãy trả lời bằng văn bản thông thường, ngắn gọn, thân thiện bằng tiếng Việt. Tuyệt đối không được trả về cấu trúc JSON này khi trò chuyện bình thường.`;

        // Gọi API Groq
        const completion = await groq.chat.completions.create({
            messages: [
                { role: "system", content: systemPrompt },
                ...chatHistory,
                { role: "user", content: message }
            ],
            model: "llama-3.3-70b-versatile",
            temperature: 0.7,
            max_tokens: 1024,
        });

        let reply = completion.choices[0]?.message?.content || "Xin lỗi, mình không thể trả lời lúc này.";

        // Làm sạch chuỗi markdown codeblock nếu AI tự bao bọc
        let cleanedReply = reply.trim();
        if (cleanedReply.startsWith("```json")) {
            cleanedReply = cleanedReply.replace(/^```json/, "").replace(/```$/, "").trim();
            reply = cleanedReply;
        } else if (cleanedReply.startsWith("```")) {
            cleanedReply = cleanedReply.replace(/^```/, "").replace(/```$/, "").trim();
            reply = cleanedReply;
        }

        // Phân tích xem phản hồi có phải là Actionable LOG_WORKOUT JSON không
        let isActionable = false;
        let actionType = null;
        let actionData = null;
        
        try {
            const parsedJson = JSON.parse(reply);
            if (parsedJson.action === "LOG_WORKOUT") {
                isActionable = true;
                actionType = "LOG_WORKOUT";
                actionData = parsedJson;
            }
        } catch (e) {
            // Không phải JSON, xử lý như tin nhắn thường
        }

        // Tự động đặt tiêu đề cuộc hội thoại nếu đang ở trạng thái mặc định và là câu chat đầu tiên
        if (session.sessionTitle === "Cuộc trò chuyện mới" && session.messages.length === 0) {
            session.sessionTitle = message.substring(0, 30) + (message.length > 30 ? "..." : "");
        }

        // Lưu tin nhắn của User vào danh sách
        session.messages.push({
            id: Date.now().toString(),
            role: "user",
            content: message,
            timestamp: new Date()
        });

        // Lưu tin nhắn phản hồi của AI vào danh sách
        session.messages.push({
            id: (Date.now() + 1).toString(),
            role: "model",
            content: reply,
            isActionable,
            actionType,
            actionData,
            timestamp: new Date()
        });

        // Lưu phiên chat vào MongoDB
        await session.save();

        res.status(200).json({ 
            success: true, 
            reply, 
            sessionId: session._id,
            sessionTitle: session.sessionTitle
        });
    } catch (error) {
        console.error("GROQ ERROR:", error);
        res.status(500).json({ success: false, message: "Lỗi kết nối AI (Groq)" });
    }
};

// --- LẤY DANH SÁCH PHIÊN CHAT CỦA USER ---
export const getUserSessions = async (req, res) => {
    try {
        const { userId } = req.query;
        if (!userId) return res.status(400).json({ success: false, message: "Thiếu userId" });
        
        const sessions = await ChatSession.find({ userId })
            .select("sessionTitle updatedAt")
            .sort({ updatedAt: -1 });
            
        res.status(200).json({ success: true, sessions });
    } catch (error) {
        console.error("GET SESSIONS ERROR:", error);
        res.status(500).json({ success: false, message: "Lỗi lấy danh sách phiên chat" });
    }
};

// --- LẤY CHI TIẾT PHIÊN CHAT (LỊCH SỬ TIN NHẮN) ---
export const getSessionDetail = async (req, res) => {
    try {
        const { sessionId } = req.params;
        const session = await ChatSession.findById(sessionId);
        if (!session) return res.status(404).json({ success: false, message: "Không tìm thấy phiên chat" });
        
        res.status(200).json({ 
            success: true, 
            sessionTitle: session.sessionTitle, 
            messages: session.messages 
        });
    } catch (error) {
        console.error("GET SESSION DETAIL ERROR:", error);
        res.status(500).json({ success: false, message: "Lỗi lấy chi tiết phiên chat" });
    }
};

// --- TẠO MỚI PHIÊN CHAT TRỐNG ---
export const createNewSession = async (req, res) => {
    try {
        const { userId } = req.body;
        if (!userId) return res.status(400).json({ success: false, message: "Thiếu userId" });
        
        const session = new ChatSession({
            userId,
            sessionTitle: "Cuộc trò chuyện mới",
            messages: []
        });
        await session.save();
        res.status(201).json({ success: true, session });
    } catch (error) {
        console.error("CREATE SESSION ERROR:", error);
        res.status(500).json({ success: false, message: "Lỗi tạo phiên chat mới" });
    }
};

// --- XÓA PHIÊN CHAT ---
export const deleteSession = async (req, res) => {
    try {
        const { sessionId } = req.params;
        await ChatSession.findByIdAndDelete(sessionId);
        res.status(200).json({ success: true, message: "Đã xóa phiên chat thành công" });
    } catch (error) {
        console.error("DELETE SESSION ERROR:", error);
        res.status(500).json({ success: false, message: "Lỗi xóa phiên chat" });
    }
};

// --- 2. TẠO THỰC ĐƠN & BÀI TẬP ---
export const generateHealthPlan = async (req, res) => {
    try {
        const { userId, userInput } = req.body;
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: "Không tìm thấy người dùng" });

        const { name, gender, height, weight, dob } = user;
        let age = 25;
        if (dob) {
            age = new Date().getFullYear() - new Date(dob).getFullYear();
        }
        const bmi = (weight / ((height / 100) ** 2)).toFixed(1);
        
        let specialRequest = userInput ? `YÊU CẦU ĐẶC BIỆT TỪ NGƯỜI DÙNG: "${userInput}". \nBẮT BUỘC: Bạn phải phân tích yêu cầu này (nếu họ muốn ăn món gì, hãy cố gắng sắp xếp hợp lý món đó vào thực đơn; nếu họ kiêng cữ/dị ứng, tuyệt đối loại bỏ).` : "";

        const prompt = `
            Dựa trên thông tin: Tên ${name || 'Khách'}, Giới tính ${gender || 'Nam'}, ${age} tuổi, BMI ${bmi}.
            ${specialRequest}
            Hãy thiết kế một thực đơn dinh dưỡng đầy đủ 7 ngày trong tuần chuẩn khoa học.
            TRẢ VỀ ĐỊNH DẠNG JSON CHUẨN XÁC THEO CẤU TRÚC SAU (KHÔNG BỌC TRONG MARKDOWN CODEBLOCK):
            {
              "action": "GENERATE_MEAL_PLAN",
              "bmi_status": "Phân loại BMI",
              "advice": "Lời khuyên dinh dưỡng tổng quan ngắn gọn",
              "weeklyPlan": [
                {
                  "day": "T2",
                  "totalCalories": 1500,
                  "daily_desc": "Mô tả ngắn gọn (VD: Ức gà & Salad)",
                  "meals": [
                    {"type": "Bữa sáng", "name": "Tên món", "servingSize": "1 tô (250g)", "calories": 350, "carbs": 48, "protein": 12, "fat": 6},
                    {"type": "Bữa trưa", "name": "Tên món", "servingSize": "1 phần (300g)", "calories": 500, "carbs": 55, "protein": 25, "fat": 15},
                    {"type": "Bữa tối", "name": "Tên món", "servingSize": "1 đĩa (200g)", "calories": 450, "carbs": 30, "protein": 10, "fat": 12},
                    {"type": "Bữa phụ", "name": "Tên món", "servingSize": "1 hộp (100g)", "calories": 200, "carbs": 20, "protein": 5, "fat": 8}
                  ]
                }
              ]
            }
            BẮT BUỘC: Kế hoạch "weeklyPlan" phải chứa đúng 7 phần tử tương ứng đầy đủ với 7 ngày trong tuần lần lượt là: "T2", "T3", "T4", "T5", "T6", "T7", "CN". Tuyệt đối không được bỏ sót ngày Chủ Nhật ("CN").
            BẮT BUỘC: Mỗi món ăn PHẢI có trường "servingSize" (khẩu phần/định lượng) rõ ràng khớp với số calo đã tính. Ví dụ: "1 tô (250g)", "2 lát bánh mì", "1 hũ sữa chua (150ml)", "1 chén cơm + 100g thịt".
            QUAN TRỌNG: Mỗi ngày phải có tổng calo KHÁC NHAU tùy theo các món ăn thực tế (dao động 1200-2000 kcal).
            Tính totalCalories = tổng cộng calories của TẤT CẢ các meals trong ngày đó.
            CHỈ TRẢ VỀ JSON. KHÔNG GIẢI THÍCH GÌ THÊM.
        `;

        const completion = await groq.chat.completions.create({
            messages: [{ role: "user", content: prompt }],
            model: "llama-3.3-70b-versatile",
            temperature: 0.5,
            response_format: { type: "json_object" }
        });

        let content = completion.choices[0].message.content.trim();
        
        // Dùng Regex trích xuất chính xác khối JSON giữa {} để tránh lỗi parse khi AI trả về văn bản thừa
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            content = jsonMatch[0];
        }

        const data = JSON.parse(content);
        res.status(200).json({ success: true, data });
    } catch (error) {
        console.error("GENERATE PLAN ERROR:", error);
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
        const { text, remainingCalories, todayIntake, targetCalories } = req.body;
        const imageFile = req.file; 

        // Validate: phải có text hoặc image
        if (!imageFile && (!text || text.trim() === '')) {
            return res.status(400).json({ success: false, message: "Vui lòng nhập tên món ăn hoặc tải ảnh lên" });
        }

        let nutritionData = null;

        if (imageFile) {
            // Sử dụng Groq Vision (llama-3.2-11b-vision-preview) cực kỳ ổn định,
            // dùng chung GROQ_API_KEY sẵn có mà không cần cấu hình thêm Gemini Key.
            const base64Image = imageFile.buffer.toString("base64");
            const prompt = `Nhiệm vụ của bạn là phân tích hình ảnh món ăn này.
            
            Thông tin calo hiện tại của người dùng hôm nay:
            - Mục tiêu calo hàng ngày (TDEE): ${targetCalories || 2000} kcal
            - Calo đã nạp: ${todayIntake || 0} kcal
            - Calo còn lại: ${remainingCalories || 2000} kcal

            Điều kiện bắt buộc: Nếu nội dung trong hình KHÔNG PHẢI là thực phẩm, thức ăn, hoặc đồ uống, bạn KHÔNG ĐƯỢC tính toán Calo. Hãy lập tức trả về cấu trúc JSON chính xác như sau:
            {
                "isFood": false,
                "message": "Đây không phải là thức ăn hoặc đồ uống hợp lệ. Vui lòng nhập lại!"
            }

            Nếu là thực phẩm/thức ăn hợp lệ, hãy trả về JSON chứa thông tin dinh dưỡng:
            {
                "isFood": true,
                "foodName": "tên món ăn bằng tiếng Việt",
                "servingSize": "khẩu phần cụ thể tương ứng với số calo (ví dụ: 1 đĩa 200g, 1 tô 300ml, 2 cái bánh)",
                "estimatedCalories": số calo (number),
                "calories": số calo (number),
                "protein": số g đạm (number),
                "carbs": số g tinh bột (number),
                "fat": số g chất béo (number),
                "macros": "Carb: [số g carbs]g • Protein: [số g protein]g • Fat: [số g fat]g",
                "isReasonable": true hoặc false (boolean),
                "warningMessage": "chuỗi cảnh báo thông minh hoặc rỗng",
                "message": "Phân tích dinh dưỡng món ăn"
            }
            BẮT BUỘC: Trường "servingSize" phải ghi rõ định lượng cụ thể (số lượng + đơn vị + gram nếu có) tương ứng chính xác với số calo đã tính.
            Chỉ trả về đối tượng JSON, không giải thích gì thêm.`;

            const completion = await groq.chat.completions.create({
                messages: [
                    {
                        role: "user",
                        content: [
                            { type: "text", text: prompt },
                            {
                                type: "image_url",
                                image_url: {
                                    url: `data:${imageFile.mimetype};base64,${base64Image}`,
                                },
                            },
                        ],
                    },
                ],
                model: "meta-llama/llama-4-scout-17b-16e-instruct",
                response_format: { type: "json_object" }
            });

            const content = completion.choices[0]?.message?.content;
            nutritionData = JSON.parse(content);
            if (nutritionData) {
                nutritionData.imageUrl = `data:${imageFile.mimetype};base64,${base64Image}`;
            }
        } else if (text) {
            const prompt = `Nhiệm vụ của bạn là phân tích món ăn người dùng vừa nhập: "${text}".
            
            Thông tin calo hiện tại của người dùng hôm nay:
            - Mục tiêu calo hàng ngày (TDEE): ${targetCalories || 2000} kcal
            - Calo đã nạp: ${todayIntake || 0} kcal
            - Calo còn lại: ${remainingCalories || 2000} kcal

            Điều kiện bắt buộc: Nếu nội dung nhập vào KHÔNG PHẢI là thực phẩm, thức ăn, hoặc đồ uống (Ví dụ: máy tính, bàn ghế, lập trình web...), bạn KHÔNG ĐƯỢC tính toán Calo. Hãy lập tức trả về cấu trúc JSON chính xác như sau:
            {
                "isFood": false,
                "message": "Đây không phải là thức ăn hoặc đồ uống hợp lệ. Vui lòng nhập lại!"
            }

            Nếu là thức ăn hợp lệ: Trả về JSON chứa thông tin dinh dưỡng:
            {
                "isFood": true,
                "foodName": "tên món ăn bằng tiếng Việt",
                "servingSize": "khẩu phần cụ thể tương ứng với số calo (ví dụ: 1 tô 300g, 1 miếng 150g, 2 lát bánh mì)",
                "estimatedCalories": số calo (number),
                "calories": số calo (number),
                "carbs": số g tinh bột (number),
                "protein": số g đạm (number),
                "fat": số g chất béo (number),
                "macros": "Carb: [số g carbs]g • Protein: [số g protein]g • Fat: [số g fat]g",
                "isReasonable": true hoặc false (boolean),
                "warningMessage": "chuỗi cảnh báo thông minh hoặc rỗng",
                "message": "Phân tích dinh dưỡng món ăn"
            }
            BẮT BUỘC: Trường "servingSize" phải ghi rõ định lượng cụ thể (số lượng + đơn vị + gram nếu có) tương ứng chính xác với số calo đã tính.
            Chỉ trả về đối tượng JSON, không giải thích gì thêm.`;

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

