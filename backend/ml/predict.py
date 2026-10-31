import sys, json, os

# Đường dẫn tới mô hình đã huấn luyện
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "model.pkl")
CSV_PATH = os.path.join(BASE_DIR, "gym_members_exercise_tracking_cleaned.csv")
FEATURES = ["Age", "Weight (kg)", "Height (m)", "Session_Duration (hours)", "Avg_BPM"]


def _retrain_and_save():
    """
    File model.pkl được lưu (pickle) bằng một phiên bản scikit-learn cụ thể;
    khi môi trường triển khai (Render) cài một phiên bản scikit-learn khác tại
    thời điểm build (requirements.txt không ghim phiên bản), joblib.load() có
    thể lỗi "ModuleNotFoundError" do cấu trúc nội bộ của scikit-learn đã đổi
    giữa các phiên bản — không phải lỗi dữ liệu hay logic.
    Thay vì chỉ lặng lẽ fallback sang công thức MET mãi mãi, tự huấn luyện lại
    model ngay bằng scikit-learn đang có trong môi trường hiện tại rồi lưu đè
    — model.pkl luôn tự "chữa lành", tương thích với đúng môi trường đang chạy.
    """
    import pandas as pd
    import numpy as np
    import joblib
    from sklearn.linear_model import LinearRegression
    from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import r2_score

    df = pd.read_csv(CSV_PATH).dropna()
    X = df[FEATURES]
    y = df["Calories_Burned"]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    candidates = {
        "LinearRegression": LinearRegression(),
        "RandomForest": RandomForestRegressor(n_estimators=200, random_state=42),
        "GradientBoosting": GradientBoostingRegressor(n_estimators=200, random_state=42),
    }
    best_name, best_model, best_r2 = None, None, -1e9
    for name, model in candidates.items():
        model.fit(X_train, y_train)
        r2 = r2_score(y_test, model.predict(X_test))
        if r2 > best_r2:
            best_name, best_model, best_r2 = name, model, r2

    best_model.fit(X, y)
    joblib.dump(best_model, MODEL_PATH)
    print(f"[predict] Da tu dong huan luyen lai va luu model.pkl ({best_name}, R2={best_r2:.4f})", file=sys.stderr)
    return best_model


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


# Bộ dữ liệu huấn luyện chỉ có Session_Duration từ 0.5h (30 phút) tới 2.0h
# (120 phút) — xem get_training_duration_range()/EDA. Model cây (Gradient
# Boosting) không ngoại suy tốt ngoài khoảng đã huấn luyện: nhiều giá trị
# duration nhỏ hơn 30 phút rơi vào cùng 1 "lá" của cây và ra cùng 1 con số,
# khiến vd. 10/20/30 phút đều ra y hệt calo — không phản ánh đúng thực tế.
# Vì vậy với buổi tập dưới mốc tối thiểu đã huấn luyện, chủ động dùng công
# thức MET (vẫn tỉ lệ thuận với thời lượng) thay vì để model ngoại suy sai.
MIN_TRAINED_DURATION_MINUTES = 30


def predict_calories(weight, height, age, duration, heart_rate, activity_type):
    """
    Dự đoán calo tiêu hao.
    Ưu tiên mô hình Gradient Boosting Regressor (model.pkl) đã huấn luyện trên bộ
    dữ liệu gym_members_exercise_tracking với các đặc trưng:
        [Age, Weight (kg), Height (m), Session_Duration (hours), Avg_BPM]
    Dùng công thức MET khi: không nạp được mô hình (thiếu thư viện/file), hoặc
    thời lượng nằm ngoài khoảng đã huấn luyện (< 30 phút).
    """
    if duration < MIN_TRAINED_DURATION_MINUTES:
        return met_fallback(weight, duration, activity_type), "met_fallback_short_duration"

    try:
        import warnings
        warnings.filterwarnings("ignore")
        import joblib
        import numpy as np

        try:
            model = joblib.load(MODEL_PATH)
        except Exception as load_err:
            print(f"[predict] model.pkl khong tuong thich ({load_err}), tu huan luyen lai...", file=sys.stderr)
            model = _retrain_and_save()

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
