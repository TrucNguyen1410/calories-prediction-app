import sys, json

def predict_calories(weight, height, age, duration, heart_rate, activity_type):
    try:
        # MET values – hệ số năng lượng cho từng hoạt động
        met_values = {
            "Gym": 8.0,
            "Chạy bộ": 9.8,
            "Đạp xe": 7.5,
            "Bơi lội": 6.0,
            "Yoga": 3.5,
            "Đi bộ nhanh": 3.8,
            "Leo núi": 10.0
        }

        met = met_values.get(activity_type, 6.0)  # nếu không có -> mặc định 6
        calories = met * weight * duration / 60
        return round(calories, 2)

    except Exception as e:
        return None

if __name__ == "__main__":
    try:
        args = sys.argv[1:]
        if len(args) < 6:
            print(json.dumps({"success": False, "message": "Thiếu tham số đầu vào"}))
            sys.exit(1)

        weight = float(args[0])
        height = float(args[1])
        age = int(args[2])
        duration = int(args[3])
        heart_rate = int(args[4])
        activity_type = args[5]

        calories = predict_calories(weight, height, age, duration, heart_rate, activity_type)

        if calories is not None:
            print(json.dumps({"success": True, "calories": calories}))
        else:
            print(json.dumps({"success": False, "message": "Không tính được lượng calo"}))
    except Exception as e:
        print(json.dumps({"success": False, "error": str(e)}))
