import { google } from 'googleapis';
import User from '../models/User.js';
import CalorieRecord from '../models/CalorieRecord.js';

// Lưu số bước/calo hôm nay vào một CalorieRecord "Sync" duy nhất (dùng chung cho
// cả Google Fit và Health Connect — activityType phân biệt nguồn dữ liệu).
async function upsertTodaySyncRecord({ userId, steps, caloriesBurned, activityType }) {
    const dateStr = new Date().toISOString().split('T')[0];
    let workout = await CalorieRecord.findOne({ userId, date: { $regex: `^${dateStr}` }, activityType });

    if (workout) {
        workout.calories = caloriesBurned;
        workout.duration = (steps / 100).toFixed(0);
        workout.date = new Date().toISOString();
        await workout.save();
    } else {
        await CalorieRecord.create({
            userId,
            activityType,
            duration: (steps / 100).toFixed(0),
            calories: caloriesBurned,
            date: new Date().toISOString(),
        });
    }
}


export const syncGoogleFit = async (req, res) => {
    try {
        const { userId, accessToken, refreshToken } = req.body;
        console.log("👉 GOOGLE-SYNC REQUEST RECEIVED. userId:", userId);
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: "User not found" });

        // Cập nhật token nếu client gửi lên (access token mới mỗi lần đăng nhập)
        if (accessToken) {
            user.googleAccessToken = accessToken;
        }
        // Lưu refresh token nếu có để googleapis tự động làm mới access token khi hết hạn
        if (refreshToken) {
            user.googleRefreshToken = refreshToken;
        }
        if (accessToken || refreshToken) {
            await user.save();
        }

        if (!user.googleAccessToken && !user.googleRefreshToken) {
            return res.status(401).json({
                success: false,
                message: "Không tìm thấy Google Access Token. Phiên kết nối hết hạn hoặc chưa liên kết Google Fit. Vui lòng Đăng xuất và Đăng nhập lại bằng Google để cấp quyền."
            });
        }

        const oauth2Client = new google.auth.OAuth2();
        // Truyền cả refresh_token (nếu có) để thư viện tự động refresh khi access_token hết hạn
        const credentials = { access_token: user.googleAccessToken };
        if (user.googleRefreshToken) {
            credentials.refresh_token = user.googleRefreshToken;
        }
        oauth2Client.setCredentials(credentials);

        // Khi thư viện tự refresh, lưu lại access token mới vào DB
        oauth2Client.on("tokens", async (tokens) => {
            try {
                if (tokens.access_token) {
                    user.googleAccessToken = tokens.access_token;
                    await user.save();
                    console.log("🔄 Google access token đã được tự động làm mới.");
                }
            } catch (e) {
                console.error("Lỗi lưu token mới:", e.message);
            }
        });

        const fitness = google.fitness({
            version: 'v1',
            auth: oauth2Client
        });

        // Fetch aggregate data for the last 24 hours
        const now = new Date();
        const startOfDay = new Date(now.setHours(0, 0, 0, 0)).getTime();
        const endOfDay = new Date(now.setHours(23, 59, 59, 999)).getTime();

        let steps = 0;
        let caloriesBurned = 0;

        try {
            const response = await fitness.users.dataset.aggregate({
                userId: 'me',
                requestBody: {
                    aggregateBy: [
                        { dataTypeName: 'com.google.step_count.delta' },
                        { dataTypeName: 'com.google.calories.expended' }
                    ],
                    bucketByTime: { durationMillis: (endOfDay - startOfDay).toString() },
                    startTimeMillis: startOfDay.toString(),
                    endTimeMillis: endOfDay.toString()
                }
            });

            console.log("FIT DATA FROM GOOGLE:", JSON.stringify(response.data, null, 2));

            const buckets = response.data.bucket;
            if (buckets && buckets.length > 0) {
                buckets[0].dataset.forEach(ds => {
                    ds.point.forEach(point => {
                        if (point.dataTypeName === 'com.google.step_count.delta') {
                            steps += point.value[0].intVal || 0;
                        } else if (point.dataTypeName === 'com.google.calories.expended') {
                            caloriesBurned += point.value[0].fpVal || 0;
                        }
                    });
                });
            }
        } catch (apiError) {
            console.error("GOOGLE FIT API CRITICAL ERROR:", apiError.message);
            
            // Check for OAuth expiration
            if (apiError.code === 401 || apiError.message.includes("invalid authentication") || apiError.message.includes("expired")) {
                return res.status(401).json({ 
                    success: false, 
                    message: "Phiên đăng nhập Google Fit của bạn đã hết hạn. Vui lòng Đăng xuất và đăng nhập lại bằng Google để tiếp tục đồng bộ dữ liệu thật." 
                });
            }
            
            return res.status(500).json({ 
                success: false, 
                message: "Không thể lấy dữ liệu từ Google Fit: " + apiError.message 
            });
        }

        // Save to Database (Workout entry for today)
        await upsertTodaySyncRecord({ userId, steps, caloriesBurned, activityType: 'Google Fit Sync' });

        res.status(200).json({
            success: true, 
            data: { steps, caloriesBurned } 
        });

    } catch (error) {
        console.error("GOOGLE FIT SYNC ERROR:", error.message);
        if (error.code === 401) {
            return res.status(401).json({ success: false, message: "Hết hạn phiên đăng nhập Google. Vui lòng đăng nhập lại." });
        }
        res.status(500).json({ success: false, message: "Lỗi đồng bộ Google Fit: " + error.message });
    }
};

// Đồng bộ dữ liệu từ Health Connect (Android) / HealthKit (iOS) qua package `health` phía Flutter.
// Khác với Google Fit, dữ liệu được ĐỌC SẴN trên thiết bị rồi app tự đẩy số liệu lên đây —
// không cần OAuth token, dùng làm nguồn dự phòng khi Google Fit API ngưng hoạt động.
export const syncHealthConnect = async (req, res) => {
    try {
        const { userId, steps, caloriesBurned } = req.body;
        if (!userId) return res.status(400).json({ success: false, message: "Thiếu userId" });

        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ success: false, message: "Không tìm thấy người dùng" });

        const safeSteps = Number(steps) || 0;
        const safeCalories = Number(caloriesBurned) || 0;

        await upsertTodaySyncRecord({ userId, steps: safeSteps, caloriesBurned: safeCalories, activityType: 'Health Connect Sync' });

        res.status(200).json({
            success: true,
            data: { steps: safeSteps, caloriesBurned: safeCalories },
        });
    } catch (error) {
        console.error("HEALTH CONNECT SYNC ERROR:", error.message);
        res.status(500).json({ success: false, message: "Lỗi đồng bộ Health Connect: " + error.message });
    }
};
