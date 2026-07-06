"""
Kiểm thử đơn vị cho module dự đoán calo (predict.py).
Chạy: python -m unittest ml/test_predict.py   (từ thư mục backend)
hoặc:  python -m unittest discover -s ml -p "test_*.py"
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from predict import predict_calories, met_fallback


class TestPredict(unittest.TestCase):
    def test_met_fallback_positive(self):
        """Công thức MET phải trả về giá trị dương hợp lý."""
        cal = met_fallback(weight=70, duration=60, activity_type="Chạy bộ")
        self.assertGreater(cal, 0)
        # MET Chạy bộ = 9.8 -> 9.8 * 70 * 60 / 60 = 686
        self.assertAlmostEqual(cal, 686.0, places=1)

    def test_met_fallback_unknown_activity(self):
        """Hoạt động không xác định dùng MET mặc định 6.0."""
        cal = met_fallback(weight=60, duration=30, activity_type="Nhảy dây XYZ")
        self.assertAlmostEqual(cal, 6.0 * 60 * 30 / 60, places=1)

    def test_predict_returns_positive(self):
        """predict_calories trả về (calo dương, nguồn hợp lệ)."""
        calories, source = predict_calories(
            weight=65, height=170, age=25, duration=45, heart_rate=130, activity_type="Gym"
        )
        self.assertIsNotNone(calories)
        self.assertGreater(calories, 0)
        self.assertIn(source, ("ml_model", "met_fallback"))

    def test_predict_reasonable_range(self):
        """Kết quả dự đoán nằm trong khoảng calo hợp lý cho 1 buổi tập."""
        calories, _ = predict_calories(
            weight=70, height=175, age=30, duration=60, heart_rate=140, activity_type="Chạy bộ"
        )
        self.assertGreater(calories, 50)
        self.assertLess(calories, 5000)


if __name__ == "__main__":
    unittest.main()
