import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/workout.dart';
import '../utils/responsive.dart';
import '../theme.dart';
import '../providers/health_provider.dart';
import '../utils/meal_time.dart';
import '../widgets/app_toast.dart';
import '../widgets/animated_icon_button.dart';
import 'meal_history_screen.dart';
import 'history_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/tour_provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _quickLogController = TextEditingController();
  final TextEditingController _workoutInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSyncing = false;
  bool _hasUnreadNotifications = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(healthProvider.notifier).refreshAll());
  }

  @override
  void dispose() {
    _quickLogController.dispose();
    _workoutInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthProvider);

    final startTour = ref.watch(tourStartProvider);
    if (startTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tourStartProvider.notifier).state = false;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _startInteractiveTour();
          }
        });
      });
    }

    if (healthState.isLoading && healthState.userData == null) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.read(healthProvider.notifier).refreshAll(),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isMobile(context) ? 16 : 24,
            vertical: 20,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(healthState),
              const SizedBox(height: 32),
              _buildBentoGridPro(healthState),
              const SizedBox(height: 32),
              _buildRecentWorkoutsHeader(),
              const SizedBox(height: 16),
              _buildWorkoutList(healthState.recentWorkouts),
            ],
          ),
        ),
      ),
    );
  }

  static const List<String> _weekdayLabels = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  /// Nhãn 7 ngày cho biểu đồ, tính đúng theo ngày thực tế (today-6 → today) thay
  /// vì cố định "T2..CN" — vì dữ liệu weeklyIntake/weeklyBurned luôn là cửa sổ
  /// trượt 7 ngày kết thúc ở HÔM NAY, không phải luôn kết thúc vào Chủ Nhật.
  List<String> _weeklyChartDayLabels() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return _weekdayLabels[d.weekday];
    });
  }

  Widget _buildHeaderIconButton({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFFBB86FC).withOpacity(0.5) : Theme.of(context).dividerColor),
        boxShadow: [
          if (isDark)
            BoxShadow(color: const Color(0xFFBB86FC).withOpacity(0.4), blurRadius: 10, spreadRadius: 1)
          else
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: child,
    );
  }

  Widget _buildDayStrip(bool isDark) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (i) => now.add(Duration(days: i - 3)));
    final accent = AppTheme.heroAccent(isDark);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((d) {
        final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
        return Container(
          width: 38,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isToday ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _weekdayLabels[d.weekday],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isToday ? Colors.white : (isDark ? const Color(0xFF949BA4) : Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${d.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : (isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.heroGradientDark : AppTheme.heroGradientLight,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chào mừng trở lại 👋', style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      state.userData?['name'] ?? 'Người dùng',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87, letterSpacing: -0.5),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildHeaderIconButton(
                    child: _isSyncing
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                            ),
                          )
                        : AnimatedIconButton(
                            icon: LucideIcons.refreshCw,
                            color: isDark ? const Color(0xFFBB86FC) : AppTheme.primary,
                            size: 20,
                            tooltip: 'Đồng bộ dữ liệu',
                            onPressed: () async {
                              setState(() => _isSyncing = true);

                              AppToast.show(
                                context,
                                message: 'Đang đồng bộ dữ liệu với máy chủ và thiết bị đeo...',
                                type: AppToastType.info,
                              );

                              try {
                                await ref.read(healthProvider.notifier).refreshAll();
                                await Future.delayed(const Duration(milliseconds: 1000));

                                if (mounted) {
                                  AppToast.show(
                                    context,
                                    message: 'Đồng bộ thành công! Chỉ số calo đã được làm mới.',
                                    type: AppToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  AppToast.show(
                                    context,
                                    message: 'Lỗi đồng bộ: $e',
                                    type: AppToastType.error,
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isSyncing = false);
                                }
                              }
                            },
                          ),
                  ),
                  const SizedBox(width: 12),
                  _buildHeaderIconButton(
                    child: Stack(
                      children: [
                        AnimatedIconButton(
                          icon: LucideIcons.bell,
                          size: 20,
                          color: isDark ? const Color(0xFFBB86FC) : Colors.black87,
                          onPressed: _showNotificationsBottomSheet,
                        ),
                        if (_hasUnreadNotifications)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            ),
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDayStrip(isDark),
        ],
      ),
    );
  }

  Widget _buildBentoGridPro(HealthState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = Responsive.isTablet(context);
        final isMobile = Responsive.isMobile(context);

        // ── Mobile (<600px): single column ──
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTodayGoalCard(state),
              const SizedBox(height: 16),
              _buildBMICard(state),
              const SizedBox(height: 16),
              _buildStepsCard(state),
              const SizedBox(height: 16),
              _buildCaloriesCard(state),
              const SizedBox(height: 16),
              _buildWaterCard(state),
              const SizedBox(height: 16),
              _buildAICard(),
              const SizedBox(height: 16),
              _buildAIWorkoutCard(),
              const SizedBox(height: 20),
              _buildLineChartCard(state),
              const SizedBox(height: 16),
              _buildBarChartCard(state),
            ],
          );
        }

        // ── Tablet & Desktop: 2-column grid (each card gets ≥ half screen width) ──
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTodayGoalCard(state),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildBMICard(state)),
                const SizedBox(width: 16),
                Expanded(child: _buildCaloriesCard(state)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStepsCard(state)),
                const SizedBox(width: 16),
                Expanded(child: _buildWaterCard(state)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAICard()),
                const SizedBox(width: 16),
                Expanded(child: _buildAIWorkoutCard()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildLineChartCard(state)),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _buildBarChartCard(state)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayGoalCard(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final intake = state.todayIntake;
    final target = state.dailyCalorieTarget;
    final progress = target > 0 ? (intake / target).clamp(0.0, 1.0) : 0.0;
    final gaugeColor = isDark ? AppTheme.gaugeNeutralDark : AppTheme.gaugeNeutralLight;

    return _buildBentoCard(
      title: 'Mục tiêu hôm nay',
      color: Theme.of(context).cardColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${intake.toInt()}',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, letterSpacing: -1),
                    ),
                    Text(
                      ' / ${target.toInt()}',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF949BA4) : Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'kcal đã nạp hôm nay',
                  style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircularPercentIndicator(
            radius: 46,
            lineWidth: 11,
            percent: progress,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: isDark ? const Color(0xFF35373C) : Colors.grey[200]!,
            progressColor: gaugeColor,
            animation: true,
            animationDuration: 700,
            center: Icon(LucideIcons.flame, color: gaugeColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildBMICard(HealthState state) {
    double bmi = 0.0;
    String status = "Chưa có";
    Color statusColor = Colors.grey;
    double height = 0.0;
    double weight = 0.0;

    if (state.userData != null) {
      height = (state.userData!['height'] ?? 0).toDouble();
      weight = (state.userData!['weight'] ?? 0).toDouble();
      if (height > 0 && weight > 0) {
        bmi = weight / ((height / 100) * (height / 100));
        if (bmi < 18.5) {
          status = "Gầy";
          statusColor = Colors.blue;
        } else if (bmi >= 18.5 && bmi <= 22.9) {
          status = "Bình thường";
          statusColor = Colors.green;
        } else if (bmi >= 23.0 && bmi <= 24.9) {
          status = "Thừa cân nhẹ";
          statusColor = Colors.orangeAccent;
        } else if (bmi >= 25.0 && bmi <= 29.9) {
          status = "Béo phì độ 1";
          statusColor = Colors.redAccent;
        } else {
          status = "Béo phì độ 2";
          statusColor = const Color(0xFFB71C1C);
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildBentoCard(
      key: ref.read(tourKeysProvider).bmiKey,
      title: 'Chỉ số BMI của bạn',
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: -1),
              ),
              const SizedBox(width: 10),
              if (bmi > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            height > 0 && weight > 0 ? '${height.toInt()} cm • ${weight.toStringAsFixed(0)} kg' : 'Chưa thiết lập chiều cao/cân nặng',
            style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          _buildBMIHorizontalBar(bmi),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bmiLegendDot('Gầy', Colors.blue, isDark),
              _bmiLegendDot('Bình thường', Colors.green, isDark),
              _bmiLegendDot('Thừa cân', Colors.orangeAccent, isDark),
              _bmiLegendDot('Béo phì', const Color(0xFFB71C1C), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bmiLegendDot(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBMIHorizontalBar(double bmi) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = bmi > 0 ? ((bmi - 15.0) / (35.0 - 15.0)).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final dotX = (percent * trackWidth).clamp(8.0, trackWidth - 8.0);
        return SizedBox(
          height: 18,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8,
                width: trackWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.blue,          // Gầy
                      Colors.green,         // Bình thường
                      Colors.orangeAccent,  // Thừa cân nhẹ
                      Colors.redAccent,     // Béo phì độ 1
                      Color(0xFFB71C1C),    // Béo phì độ 2
                    ],
                    stops: [0.0, 0.175, 0.4, 0.5, 0.75],
                  ),
                ),
              ),
              if (bmi > 0)
                Positioned(
                  left: dotX - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2D31) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black87, width: 2.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaloriesCard(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Hiển thị calo đã đốt từ tập luyện hôm nay
    final burned = state.todayBurned;
    // Mục tiêu đốt calo: 500 kcal/ngày là mức khỏe mạnh
    const double burnTarget = 500.0;
    final progress = (burned / burnTarget).clamp(0.0, 1.0);

    return _buildBentoCard(
      title: 'Calo đã đốt hôm nay',
      color: Theme.of(context).cardColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 46,
            lineWidth: 10,
            percent: progress,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: isDark ? const Color(0xFF35373C) : Colors.grey[200]!,
            progressColor: Colors.redAccent,
            animation: true,
            animationDuration: 600,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    '${burned.toInt()}',
                    key: ValueKey<int>(burned.toInt()),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: -0.5),
                  ),
                ),
                Text('kcal', style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.black38, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mục tiêu: ${burnTarget.toInt()} kcal/ngày',
                  style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (burned > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.flame, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text('Đang cháy!', style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWaterCard(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = state.todayWaterMl;
    final target = state.waterTargetMl;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return _buildBentoCard(
      key: ref.read(tourKeysProvider).waterKey,
      title: 'Nước uống hôm nay',
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _WaterWaveCircle(
                percent: progress,
                size: 92,
                waveColor: const Color(0xFF29B6F6),
                backgroundColor: isDark ? const Color(0xFF35373C) : Colors.grey[200]!,
                center: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(current / 1000).toStringAsFixed(current % 1000 == 0 ? 0 : 1)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : (progress > 0.45 ? Colors.white : const Color(0xFF01579B)),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text('/ ${(target / 1000).toStringAsFixed(1)} L',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : (progress > 0.45 ? Colors.white70 : Colors.black45),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  current >= target
                      ? 'Đã đạt mục tiêu hôm nay! 🎉'
                      : 'Còn ${((target - current) / 1000).toStringAsFixed(1)} L nữa là đạt mục tiêu.',
                  style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _waterQuickButton('+250ml', 250),
              const SizedBox(width: 8),
              _waterQuickButton('+500ml', 500),
              const Spacer(),
              IconButton(
                tooltip: 'Hoàn tác',
                onPressed: current > 0 ? () => ref.read(healthProvider.notifier).undoWater() : null,
                icon: Icon(LucideIcons.undo2, size: 18, color: isDark ? const Color(0xFF949BA4) : Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waterQuickButton(String label, int ml) {
    return OutlinedButton(
      onPressed: () => ref.read(healthProvider.notifier).addWater(ml),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0288D1),
        side: const BorderSide(color: Color(0xFF29B6F6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStepsCard(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = state.todaySteps;
    const double stepGoal = 10000.0;
    final progress = (steps / stepGoal).clamp(0.0, 1.0);

    return _buildBentoCard(
      key: ref.read(tourKeysProvider).stepsKey,
      title: 'Bước chân hôm nay',
      color: Theme.of(context).cardColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 46,
            lineWidth: 10,
            percent: progress,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: isDark ? const Color(0xFF35373C) : Colors.grey[200]!,
            progressColor: Colors.teal,
            animation: true,
            animationDuration: 600,
            center: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.footprints, color: Colors.teal, size: 18),
                  Text(
                    steps > 0 ? steps.toInt().toString() : '0',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mục tiêu: 10.000 bước',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.refreshCw, size: 12, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text('Google Fit',
                        style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildBentoCard(
      key: ref.read(tourKeysProvider).aiDiaryKey,
      title: 'Nhật ký dinh dưỡng AI',
      color: Theme.of(context).cardColor,
      action: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
          );
          ref.read(healthProvider.notifier).refreshAll();
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lịch sử', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(width: 4),
            Icon(LucideIcons.history, size: 15, color: AppTheme.primary),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _quickLogController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Bạn vừa ăn gì hôm nay?',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2D31) : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFFBB86FC).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: AnimatedIconButton(
                      icon: LucideIcons.camera,
                      color: isDark ? const Color(0xFFBB86FC) : Colors.purpleAccent,
                      size: 18,
                      onPressed: _handleImagePick,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2D31) : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFFBB86FC).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: AnimatedIconButton(
                      icon: LucideIcons.sparkles,
                      color: isDark ? const Color(0xFFBB86FC) : Colors.purpleAccent,
                      size: 18,
                      onPressed: () => _handleQuickLog(_quickLogController.text),
                    ),
                  ),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1F22) : Colors.purple.withOpacity(0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (val) => _handleQuickLog(val),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickTag('🥣 Ăn sáng'),
                const SizedBox(width: 8),
                _buildQuickTag('🥗 Ăn trưa'),
                const SizedBox(width: 8),
                _buildQuickTag('🥩 Ăn tối'),
                const SizedBox(width: 8),
                _buildQuickTag('🍎 Ăn nhẹ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTag(String tagText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        final currentText = _quickLogController.text;
        if (currentText.isEmpty) {
          _quickLogController.text = tagText;
        } else {
          _quickLogController.text = currentText.endsWith(' ') ? '$currentText$tagText' : '$currentText $tagText';
        }
        _quickLogController.selection = TextSelection.fromPosition(
          TextPosition(offset: _quickLogController.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF35373C) : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Text(
          tagText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFDBDEE1) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildAIWorkoutCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildBentoCard(
      key: ref.read(tourKeysProvider).aiWorkoutKey,
      title: 'Nhật ký tập luyện AI',
      color: Theme.of(context).cardColor,
      action: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
          ref.read(healthProvider.notifier).refreshAll();
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lịch sử', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(width: 4),
            Icon(LucideIcons.history, size: 15, color: AppTheme.primary),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _workoutInputController,
            style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Bạn đã tập luyện gì hôm nay?',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
              suffixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B2D31) : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: const Color(0xFFBB86FC).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: AnimatedIconButton(
                  icon: LucideIcons.sparkles,
                  color: isDark ? const Color(0xFFBB86FC) : Colors.purpleAccent,
                  size: 18,
                  onPressed: () => _handleWorkoutQuickLog(_workoutInputController.text),
                ),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1F22) : Colors.purple.withOpacity(0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (val) => _handleWorkoutQuickLog(val),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildWorkoutQuickTag('🏃 Đi bộ'),
                const SizedBox(width: 8),
                _buildWorkoutQuickTag('🚴 Đạp xe'),
                const SizedBox(width: 8),
                _buildWorkoutQuickTag('💪 Kháng lực'),
                const SizedBox(width: 8),
                _buildWorkoutQuickTag('🏊 Bơi lội'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutQuickTag(String tagText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        final currentText = _workoutInputController.text;
        if (currentText.isEmpty) {
          _workoutInputController.text = tagText;
        } else {
          _workoutInputController.text = currentText.endsWith(' ') ? '$currentText$tagText' : '$currentText $tagText';
        }
        _workoutInputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _workoutInputController.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF35373C) : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Text(
          tagText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFDBDEE1) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _handleWorkoutQuickLog(String text) async {
    if (text.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final response = await _apiService.sendMessageToAI(text);
      Navigator.pop(context); // Hide loading dialog

      final replyStr = response['reply']?.toString() ?? '';
      
      // Clean up markdown block format if any
      String cleanedReply = replyStr.trim();
      if (cleanedReply.startsWith("```json")) {
        cleanedReply = cleanedReply.replaceFirst("```json", "").replaceAll("```", "").trim();
      } else if (cleanedReply.startsWith("```")) {
        cleanedReply = cleanedReply.replaceFirst("```", "").replaceAll("```", "").trim();
      }

      // Try to parse JSON
      Map<String, dynamic>? parsedJson;
      try {
        parsedJson = jsonDecode(cleanedReply);
      } catch (e) {
        // Not a JSON response
      }

      if (parsedJson != null && parsedJson['action'] == 'LOG_WORKOUT') {
        _showWorkoutConfirmationSheet(parsedJson);
      } else {
        AppToast.show(
          context,
          message: parsedJson?['message'] ?? (replyStr.isNotEmpty ? replyStr : 'Không thể phân tích hoạt động. Vui lòng nhập rõ dạng: "Chạy bộ 30 phút"'),
          type: AppToastType.info,
        );
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading dialog
      AppToast.show(
        context,
        message: 'Lỗi phân tích bài tập: $e',
        type: AppToastType.error,
      );
    }
  }

  void _showWorkoutConfirmationSheet(Map<String, dynamic> data) {
    final activityName = data['activityName'] ?? 'Tập luyện';
    final duration = (data['duration'] is num) 
        ? (data['duration'] as num).toDouble() 
        : double.tryParse(data['duration']?.toString() ?? '0') ?? 0.0;
    final caloriesBurned = (data['caloriesBurned'] is num) 
        ? (data['caloriesBurned'] as num).toDouble() 
        : double.tryParse(data['caloriesBurned']?.toString() ?? '0') ?? 0.0;
    final message = data['message'] ?? 'Tuyệt vời!';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xác nhận tập luyện', 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF2F3F5) : Colors.black87
                )
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFB5BAC1) : Colors.black54
                ),
              ),
              const SizedBox(height: 16),
              _buildNutrientRow('Hoạt động', activityName),
              _buildNutrientRow('Thời gian', '${duration.toStringAsFixed(0)} phút'),
              _buildNutrientRow('Calories tiêu hao', '${caloriesBurned.toStringAsFixed(0)} kcal'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: PurpleGradientButton(
                  onPressed: () async {
                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );

                      await _apiService.logWorkout(
                        activityName: activityName,
                        duration: duration,
                        caloriesBurned: caloriesBurned,
                      );

                      await ref.read(healthProvider.notifier).refreshAll();

                      Navigator.pop(context); // Hide loading dialog
                      Navigator.pop(context); // Close confirmation sheet
                      _workoutInputController.clear(); // Clear input field

                      AppToast.show(
                        context,
                        message: 'Đã lưu thành công $caloriesBurned kcal!',
                        type: AppToastType.success,
                      );
                    } catch (e) {
                      Navigator.pop(context); // Hide loading dialog
                      AppToast.show(
                        context,
                        message: 'Lỗi khi lưu: $e',
                        type: AppToastType.error,
                      );
                    }
                  },
                  child: const Text('Lưu vào nhật ký', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineChartCard(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildBentoCard(
      title: 'Xu hướng calo nạp vào (7 ngày qua)',
      color: Theme.of(context).cardColor,
      child: Container(
        height: 220,
        padding: const EdgeInsets.only(top: 24, right: 16, bottom: 8),
        child: state.weeklyIntake.isEmpty 
          ? const Center(child: Text('Chưa có dữ liệu đồ thị', style: TextStyle(color: Colors.grey, fontSize: 12)))
          : LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(color: isDark ? const Color(0xFF35373C) : Colors.grey.withOpacity(0.08), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (val, meta) {
                    if (val % 1 != 0 || val < 0 || val >= 7) return const SizedBox();
                    final days = _weeklyChartDayLabels();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(days[val.toInt()], style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF949BA4) : Colors.grey, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: state.weeklyIntake.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                isCurved: true,
                gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true, 
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent.withOpacity(0.2), Colors.deepOrange.withOpacity(0.01)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartCard(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildBentoCard(
      title: 'Nạp vs Đốt (kcal)',
      color: Theme.of(context).cardColor,
      child: Container(
        height: 220,
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: (state.weeklyIntake.isEmpty || state.weeklyBurned.isEmpty)
          ? const Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: Colors.grey, fontSize: 12)))
          : BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (val, meta) {
                    if (val % 1 != 0 || val < 0 || val >= 7) return const SizedBox();
                    final days = _weeklyChartDayLabels();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(days[val.toInt()], style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF949BA4) : Colors.grey, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: state.weeklyIntake.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value, 
                    color: Colors.orangeAccent, 
                    width: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: state.weeklyBurned[e.key], 
                    color: Colors.blueAccent, 
                    width: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuickLog(String text) async {
    if (text.isEmpty) return;
    _analyzeData(text: text);
  }

  Future<void> _handleImagePick() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tải ảnh phân tích dinh dưỡng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.camera, color: AppTheme.primary),
              ),
              title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.image, color: Colors.purple),
              ),
              title: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        _analyzeData(
          imageBytes: bytes,
          fileName: file.name,
        );
      }
    } catch (e) {
      AppToast.show(
        context,
        message: 'Lỗi tải ảnh: $e',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _analyzeData({String? text, List<int>? imageBytes, String? fileName}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final data = await _apiService.analyzeFood(text: text, imageBytes: imageBytes, fileName: fileName);
      Navigator.pop(context); 
      _showConfirmationSheet(data);
    } catch (e) {
      Navigator.pop(context);
      AppToast.show(context, message: e.toString().replaceFirst('Exception: ', ''), type: AppToastType.error);
    }
  }

  void _showConfirmationSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final calories = data['estimatedCalories'] ?? data['calories'] ?? 0;
        final isReasonable = data['isReasonable'] != false;
        final warningMessage = data['warningMessage']?.toString() ?? '';

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF35373C) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (data['imageUrl'] != null && data['imageUrl'].toString().startsWith('data:')) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      base64Decode(data['imageUrl'].toString().split(',')[1]),
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$calories',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, letterSpacing: -1),
                    ),
                    const SizedBox(width: 6),
                    Text('kcal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['foodName'] ?? 'Không rõ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                ),
                if (data['servingSize'] != null && data['servingSize'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data['servingSize'].toString(),
                    style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildMacroPill('${data['protein']}g', 'Protein', AppTheme.macroProtein, LucideIcons.beef)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMacroPill('${data['carbs']}g', 'Carbs', AppTheme.macroCarbs, LucideIcons.wheat)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMacroPill('${data['fat']}g', 'Fat', AppTheme.macroFat, LucideIcons.droplet)),
                  ],
                ),
                if (!isReasonable && warningMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A524).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: Color(0xFFF5A524), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            warningMessage,
                            style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87, fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? const Color(0xFF35373C) : Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: PurpleGradientButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final mealType = detectMealTypeByTime(now);
                            final calories = (data['estimatedCalories'] as num).toDouble();
                            final protein = (data['protein'] as num?)?.toDouble() ?? 0;
                            final carbs = (data['carbs'] as num?)?.toDouble() ?? 0;
                            final fat = (data['fat'] as num?)?.toDouble() ?? 0;
                            final fiber = (data['fiber'] as num?)?.toDouble() ?? 0;
                            final sugar = (data['sugar'] as num?)?.toDouble() ?? 0;
                            final sodium = (data['sodium'] as num?)?.toDouble() ?? 0;

                            await _apiService.addMeal(
                              name: data['foodName'],
                              calories: calories,
                              mealType: mealType,
                              date: DateFormat('yyyy-MM-dd').format(now),
                              imageUrl: data['imageUrl'],
                              servingSize: data['servingSize'],
                              protein: protein,
                              carbs: carbs,
                              fat: fat,
                              fiber: fiber,
                              sugar: sugar,
                              sodium: sodium,
                            );

                            // Món ăn thật vừa log khác với gợi ý ban đầu của Thực đơn AI
                            // (nếu có) → ghi đè lại slot bữa tương ứng hôm nay cho khớp thực tế.
                            await ref.read(healthProvider.notifier).updateMealInPlan(
                              mealType: mealType,
                              newName: data['foodName'],
                              newCalories: calories,
                              carbs: carbs,
                              protein: protein,
                              fat: fat,
                              fiber: fiber,
                              sugar: sugar,
                              sodium: sodium,
                              imageUrl: data['imageUrl'],
                              servingSize: data['servingSize'],
                            );

                            Navigator.pop(context);
                            ref.read(healthProvider.notifier).refreshAll();
                            AppToast.show(
                              context,
                              message: 'Đã lưu món ăn thành công!',
                              type: AppToastType.success,
                            );
                          },
                          child: const Text('Lưu vào nhật ký', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String value, String label, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF949BA4) : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    Key? key,
    required String title,
    required Widget child,
    required Color color,
    Widget? action,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.055),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (action != null) action,
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWorkoutsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Lịch sử tập luyện', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          },
          child: const Row(
            children: [
              Text('Xem tất cả', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutList(List<Workout> workouts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (workouts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.22 : 0.055), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -6),
          ],
        ),
        child: const Center(
          child: Text('Chưa có lịch sử tập luyện hôm nay', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workouts.length > 5 ? 5 : workouts.length,
      itemBuilder: (context, index) {
        final w = workouts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -6),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.activity, color: Colors.blueAccent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.activityType, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      '${w.duration.toInt()} phút • ${DateFormat('dd/MM HH:mm').format(DateTime.parse(w.date))}',
                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${w.calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tạo một bước tour gọn gàng
  TargetFocus _tourTarget({
    required String id,
    required GlobalKey key,
    required String title,
    required String message,
    ContentAlign align = ContentAlign.bottom,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double radius = 20,
  }) {
    return TargetFocus(
      identify: id,
      keyTarget: key,
      paddingFocus: 8,
      shape: shape,
      radius: radius,
      contents: [
        TargetContent(
          align: align,
          child: _buildTourBubble(title: title, message: message),
        ),
      ],
    );
  }

  void _startInteractiveTour() {
    final tourKeys = ref.read(tourKeysProvider);

    if (tourKeys.bmiKey.currentContext == null) {
      debugPrint("Widget tour guide chưa được render!");
      return;
    }

    // Đưa trang về đầu để bắt đầu tour gọn gàng
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    final targets = <TargetFocus>[
      _tourTarget(
        id: "bmi", key: tourKeys.bmiKey,
        title: "📊 Chỉ số BMI của bạn",
        message: "BMI tự động tính từ cân nặng & chiều cao, phân loại theo chuẩn Châu Á. Chạm để xem thể trạng.",
      ),
      _tourTarget(
        id: "steps", key: tourKeys.stepsKey,
        title: "👟 Bước chân hôm nay",
        message: "Số bước tự đồng bộ từ Google Fit khi bạn đăng nhập bằng Google. Mục tiêu 10.000 bước/ngày.",
      ),
      _tourTarget(
        id: "water", key: tourKeys.waterKey,
        title: "💧 Nước uống hôm nay",
        message: "Bấm +250ml / +500ml để ghi lượng nước. Mục tiêu được tính theo cân nặng của bạn.",
      ),
      _tourTarget(
        id: "aiDiary", key: tourKeys.aiDiaryKey,
        title: "📝 Nhật ký dinh dưỡng AI",
        message: "Nhập tên món hoặc tải ẢNH món ăn, AI sẽ tính calo và các chất dinh dưỡng nạp vào.",
      ),
      _tourTarget(
        id: "aiWorkout", key: tourKeys.aiWorkoutKey,
        title: "🏋️ Nhật ký tập luyện AI",
        message: "Gõ hoạt động vừa tập (VD: \"chạy bộ 30 phút\"), AI tính calo đã đốt và lưu vào thống kê.",
      ),
      _tourTarget(
        id: "chatbot", key: tourKeys.chatbotKey,
        title: "🤖 Trợ lý Sức khỏe AI",
        message: "Bong bóng chat để hỏi đáp mọi lúc về sức khỏe, dinh dưỡng, tập luyện.",
        align: ContentAlign.top, shape: ShapeLightFocus.Circle, radius: 0,
      ),
      _tourTarget(
        id: "menuTab", key: tourKeys.menuTabKey,
        title: "📅 Thực đơn Dinh dưỡng AI",
        message: "Tab Thực đơn: nhờ AI thiết kế thực đơn ăn kiêng/ăn chay 7 ngày theo sở thích.",
        align: ContentAlign.top,
      ),
      _tourTarget(
        id: "statsTab", key: tourKeys.statsTabKey,
        title: "📈 Thống kê",
        message: "Xem biểu đồ calo nạp/đốt, xu hướng cân nặng & BMI theo 7 ngày.",
        align: ContentAlign.top,
      ),
      _tourTarget(
        id: "profileTab", key: tourKeys.profileTabKey,
        title: "👤 Cá nhân",
        message: "Cập nhật hồ sơ, đặt mục tiêu calo, hồ sơ sức khỏe, dự đoán calo và cài đặt.",
        align: ContentAlign.top,
      ),
    ];

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 10,
      pulseEnable: false, // tắt hiệu ứng nhấp nháy gây cảm giác "giật"
      // Tự động cuộn tới widget trước khi highlight (quan trọng trên điện thoại)
      beforeFocus: (target) async {
        final ctx = target.keyTarget?.currentContext;
        if (ctx != null) {
          try {
            await Scrollable.ensureVisible(
              ctx,
              alignment: 0.25,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 250));
        }
      },
      textSkip: "Bỏ qua",
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      onSkip: () {
        debugPrint("Người dùng bỏ qua Tour");
        return true;
      },
      onFinish: () {
        debugPrint("Người dùng hoàn thành Tour");
      },
    );

    tutorial.show(context: context);
  }

  Widget _buildTourBubble({required String title, required String message}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31), // Nền xám tối Discord
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8A2BE2), width: 2), // Viền tím gradient màu chủ đạo
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.purpleAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFDBDEE1), // Nhạt màu Discord
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF12121E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Thông báo sinh động TỪ DỮ LIỆU THẬT để đồng nhất với dashboard
            final health = ref.read(healthProvider);
            final intake = health.todayIntake;
            final target = health.dailyCalorieTarget;
            final burned = health.todayBurned;
            final steps = health.todaySteps;
            final water = health.todayWaterMl;
            final waterTarget = health.waterTargetMl;

            // Chuỗi ngày ghi nhật ký liên tục (tính đến hôm nay)
            int streak = 0;
            for (int i = health.weeklyIntake.length - 1; i >= 0; i--) {
              if (health.weeklyIntake[i] > 0) {
                streak++;
              } else {
                break;
              }
            }

            final notifications = <Map<String, dynamic>>[];

            // 1) Dinh dưỡng hôm nay
            notifications.add({
              'title': 'Dinh dưỡng hôm nay',
              'message': intake > 0
                  ? 'Bạn đã nạp ${intake.toInt()}/${target.toInt()} kcal hôm nay.' +
                      (intake < target
                          ? ' Còn ${(target - intake).toInt()} kcal để đạt mục tiêu.'
                          : ' Bạn đã đạt/vượt mục tiêu!')
                  : 'Hôm nay bạn chưa ghi bữa ăn nào. Hãy dùng Nhật ký AI để bắt đầu nhé!',
              'time': 'Hôm nay',
              'icon': LucideIcons.utensilsCrossed,
              'color': Colors.orangeAccent,
            });

            // 2) Google Fit (số liệu thật)
            notifications.add({
              'title': 'Google Fit',
              'message': (steps > 0 || burned > 0)
                  ? 'Đã đồng bộ: ${steps.toInt()} bước • ${burned.toInt()} kcal đã đốt hôm nay.'
                  : 'Chưa có dữ liệu Google Fit hôm nay. Đăng nhập bằng Google để đồng bộ số bước.',
              'time': 'Vừa cập nhật',
              'icon': LucideIcons.activity,
              'color': Colors.cyan,
            });

            // 3) Nước uống
            notifications.add({
              'title': 'Nước uống',
              'message': water > 0
                  ? 'Bạn đã uống ${(water / 1000).toStringAsFixed(1)}L / ${(waterTarget / 1000).toStringAsFixed(1)}L hôm nay.' +
                      (water < waterTarget ? ' Uống thêm để đạt mục tiêu nhé!' : ' Tuyệt vời, đã đủ nước!')
                  : 'Bạn chưa uống nước hôm nay. Bấm +250ml trên thẻ Nước uống để ghi lại.',
              'time': 'Hôm nay',
              'icon': LucideIcons.droplet,
              'color': Colors.blueAccent,
            });

            // 4) Đạt mục tiêu calo (khi nạp sát mục tiêu)
            if (target > 0 && intake >= target * 0.9 && intake <= target * 1.1) {
              notifications.add({
                'title': 'Đạt mục tiêu ngày',
                'message': 'Xuất sắc! Lượng calo nạp hôm nay rất sát mục tiêu của bạn 🌟.',
                'time': 'Hôm nay',
                'icon': LucideIcons.star,
                'color': Colors.amber,
              });
            }

            // 5) Chuỗi ngày (streak) khi >= 2 ngày
            if (streak >= 2) {
              notifications.add({
                'title': 'Giữ vững phong độ',
                'message': 'Bạn đã ghi nhật ký ăn uống $streak ngày liên tục! Cố gắng duy trì nhé 💪.',
                'time': 'Chuỗi ngày',
                'icon': LucideIcons.flame,
                'color': Colors.redAccent,
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: const Icon(
                                  LucideIcons.bellRing,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Thông báo',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          if (_hasUnreadNotifications)
                            TextButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  setState(() {
                                    _hasUnreadNotifications = false;
                                  });
                                });
                                AppToast.show(
                                  context,
                                  message: 'Đã đánh dấu toàn bộ thông báo là đã đọc',
                                  type: AppToastType.info,
                                );
                              },
                              icon: const Icon(LucideIcons.checkCheck, size: 16, color: Colors.purpleAccent),
                              label: const Text(
                                'Đọc tất cả',
                                style: TextStyle(
                                  color: Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            Text(
                              'Đã xem hết',
                              style: TextStyle(
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: isDark ? const Color(0xFF26263F) : Colors.grey[200], height: 1),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            final itemColor = item['color'] as Color;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark 
                                      ? const Color(0xFF2B2D3F) 
                                      : Colors.grey.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: itemColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: itemColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item['title'] as String,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              item['time'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? const Color(0xFF949BA4) : Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item['message'] as String,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: isDark ? const Color(0xFFDBDEE1) : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_hasUnreadNotifications && index < 2)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8, top: 4),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.purpleAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Vòng tròn hiển thị mực nước dạng "sóng" lắc nhẹ nhàng qua lại (không cuộn một
/// chiều liên tục), dùng cho card "Nước uống hôm nay".
class _WaterWaveCircle extends StatefulWidget {
  final double percent; // 0..1
  final double size;
  final Color waveColor;
  final Color backgroundColor;
  final Widget? center;

  const _WaterWaveCircle({
    required this.percent,
    required this.waveColor,
    required this.backgroundColor,
    this.size = 84,
    this.center,
  });

  @override
  State<_WaterWaveCircle> createState() => _WaterWaveCircleState();
}

class _WaterWaveCircleState extends State<_WaterWaveCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipOval(
        child: Container(
          color: widget.backgroundColor,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _WavePainter(
                      progress: widget.percent.clamp(0.0, 1.0),
                      animationValue: _controller.value,
                      color: widget.waveColor,
                    ),
                  );
                },
              ),
              if (widget.center != null) widget.center!,
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress; // 0..1, mực nước tính từ đáy lên
  final double animationValue; // 0..1, lặp vô hạn
  final Color color;

  _WavePainter({required this.progress, required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final waveAmplitude = size.height * 0.045;
    final baseline = size.height * (1 - progress);
    // Lắc qua lắc lại nhẹ nhàng (dao động sin) thay vì cuộn một chiều liên tục.
    final phase = math.sin(animationValue * 2 * math.pi) * (math.pi / 3);

    Path buildWave(double amplitude, double phaseShift) {
      final path = Path()..moveTo(0, size.height)..lineTo(0, baseline);
      for (double x = 0; x <= size.width; x += 2) {
        final y = baseline + math.sin((x / size.width * 2 * math.pi) + phaseShift) * amplitude;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      return path;
    }

    canvas.drawPath(buildWave(waveAmplitude, phase), Paint()..color = color.withOpacity(0.5));
    canvas.drawPath(buildWave(waveAmplitude * 0.7, phase + math.pi / 2), Paint()..color = color.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}