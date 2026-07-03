import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error
import joblib
import os

# === 1️⃣ Đường dẫn file ===
base_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(base_dir, "gym_members_exercise_tracking_cleaned.csv")

print(f"🔍 Đang đọc dữ liệu từ: {csv_path}")

# === 2️⃣ Đọc file CSV đã được làm sạch sẵn ===
df = pd.read_csv(csv_path)
df = df.dropna()

print("✅ Đã đọc dữ liệu, các cột gồm:")
print(df.columns.tolist())

# === 3️⃣ Chọn cột đặc trưng và cột mục tiêu ===
FEATURES = ["Age", "Weight (kg)", "Height (m)", "Session_Duration (hours)", "Avg_BPM"]
X = df[FEATURES]
y = df["Calories_Burned"]

# === 4️⃣ Chia tập train/test để đánh giá khách quan ===
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# === 5️⃣ Huấn luyện mô hình trên tập train ===
model = LinearRegression()
model.fit(X_train, y_train)

# === 6️⃣ Đánh giá trên tập test ===
y_pred = model.predict(X_test)
r2 = r2_score(y_test, y_pred)
mae = mean_absolute_error(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))

print("\n📊 KẾT QUẢ ĐÁNH GIÁ MÔ HÌNH (trên tập test 20%):")
print(f"   • R²   (hệ số xác định): {r2:.4f}")
print(f"   • MAE  (sai số tuyệt đối TB): {mae:.2f} kcal")
print(f"   • RMSE (căn sai số bình phương TB): {rmse:.2f} kcal")

# === 7️⃣ Huấn luyện lại trên TOÀN BỘ dữ liệu rồi lưu để dùng thực tế ===
final_model = LinearRegression()
final_model.fit(X, y)
model_path = os.path.join(base_dir, "model.pkl")
joblib.dump(final_model, model_path)
print(f"\n✅ Mô hình đã được huấn luyện lại trên toàn bộ dữ liệu và lưu tại: {model_path}")

# === 8️⃣ Dự đoán thử ===
sample = pd.DataFrame(
    [[20, 49, 1.59, 45 / 60, 102]], columns=FEATURES
)  # Tuổi, cân nặng, cao (m), thời gian (giờ), nhịp tim
pred = final_model.predict(sample)[0]
print(f"🔥 Dự đoán thử (tuổi=20, 49kg, 159cm, 45 phút, 102 BPM): {pred:.2f} kcal")
print("🎯 Huấn luyện hoàn tất thành công!")
