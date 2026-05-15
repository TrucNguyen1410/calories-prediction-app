import { google } from 'googleapis';
import User from '../models/User.js';
import CalorieRecord from '../models/CalorieRecord.js';


export const syncGoogleFit = async (req, res) => {
    try {
        const { userId, accessToken } = req.body;
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: "User not found" });

        // Update token if provided
        if (accessToken) {
            user.googleAccessToken = accessToken;
            await user.save();
        }

        if (!user.googleAccessToken) {
            return res.status(400).json({ message: "No Google Access Token found" });
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

        // Extract steps and calories
        let steps = 0;
        let caloriesBurned = 0;

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

        // Save to Database (Workout entry for today)
        const dateStr = new Date().toISOString().split('T')[0];
        
        // Find if today's sync entry exists
        let workout = await CalorieRecord.findOne({ userId, date: { $regex: `^${dateStr}` }, activityType: 'Google Fit Sync' });
        
        if (workout) {
            workout.calories = caloriesBurned;
            workout.duration = (steps / 100).toFixed(0); 
            await workout.save();
        } else {
            await CalorieRecord.create({
                userId,
                activityType: 'Google Fit Sync',
                duration: (steps / 100).toFixed(0),
                calories: caloriesBurned,
                date: new Date().toISOString()
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
