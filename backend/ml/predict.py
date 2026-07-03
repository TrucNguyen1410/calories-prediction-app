import sys, json, os

# Đường dẫn tới mô hình đã huấn luyện (LinearRegression)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "model.pkl")


def met_fallback(weight, duration, activity_type):
    """Ước lượng calo bằng công thức MET khi không dùng được mô hình ML."""
    met_values = {
        "Gym": 8.0,
        "Chạy bộ": 9.8,
        "Đạp xe": 7.5,
        "Bơi lội": 6.0,
        "Yoga": 3.5,
        "Đi bộ nhanh": 3.8,
        "Leo núi": 10.0,
    }
    met = met_values.get(activity_type, 6.0)
    return round(met * weight * duration / 60, 2)


def predict_calories(weight, height, age, duration, heart_rate, activity_type):
    """
    Dự đoán calo tiêu hao.
    Ưu tiên mô hình Hồi quy tuyến tính (model.pkl) đã huấn luyện trên bộ dữ liệu
    gym_members_exercise_tracking với các đặc trưng:
        [Age, Weight (kg), Height (m), Session_Duration (hours), Avg_BPM]
    Nếu không nạp được mô hình (thiếu thư viện / thiếu file), tự động dùng công thức MET.
    """
    try:
        import warnings
        warnings.filterwarnings("ignore")
        import joblib
        import numpy as np

        model = joblib.load(MODEL_PATH)

        # Chuẩn hóa đơn vị đầu vào cho khớp lúc huấn luyện
        height_m = height / 100.0 if height > 3 else height  # cm -> m
        duration_hours = duration / 60.0                     # phút -> giờ

        features = np.array([[age, weight, height_m, duration_hours, heart_rate]], dtype=float)
        pred = float(model.predict(features)[0])

        # Chặn giá trị âm/bất thường; nếu vô lý thì fallback MET
        if pred <= 0 or pred > 5000:
            return met_fallback(weight, duration, activity_type), "met_fallback"
        return round(pred, 2), "ml_model"
    except Exception as e:
        # Ghi cảnh báo ra stderr (chỉ để log), giữ stdout sạch cho JSON
        print(f"[predict] Model unavailable, using MET fallback: {e}", file=sys.stderr)
        return met_fallback(weight, duration, activity_type), "met_fallback"


if __name__ == "__main__":
    try:
        args = sys.argv[1:]
        if len(args) < 6:
            print(json.dumps({"success": False, "message": "Thiếu tham số đầu vào"}))
            sys.exit(1)

        weight = float(args[0])
        height = float(args[1])
        age = int(float(args[2]))
        duration = int(float(args[3]))
        heart_rate = int(float(args[4]))
        activity_type = args[5]

        calories, source = predict_calories(
            weight, height, age, duration, heart_rate, activity_type
        )

        if calories is not None:
            print(json.dumps({"success": True, "calories": calories, "source": source}))
        else:
            print(json.dumps({"success": False, "message": "Không tính được lượng calo"}))
    except Exception as e:
        print(json.dumps({"success": False, "error": str(e)}))
