# Tài liệu API — HealthAI Backend

**Base URL (local):** `http://localhost:3000/api`
**Base URL (production):** `https://calo-backend-api.onrender.com/api`

**Xác thực:** Hầu hết endpoint yêu cầu header `Authorization: Bearer <JWT>`.
Token nhận được sau khi đăng nhập, hết hạn sau 7 ngày.

**Định dạng phản hồi chung:**
```json
{ "success": true, "data": { ... }, "message": "..." }
```

---

## 1. Auth — `/api/auth`

| Method | Endpoint | Auth | Mô tả | Body |
|--------|----------|:----:|-------|------|
| POST | `/register` | ❌ | Đăng ký tài khoản | `{ name, email, password, gender, birthdate }` |
| POST | `/login` | ❌ | Đăng nhập (trả JWT + user) | `{ email, password }` |
| PUT | `/profile/:id` | ❌* | Cập nhật hồ sơ (tên/chiều cao/cân nặng/giới tính/tuổi/mục tiêu/mức vận động/onboarded) | `{ name?, height?, weight?, gender?, age?, goal?, activityLevel?, onboarded? }` |
| POST | `/change-password` | ❌* | Đổi mật khẩu | `{ userId, oldPassword, newPassword }` |
| POST | `/forgot-password` | ❌ | Gửi mã OTP đặt lại mật khẩu qua email | `{ email }` |
| POST | `/reset-password` | ❌ | Đặt lại mật khẩu bằng OTP | `{ email, otp, newPassword }` |
| DELETE | `/account` | 🔒 | Xóa tài khoản & toàn bộ dữ liệu liên quan | — |
| POST | `/google-sync` | ❌* | Đồng bộ Google Fit (steps, calo) | `{ userId, accessToken, refreshToken? }` |

> `goal` ∈ `lose | maintain | gain`; `activityLevel` ∈ `sedentary | light | moderate | active | very_active`. Dùng để tính **mục tiêu calo nạp/ngày (TDEE)** cá nhân hóa.

> *Các route này hiện xác thực dựa trên `userId`/token Google trong body. Có giới hạn tần suất (rate limit) cho `/register` và `/login`.

**Ví dụ login response:**
```json
{ "token": "eyJhbGci...", "user": { "id": "...", "name": "...", "email": "...", "height": 170, "weight": 65 } }
```

---

## 2. AI — `/api/ai` 🔒 (yêu cầu JWT + rate limit 20 req/phút)

| Method | Endpoint | Mô tả | Body |
|--------|----------|-------|------|
| POST | `/chat` | Chat với trợ lý AI (đa phiên) | `{ userId, message, sessionId? }` |
| POST | `/plan` | Sinh thực đơn 7 ngày cá nhân hóa | `{ userId, userInput? }` |
| POST | `/ahp-suggestion` | Gợi ý cường độ tập (AHP) | `{ userId, sleepHours, stressLevel }` |
| POST | `/analyze-food` | Phân tích calo từ text/ảnh | `multipart: { text?, image?, targetCalories?, todayIntake?, remainingCalories? }` |
| GET | `/sessions?userId=` | Danh sách phiên chat | — |
| GET | `/sessions/:sessionId` | Chi tiết phiên chat | — |
| POST | `/sessions` | Tạo phiên chat mới | `{ userId }` |
| DELETE | `/sessions/:sessionId` | Xóa phiên chat | — |

**Đặc biệt:** khi người dùng mô tả một buổi tập, `/chat` có thể trả về JSON hành động:
```json
{ "action": "LOG_WORKOUT", "activityName": "Chạy bộ", "duration": 30, "caloriesBurned": 320, "message": "..." }
```

---

## 3. Calories / Vận động — `/api/calories` 🔒

| Method | Endpoint | Mô tả | Body |
|--------|----------|-------|------|
| POST | `/predict` | Dự đoán calo bằng ML (có validation khoảng giá trị) | `{ activityType, weight, height, age, duration, heartRate }` |
| GET | `/history` | Lịch sử tập luyện của người dùng | — |
| POST | `/add` | Ghi trực tiếp một hoạt động (từ chatbot) | `{ activityName, duration, caloriesBurned }` |

**Predict response:** `{ "success": true, "calories": 488.3 }`

---

## 4. Meals — `/api/meals` 🔒

| Method | Endpoint | Mô tả | Body |
|--------|----------|-------|------|
| POST | `/` | Thêm bữa ăn | `{ name, calories, mealType, date, imageUrl?, servingSize? }` |
| GET | `/?date=YYYY-MM-DD` | Lấy bữa ăn (theo ngày hoặc toàn bộ) | — |
| DELETE | `/:mealId` | Xóa bữa ăn | — |

---

## 5. Health Records — `/api/records` 🔒

| Method | Endpoint | Mô tả | Body |
|--------|----------|-------|------|
| POST | `/weight` | Ghi nhận số đo cân nặng (tự tính BMI, đồng bộ hồ sơ) | `{ weight, height?, note? }` |
| GET | `/weight?limit=100` | Lịch sử cân nặng/BMI (mới nhất trước) | — |
| DELETE | `/weight/:id` | Xóa một bản ghi | — |
| POST | `/water` | Ghi thêm lượng nước uống (ml) | `{ amountMl, date? }` |
| GET | `/water?date=YYYY-MM-DD` | Tổng nước uống trong ngày | — |
| DELETE | `/water/last` | Hoàn tác lần ghi nước gần nhất | — |

---

## 5b. Keep-alive — `GET /health` (không cần auth)

Trả về trạng thái server (uptime, kết nối DB) — dùng cho cron ping chống Render free ngủ đông:
```json
{ "status": "ok", "uptime": 123.4, "db": "connected", "time": "..." }
```

**Weight record item:**
```json
{ "_id": "...", "weight": 64.5, "height": 170, "bmi": 22.3, "bmiStatus": "Bình thường", "date": "2026-07-03T..." }
```

---

## 6. Feedback — `/api/feedback` 🔒

| Method | Endpoint | Mô tả | Body |
|--------|----------|-------|------|
| POST | `/submit` | Gửi góp ý (lưu DB + gửi email qua Resend) | `{ content }` |

---

## Mã lỗi thường gặp

| HTTP | Ý nghĩa |
|------|---------|
| 400 | Dữ liệu đầu vào không hợp lệ (validation) |
| 401 | Thiếu / sai / hết hạn token |
| 403 | Không có quyền với tài nguyên |
| 404 | Không tìm thấy tài nguyên |
| 429 | Vượt giới hạn tần suất (rate limit) |
| 500 | Lỗi máy chủ nội bộ |
