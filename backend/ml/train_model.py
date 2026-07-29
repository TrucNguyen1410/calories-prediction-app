import pandas as pd
import numpy as np
import json
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error
import joblib
import os

# === 1. Đường dẫn ===
base_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(base_dir, "gym_members_exercise_tracking_cleaned.csv")
print(f"Đang đọc dữ liệu từ: {csv_path}")

# === 2. Đọc & làm sạch ===
df = pd.read_csv(csv_path).dropna()
FEATURES = ["Age", "Weight (kg)", "Height (m)", "Session_Duration (hours)", "Avg_BPM"]
X = df[FEATURES]
y = df["Calories_Burned"]
print("Số mẫu:", len(df))

# === 3. Chia train/test ===
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# === 4. So sánh nhiều mô hình ===
candidates = {
    "LinearRegression": LinearRegression(),
    "RandomForest": RandomForestRegressor(n_estimators=200, random_state=42),
    "GradientBoosting": GradientBoostingRegressor(n_estimators=200, random_state=42),
}

results = {}
print("\n=== SO SÁNH MÔ HÌNH (tập test 20%) ===")
print(f"{'Mô hình':<20}{'R²':>10}{'MAE (kcal)':>14}{'RMSE (kcal)':>14}")
for name, model in candidates.items():
    model.fit(X_train, y_train)
    pred = model.predict(X_test)
    r2 = r2_score(y_test, pred)
    mae = mean_absolute_error(y_test, pred)
    rmse = float(np.sqrt(mean_squared_error(y_test, pred)))
    results[name] = {"r2": round(r2, 4), "mae": round(mae, 2), "rmse": round(rmse, 2)}
    print(f"{name:<20}{r2:>10.4f}{mae:>14.2f}{rmse:>14.2f}")

# === 5. Chọn mô hình tốt nhất theo R² ===
best_name = max(results, key=lambda k: results[k]["r2"])
print(f"\n>>> Mô hình tốt nhất: {best_name} (R²={results[best_name]['r2']})")

# === 6. Huấn luyện lại mô hình tốt nhất trên TOÀN BỘ dữ liệu rồi lưu ===
best_model = candidates[best_name]
best_model.fit(X, y)
model_path = os.path.join(base_dir, "model.pkl")
joblib.dump(best_model, model_path)
print(f"Đã lưu mô hình '{best_name}' tại: {model_path}")

# === 7. Lưu bảng so sánh ra JSON để dùng cho báo cáo / tài liệu ===
metrics_path = os.path.join(base_dir, "model_metrics.json")
with open(metrics_path, "w", encoding="utf-8") as f:
    json.dump(
        {"best_model": best_name, "features": FEATURES, "test_size": 0.2, "results": results},
        f, ensure_ascii=False, indent=2,
    )
print(f"Đã lưu bảng đánh giá tại: {metrics_path}")

# === 8. Dự đoán thử ===
sample = pd.DataFrame([[20, 49, 1.59, 45 / 60, 102]], columns=FEATURES)
print(f"Dự đoán thử (20t, 49kg, 159cm, 45 phút, 102 BPM): {best_model.predict(sample)[0]:.2f} kcal")
print("Huấn luyện & so sánh hoàn tất!")
