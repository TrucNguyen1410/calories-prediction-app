class Workout {
  final String? id;
  final String activityType; // Loại bài tập (VD: Chạy bộ, Đạp xe)
  final double weight;       // Cân nặng (kg)
  final double height;       // Chiều cao (cm)
  final int age;             // Tuổi
  final int duration;        // Thời gian tập luyện (phút)
  final int heartRate;       // Nhịp tim trung bình
  final double calories;     // Lượng calo tiêu hao
  final String date;         // Ngày tập luyện

  Workout({
    this.id,
    required this.activityType,
    required this.weight,
    required this.height,
    required this.age,
    required this.duration,
    required this.heartRate,
    required this.calories,
    required this.date,
  });

  // Parse từ JSON (MongoDB -> Flutter)
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['_id'] ?? '',
      activityType: json['activityType'] ?? 'Không xác định',
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      age: json['age'] ?? 0,
      duration: json['duration'] ?? 0,
      heartRate: json['heartRate'] ?? json['heart_rate'] ?? 0,
      calories: (json['calories'] ?? 0).toDouble(),
      date: json['date'] ?? '',
    );
  }

  // Chuyển thành JSON (Flutter -> MongoDB)
  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "activityType": activityType,
      "weight": weight,
      "height": height,
      "age": age,
      "duration": duration,
      "heartRate": heartRate,
      "calories": calories,
      "date": date,
    };
  }
}
