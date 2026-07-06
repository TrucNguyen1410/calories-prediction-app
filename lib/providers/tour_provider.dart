import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TourKeys {
  final GlobalKey bmiKey = GlobalKey();
  final GlobalKey stepsKey = GlobalKey();
  final GlobalKey waterKey = GlobalKey();
  final GlobalKey aiDiaryKey = GlobalKey();
  final GlobalKey aiWorkoutKey = GlobalKey();
  final GlobalKey chatbotKey = GlobalKey();
  final GlobalKey menuTabKey = GlobalKey();
  final GlobalKey statsTabKey = GlobalKey();
  final GlobalKey profileTabKey = GlobalKey();
}

final tourKeysProvider = Provider<TourKeys>((ref) {
  return TourKeys();
});

// Trạng thái điều khiển việc bắt đầu tour (khi chuyển sang true sẽ kích hoạt tour ở trang chủ)
final tourStartProvider = StateProvider<bool>((ref) => false);
