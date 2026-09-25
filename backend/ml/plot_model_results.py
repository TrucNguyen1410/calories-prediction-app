"""
Sinh 2 biểu đồ minh họa cho mô hình học máy đã chọn (Gradient Boosting Regressor)
để chèn vào báo cáo KLTN (mục 3.4.1), dùng cùng dữ liệu và cách chia train/test
y hệt train_model.py để số liệu khớp đúng với Bảng 3.2.

Chạy: python plot_model_results.py
Kết quả: 2 file ảnh trong cùng thư mục ml/
  - predicted_vs_actual.png : Scatter Dự đoán vs Thực tế trên tập test
  - feature_importance.png  : Mức độ quan trọng của từng đặc trưng
"""
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_absolute_error

base_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(base_dir, "gym_members_exercise_tracking_cleaned.csv")

df = pd.read_csv(csv_path).dropna()
FEATURES = ["Age", "Weight (kg)", "Height (m)", "Session_Duration (hours)", "Avg_BPM"]
X = df[FEATURES]
y = df["Calories_Burned"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = GradientBoostingRegressor(n_estimators=200, random_state=42)
model.fit(X_train, y_train)
y_pred = model.predict(X_test)

r2 = r2_score(y_test, y_pred)
mae = mean_absolute_error(y_test, y_pred)
print(f"Gradient Boosting trên tập test: R² = {r2:.4f}, MAE = {mae:.2f} kcal")

# ===== Biểu đồ 1: Dự đoán vs Thực tế =====
plt.figure(figsize=(6.5, 6))
plt.scatter(y_test, y_pred, alpha=0.5, s=18, color="#8A2BE2", edgecolors="none")
lims = [min(y_test.min(), y_pred.min()), max(y_test.max(), y_pred.max())]
plt.plot(lims, lims, "--", color="#4B0082", linewidth=1.5, label="Dự đoán = Thực tế")
plt.xlabel("Số calo thực tế (kcal)")
plt.ylabel("Số calo dự đoán (kcal)")
plt.title(f"Gradient Boosting: Dự đoán vs Thực tế trên tập kiểm tra (R² = {r2:.4f})")
plt.legend()
plt.tight_layout()
out1 = os.path.join(base_dir, "predicted_vs_actual.png")
plt.savefig(out1, dpi=150)
print(f"Đã lưu: {out1}")

# ===== Biểu đồ 2: Mức độ quan trọng của đặc trưng =====
importances = pd.Series(model.feature_importances_, index=FEATURES).sort_values(ascending=True)
plt.figure(figsize=(7, 4.5))
plt.barh(importances.index, importances.values, color="#8A2BE2")
plt.xlabel("Mức độ quan trọng (feature importance)")
plt.title("Mức độ ảnh hưởng của từng đặc trưng đầu vào\n(mô hình Gradient Boosting Regressor)")
plt.tight_layout()
out2 = os.path.join(base_dir, "feature_importance.png")
plt.savefig(out2, dpi=150)
print(f"Đã lưu: {out2}")
