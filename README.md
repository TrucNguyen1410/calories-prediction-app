# HealthAI — Hệ thống Quản lý Sức khỏe Thông minh tích hợp AI & Google Fit

> **Khóa luận tốt nghiệp** — Người thực hiện: **Nguyễn Lê Anh Trúc**

Ứng dụng đa nền tảng (Mobile + Web) giúp người dùng **theo dõi dinh dưỡng, vận động và các chỉ số sức khỏe**, kết hợp **trợ lý AI hội thoại**, **mô hình học máy dự đoán calo**, và **đồng bộ dữ liệu vận động thực tế từ Google Fit**.

---

## 1. Tính năng chính

| Nhóm | Tính năng |
|------|-----------|
| 🔐 **Tài khoản** | Đăng ký / đăng nhập JWT, đăng nhập Google (OAuth 2.0), đổi mật khẩu, cập nhật hồ sơ sinh thể |
| 🤖 **Trợ lý AI** | Chatbot sức khỏe (Groq LLM), đa phiên hội thoại, tự động ghi nhận buổi tập từ ngôn ngữ tự nhiên, guardrails giới hạn chủ đề |
| 🍽️ **Dinh dưỡng** | Phân tích calo món ăn từ **văn bản** hoặc **ảnh** (AI Vision), sinh thực đơn 7 ngày cá nhân hóa, nhật ký bữa ăn |
| 🏃 **Vận động** | **Dự đoán calo tiêu hao bằng mô hình Hồi quy tuyến tính (ML)**, lịch sử tập luyện, đồng bộ Google Fit (số bước, calo) |
| 📊 **Theo dõi** | Dashboard Bento Grid, biểu đồ dinh dưỡng/cân nặng/BMI 7 ngày, **hồ sơ sức khỏe với lịch sử cân nặng & BMI thật** |
| 🎨 **Trải nghiệm** | Responsive (mobile/tablet/desktop), Dark Mode, hướng dẫn tương tác (coach mark) |

---

## 2. Kiến trúc hệ thống

```
┌──────────────────────┐        REST/JSON (JWT)        ┌───────────────────────────┐
│   Flutter Frontend    │  ───────────────────────────▶ │   Node.js / Express API    │
│  (Mobile + Web)       │                                │   (backend/)               │
│  - Riverpod state     │ ◀───────────────────────────  │   - Auth, Meals, AI,       │
│  - fl_chart           │                                │     Calories, Records      │
└──────────┬────────────┘                                └───────┬───────────┬────────┘
           │                                                     │           │
           │ Google Sign-In (OAuth2)                             │           │ child_process
           ▼                                                     ▼           ▼
   ┌────────────────┐                                   ┌──────────────┐  ┌──────────────────┐
   │  Google Fit    │                                   │  MongoDB     │  │  Python ML       │
   │  API           │                                   │  Atlas       │  │  (scikit-learn)  │
   └────────────────┘                                   └──────────────┘  └──────────────────┘
                                                                              │
                                                              Groq LLM API ◀──┘ (chat, vision, meal plan)
```

## 3. Công nghệ sử dụng

**Frontend:** Flutter 3.9+, Riverpod, fl_chart, google_sign_in, google_fonts, intl
**Backend:** Node.js (ESM), Express, Mongoose (MongoDB Atlas), JWT, bcryptjs, multer, Groq SDK, googleapis, Resend (email)
**Machine Learning:** Python 3.9+, scikit-learn (LinearRegression), pandas, numpy, joblib
**Hạ tầng:** Docker (image `python-nodejs`), Render (backend), Vercel (web), MongoDB Atlas (cloud DB)

---

## 4. Mô-đun Học máy (ML)

- **Dữ liệu:** `gym_members_exercise_tracking_cleaned.csv`
- **Đặc trưng đầu vào:** `Age, Weight (kg), Height (m), Session_Duration (hours), Avg_BPM`
- **Mục tiêu:** `Calories_Burned`
- **Mô hình:** Hồi quy tuyến tính (`LinearRegression`)
- **Kết quả đánh giá (tập test 20%):** **R² ≈ 0.97**, **MAE ≈ 39.8 kcal**, **RMSE ≈ 50.2 kcal**
- Khi không nạp được mô hình, hệ thống tự động **fallback sang công thức MET** để đảm bảo tính liên tục.

Huấn luyện lại mô hình:
```bash
cd backend && npm run train      # hoặc: python ml/train_model.py
```

---

## 5. Cài đặt & Chạy dự án

### 5.1. Backend (Node.js + Python)
```bash
cd backend
npm install
pip install -r requirements.txt          # cho mô-đun ML
cp .env.example .env                      # rồi điền các biến môi trường
npm run dev                               # hoặc: npm start
```
Server chạy tại `http://localhost:3000`.

### 5.2. Frontend (Flutter)
```bash
flutter pub get
flutter run                               # mobile
flutter run -d chrome                     # web
```
> Frontend tự động dùng `http://127.0.0.1:3000/api` khi chạy local và URL Render khi chạy production (xem `lib/services/api_service.dart`).

---

## 6. Kiểm thử (Testing)

```bash
# Backend — unit test cho tính toán sức khỏe & validation (Node built-in runner)
cd backend && npm test

# Backend — unit test cho mô-đun ML (Python unittest)
cd backend && npm run test:ml

# Frontend — test model & logic
flutter test
```

---

## 7. Bảo mật

- Mật khẩu băm bằng **bcrypt** (pre-save hook).
- Xác thực **JWT** (hết hạn 7 ngày) qua middleware dùng chung `middleware/authMiddleware.js`.
- **Toàn bộ** route `/api/ai/*`, `/api/records/*`, `/api/meals/*`, `/api/calories/*`, `/api/feedback/*` đều được bảo vệ.
- **Rate limiting** in-memory chống lạm dụng quota LLM và dò mật khẩu.
- **Validation** đầu vào (email, mật khẩu, khoảng giá trị chỉ số cơ thể).
- Bí mật lưu trong `.env` (không commit).

---

## 8. Tài liệu liên quan

- 📘 [Tài liệu API](docs/API.md)
- 🚀 [Hướng dẫn triển khai (Deployment)](docs/DEPLOYMENT.md)

---

## 9. Cấu trúc thư mục

```
do_an_tot_nghiep/
├── lib/                    # Mã nguồn Flutter (screens, providers, services, models)
├── backend/
│   ├── controllers/        # Xử lý nghiệp vụ (AI, auth, calorie, googleFit)
│   ├── routes/             # Định tuyến REST API
│   ├── models/             # Schema Mongoose
│   ├── middleware/         # auth, rateLimit, validate
│   ├── utils/              # health.js (BMI/BMR/TDEE)
│   ├── ml/                 # predict.py, train_model.py, model.pkl, dataset
│   ├── tests/              # Unit test (Node)
│   └── server.js           # Điểm khởi động
├── docs/                   # Tài liệu API & triển khai
└── test/                   # Unit test (Flutter)
```
