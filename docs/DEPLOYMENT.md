# Hướng dẫn triển khai (Deployment)

Hệ thống gồm 3 phần được triển khai độc lập: **Backend (Render)**, **Frontend Web (Vercel)**, **Database (MongoDB Atlas)**.

---

## 1. MongoDB Atlas (Cơ sở dữ liệu)

1. Tạo cluster miễn phí tại [mongodb.com/atlas](https://www.mongodb.com/atlas).
2. Tạo Database User + whitelist IP (`0.0.0.0/0` cho môi trường học tập).
3. Lấy connection string dạng `mongodb+srv://<user>:<pass>@cluster.../<db>` → dùng cho biến `MONGODB_URI`.

---

## 2. Backend trên Render

Backend dùng **Docker** (image `nikolaik/python-nodejs` — có sẵn cả Node.js lẫn Python cho mô-đun ML).

1. Tạo **Web Service** mới trên [render.com](https://render.com), kết nối repo GitHub.
2. Root Directory: `backend/` — Render tự phát hiện `Dockerfile`.
3. Khai báo **Environment Variables** (xem `backend/.env.example`):

   | Biến | Mô tả |
   |------|-------|
   | `PORT` | Cổng (Render tự cấp; mặc định 3000) |
   | `MONGODB_URI` | Chuỗi kết nối MongoDB Atlas |
   | `JWT_SECRET` | Khóa bí mật ký JWT (đặt chuỗi ngẫu nhiên mạnh) |
   | `GROQ_API_KEY` | API key Groq cho LLM |
   | `RESEND_API_KEY` | API key Resend để gửi email góp ý |
   | `FEEDBACK_RECIPIENT` | Email nhận góp ý (tùy chọn) |

4. Deploy. Mỗi lần `git push` lên nhánh `main` → Render **tự động build & deploy lại**.
5. Kiểm tra: truy cập URL gốc thấy `🔥 API Health Assistant đang chạy...`.

> Dockerfile đã `pip install -r requirements.txt` nên `model.pkl` (scikit-learn) hoạt động trên production.

---

## 3. Frontend Web trên Vercel

`vercel.json` cấu hình clone Flutter SDK và build web.

1. Import repo vào [vercel.com](https://vercel.com).
2. Vercel đọc `vercel.json` để build (`flutter build web`).
3. Frontend tự chuyển sang gọi URL backend Render khi chạy trên domain production (logic trong `lib/services/api_service.dart`).
4. Mỗi `git push` → Vercel tự deploy lại.

---

## 4. Google Fit / Google Sign-In

1. Tạo project trên [Google Cloud Console](https://console.cloud.google.com).
2. Bật **Fitness API**.
3. Tạo OAuth Client ID (Web + Android), cấu hình màn hình đồng thuận với scope:
   - `fitness.activity.read`, `fitness.body.read`
4. Cập nhật Client ID trong `lib/screens/login_screen.dart`.

---

## 5. Quy trình phát hành

```bash
# 1. Chạy test trước khi phát hành
cd backend && npm test && npm run test:ml
cd .. && flutter test

# 2. Commit & push -> tự động deploy
git add -A
git commit -m "..."
git push origin main
```

- **Render** build backend từ `Dockerfile` (~2-4 phút).
- **Vercel** build web (~2-3 phút).
- Theo dõi log deploy trên dashboard tương ứng.
