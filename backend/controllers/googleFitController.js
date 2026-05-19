import { google } from 'googleapis';
import User from '../models/User.js';
import CalorieRecord from '../models/CalorieRecord.js';


export const syncGoogleFit = async (req, res) => {
    try {
        const { userId, accessToken } = req.body;
        console.log("👉 GOOGLE-SYNC REQUEST RECEIVED. userId:", userId, "accessToken:", accessToken);
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: "User not found" });

        // Update token if provided
        if (accessToken) {
            user.googleAccessToken = accessToken;
            await user.save();
        }

        if (!user.googleAccessToken) {
            return res.status(401).json({ 
                success: false, 
                message: "Không tìm thấy Google Access Token. Phiên kết nối hết hạn hoặc chưa liên kết Google Fit. Vui lòng Đăng xuất và Đăng nhập lại bằng Google để cấp quyền." 
            });
        }

        const oauth2Client = new google.auth.OAuth2();
        oauth2Client.setCredentials({ access_token: user.googleAccessToken });

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
        const dateStr = new Date().toISOString().split('T')[0];
        
        // Find if today's sync entry exists
        let workout = await CalorieRecord.findOne({ userId, date: { $regex: `^${dateStr}` }, activityType: 'Google Fit Sync' });
        
        if (workout) {
            workout.calories = caloriesBurned;
            workout.duration = (steps / 100).toFixed(0); 
            workout.date = new Date().toISOString(); // Bắt buộc lấy thời gian hôm nay để cập nhật
            await workout.save();
        } else {
            await CalorieRecord.create({
                userId,
                activityType: 'Google Fit Sync',
                duration: (steps / 100).toFixed(0),
                calories: caloriesBurned,
                date: new Date().toISOString() // Bắt buộc lấy thời gian hôm nay
            });
        }


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
