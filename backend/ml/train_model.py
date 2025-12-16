import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
import joblib
import os

# === 1️⃣ Đường dẫn file ===
base_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(base_dir, "gym_members_exercise_tracking_cleaned.csv")

print(f"🔍 Đang đọc dữ liệu từ: {csv_path}")

# === 2️⃣ Đọc file CSV đã được làm sạch sẵn ===
df = pd.read_csv(csv_path)

print("✅ Đã đọc dữ liệu, các cột gồm:")
print(df.columns.tolist())

# === 3️⃣ Chọn cột đặc trưng và cột mục tiêu ===
# File cleaned có các cột: ['Age', 'Weight (kg)', 'Height (m)', 'Session_Duration (hours)', 'Avg_BPM', 'Calories_Burned']
X = df[["Age", "Weight (kg)", "Height (m)", "Session_Duration (hours)", "Avg_BPM"]]
y = df["Calories_Burned"]

# === 4️⃣ Làm sạch dữ liệu nếu còn NaN (phòng hờ) ===
df = df.dropna()

# === 5️⃣ Huấn luyện mô hình ===
model = LinearRegression()
model.fit(X, y)

# === 6️⃣ Lưu mô hình ===
model_path = os.path.join(base_dir, "model.pkl")
joblib.dump(model, model_path)

print(f"✅ Mô hình đã được huấn luyện và lưu tại: {model_path}")

# === 7️⃣ Dự đoán thử ===
sample = np.array([[20, 49, 1.59, 45 / 60, 102]])  # Tuổi, cân nặng, cao (m), thời gian giờ, nhịp tim
pred = model.predict(sample)[0]

print(f"🔥 Dự đoán thử (tuổi=20, cân nặng=49kg, cao=159cm, 45 phút, 102 BPM): {pred:.2f} kcal")
print("🎯 Huấn luyện hoàn tất thành công!")
