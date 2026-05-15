# KẾ HOẠCH KỸ NĂNG VÀ CÔNG NGHỆ (SKILLS & TECH STACK - V3 COMPLETE)

**Đề tài:** Hệ thống Quản lý Sức khỏe Thông minh tích hợp AI & Tự động hóa Dữ liệu (Google Fit API)
**Người thực hiện:** Nguyễn Lê Anh Trúc
**Mục tiêu:** Khóa luận tốt nghiệp

---

## 1. UI/UX & Data Visualization (Trực quan hóa dữ liệu)
- [cite_start]**Advanced Dashboard Architecture:** Xây dựng Dashboard theo phong cách Bento Grid, tối ưu hóa phân cấp thị giác trên Web.
- **Complex Charting:** Sử dụng thư viện `fl_chart` để triển khai Line Chart (biểu đồ đường) và Bar Chart (biểu đồ cột) đa biến, giúp người dùng phân tích xu hướng sức khỏe dài hạn.
- [cite_start]**Responsive Design:** Đảm bảo hệ thống lưới (Grid system) tự động co giãn linh hoạt giữa Laptop (3 cột) và Mobile (1 cột)[cite: 2181].

## 2. AI & Cloud Automation (Trí tuệ nhân tạo & Tự động hóa)
- **Groq/Gemini Integration:** Tận dụng LLM API để xây dựng trợ lý sức khỏe thời gian thực, hỗ trợ bóc tách Calo từ ngôn ngữ tự nhiên (NLP).
- [cite_start]**Google Fit API Integration:** Triển khai luồng OAuth 2.0 để đồng bộ hóa dữ liệu vận động thực tế từ thiết bị người dùng về hệ thống[cite: 3062].
- [cite_start]**Automated Prediction:** Kế thừa mô hình Hồi quy tuyến tính (Python) để dự đoán calo dựa trên dữ liệu vận động "sạch" được kéo về từ Cloud[cite: 1711, 2461].

## 3. Backend & Security (Hệ thống & Bảo mật)
- [cite_start]**Node.js/Express:** Xây dựng hệ thống RESTful API chịu tải tốt cho việc đồng bộ dữ liệu liên tục[cite: 2191].
- [cite_start]**MongoDB NoSQL:** Thiết kế Schema linh hoạt để lưu trữ dữ liệu Health-track phức tạp từ nhiều nguồn (Manual + API)[cite: 2193, 2446].
- [cite_start]**JWT & OAuth Security:** Đảm bảo an toàn dữ liệu sức khỏe cá nhân thông qua cơ chế mã hóa Token và xác thực đa lớp[cite: 1867].