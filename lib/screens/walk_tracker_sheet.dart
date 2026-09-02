import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme.dart';
import '../providers/health_provider.dart';
import '../services/accel_stream.dart';
import '../services/api_service.dart';
import '../utils/step_counter.dart';
import '../widgets/app_toast.dart';
import '../widgets/walk_start_button.dart';

/// "Bắt đầu đi bộ" — đếm bước chân bằng cảm biến gia tốc của trình duyệt/thiết bị,
/// dành cho người dùng có tài khoản Google nhưng không dùng Google Fit/app đếm bước
/// nào khác. Chỉ hoạt động khi màn hình này đang mở (không chạy nền).
void showWalkTrackerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => const _WalkTrackerSheet(),
  );
}

class _WalkTrackerSheet extends ConsumerStatefulWidget {
  const _WalkTrackerSheet();

  @override
  ConsumerState<_WalkTrackerSheet> createState() => _WalkTrackerSheetState();
}

class _WalkTrackerSheetState extends ConsumerState<_WalkTrackerSheet> {
  final ApiService _apiService = ApiService();
  final StepCounter _stepCounter = StepCounter();
  StreamSubscription<AccelSample>? _sub;
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isSaving = false;
  bool _permissionDenied = false;

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _onPermissionResult(bool granted) {
    if (!granted) {
      setState(() => _permissionDenied = true);
      return;
    }
    _beginTracking();
  }

  void _beginTracking() {
    _stepCounter.reset();
    _startedAt = DateTime.now();
    setState(() {
      _isRunning = true;
      _permissionDenied = false;
      _elapsed = Duration.zero;
    });

    _sub = accelerometerSampleStream().listen((sample) {
      _stepCounter.addSample(sample.x, sample.y, sample.z);
      if (mounted) setState(() {});
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      }
    });
  }

  double _strideMeters(HealthState healthState) {
    final height = (healthState.userData?['height'] ?? 165).toDouble();
    return height * 0.414 / 100;
  }

  double _distanceKm(HealthState healthState) {
    return (_stepCounter.steps * _strideMeters(healthState)) / 1000;
  }

  // Ước tính calo dựa trên QUÃNG ĐƯỜNG đã đi (suy ra từ số bước thật đo được),
  // không dựa vào thời gian trôi qua — để 0 bước luôn ra 0 kcal, không bị "phi
  // logic" như tính theo thời gian dù đứng yên không đi bước nào.
  double _estimateCalories(HealthState healthState) {
    final weight = (healthState.userData?['weight'] ?? 60).toDouble();
    const kcalPerKgPerKm = 0.9; // trung bình đi bộ tốc độ vừa
    return _distanceKm(healthState) * weight * kcalPerKgPerKm;
  }

  Future<void> _stopAndSave() async {
    _sub?.cancel();
    _ticker?.cancel();
    setState(() => _isRunning = false);

    final steps = _stepCounter.steps;
    final minutes = _elapsed.inSeconds / 60.0;

    if (steps < 10 || minutes < 0.5) {
      AppToast.show(context, message: 'Chưa đủ dữ liệu để lưu — hãy đi bộ thêm chút nữa rồi kết thúc.', type: AppToastType.warning);
      return;
    }

    final calories = _estimateCalories(ref.read(healthProvider));

    setState(() => _isSaving = true);
    try {
      await _apiService.logWorkout(
        activityName: 'Đi bộ ($steps bước, đếm qua cảm biến)',
        duration: minutes,
        caloriesBurned: calories,
      );
      await ref.read(healthProvider.notifier).refreshAll();
      if (mounted) {
        Navigator.pop(context);
        AppToast.show(
          context,
          message: 'Đã lưu buổi đi bộ: $steps bước, ${calories.toStringAsFixed(0)} kcal!',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Lỗi khi lưu: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthState = ref.watch(healthProvider);
    final distanceKm = _distanceKm(healthState);
    final liveCalories = _estimateCalories(healthState);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.footprints, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Bắt đầu đi bộ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: _isRunning ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chỉ đếm được khi màn hình này đang mở (không chạy nền). Hãy giữ điện thoại bên người trong lúc đi.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_permissionDenied)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: const Text(
                'Trình duyệt từ chối quyền đọc cảm biến chuyển động. Trên iPhone: vào Cài đặt > Safari > bật "Chuyển động & Định hướng", rồi thử lại.',
                style: TextStyle(fontSize: 12.5, color: Colors.redAccent, height: 1.4),
              ),
            ),
          Center(
            child: Column(
              children: [
                Text(
                  '${_stepCounter.steps}',
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                Text('bước', style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
                if (_isRunning) ...[
                  const SizedBox(height: 6),
                  Text(
                    _stepCounter.sampleCount == 0
                        ? 'Đang chờ dữ liệu cảm biến...'
                        : 'Đã nhận ${_stepCounter.sampleCount} mẫu cảm biến',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statTile('Thời gian', _formatDuration(_elapsed), isDark)),
              Expanded(child: _statTile('Quãng đường', '${distanceKm.toStringAsFixed(2)} km', isDark)),
              Expanded(child: _statTile('Calo', '${liveCalories.toStringAsFixed(0)} kcal', isDark)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: !_isRunning
                ? WalkStartButton(label: 'Bắt đầu', onPermissionResult: _onPermissionResult)
                : PurpleGradientButton(
                    onPressed: _isSaving ? null : _stopAndSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Kết thúc & Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
      ],
    );
  }
}
