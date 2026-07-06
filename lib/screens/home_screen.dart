import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/workout.dart';
import '../utils/responsive.dart';
import '../theme.dart';
import '../providers/health_provider.dart';
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

  Widget _buildHeader(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào mừng trở lại 👋,', style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                state.userData?['name'] ?? 'Người dùng', 
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87, letterSpacing: -0.5),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFFBB86FC).withOpacity(0.5) : Theme.of(context).dividerColor),
                boxShadow: [
                  if (isDark)
                    BoxShadow(
                      color: const Color(0xFFBB86FC).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  else
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
                ],
              ),
              child: _isSyncing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.sync, color: isDark ? const Color(0xFFBB86FC) : AppTheme.primary, size: 22),
                      tooltip: 'Đồng bộ dữ liệu',
                      onPressed: () async {
                        setState(() => _isSyncing = true);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⏳ Đang đồng bộ dữ liệu với máy chủ và thiết bị đeo...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        try {
                          await ref.read(healthProvider.notifier).refreshAll();
                          await Future.delayed(const Duration(milliseconds: 1000));
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Đồng bộ thành công! Chỉ số calo đã được làm mới.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Lỗi đồng bộ: $e'),
                                backgroundColor: Colors.red,
                              ),
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
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFFBB86FC).withOpacity(0.5) : Theme.of(context).dividerColor),
                boxShadow: [
                  if (isDark)
                    BoxShadow(
                      color: const Color(0xFFBB86FC).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  else
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
                ],
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_outlined, size: 22, color: isDark ? const Color(0xFFBB86FC) : Colors.black), 
                    onPressed: _showNotificationsBottomSheet,
                  ),
                  if (_hasUnreadNotifications)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ],
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
              _buildBMICard(state),
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
                Expanded(child: _buildAICard()),
                const SizedBox(width: 16),
                Expanded(child: _buildWaterCard(state)),
              ],
            ),
            const SizedBox(height: 16),
            _buildAIWorkoutCard(),
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

    return _buildBentoCard(
      key: ref.read(tourKeysProvider).bmiKey,
      title: 'Chỉ số BMI của bạn',
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: -1),
                    ),
                    const SizedBox(width: 4),
                    Text('kg/m²', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF949BA4) : Colors.black38, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  height > 0 && weight > 0 ? '${height.toInt()} cm • ${weight.toStringAsFixed(0)} kg' : 'Chưa thiết lập chiều cao/cân nặng',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildBMIGauge(bmi, statusColor),
        ],
      ),
    );
  }

  Widget _buildBMIGauge(double bmi, Color statusColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double percent = bmi > 0 ? ((bmi - 15.0) / (35.0 - 15.0)).clamp(0.0, 1.0) : 0.0;

    return Container(
      height: 90,
      width: 24,
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background/gradient track of the gauge
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: bmi > 0
                    ? const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.blue,          // Gầy
                          Colors.green,         // Bình thường
                          Colors.orangeAccent,  // Thừa cân nhẹ
                          Colors.redAccent,     // Béo phì độ 1
                          Color(0xFFB71C1C),    // Béo phì độ 2
                        ],
                        stops: [
                          0.0,
                          0.175,
                          0.4,
                          0.5,
                          0.75,
                        ],
                      )
                    : null,
                color: bmi > 0 ? null : (isDark ? const Color(0xFF35373C) : Colors.grey[200]),
              ),
            ),
          ),
          // Current status indicator dot
          if (bmi > 0)
            Positioned(
              bottom: (percent * 90) - 8,
              left: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B2D31) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  '${burned.toInt()}',
                  key: ValueKey<int>(burned.toInt()),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: -1),
                ),
              ),
              const SizedBox(width: 4),
              Text('kcal', style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.black38, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF35373C) : Colors.grey[200],
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mục tiêu: ${burnTarget.toInt()} kcal/ngày',
                style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
              ),
              if (burned > 0)
                Icon(Icons.local_fire_department, color: Colors.redAccent, size: 14),
            ],
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
      title: 'Nước uống hôm nay',
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${(current / 1000).toStringAsFixed(current % 1000 == 0 ? 0 : 1)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF29B6F6), letterSpacing: -1),
              ),
              const SizedBox(width: 4),
              Text('/ ${(target / 1000).toStringAsFixed(1)} L',
                  style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.black38, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF35373C) : Colors.grey[200],
              color: const Color(0xFF29B6F6),
            ),
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
                icon: Icon(Icons.undo, size: 18, color: isDark ? const Color(0xFF949BA4) : Colors.grey),
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
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        child: const Text(
          'Lịch sử 🕒',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
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
                    child: IconButton(
                      icon: Icon(Icons.camera_alt_outlined, color: isDark ? const Color(0xFFBB86FC) : Colors.purpleAccent, size: 18),
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
                    child: IconButton(
                      icon: Icon(Icons.auto_awesome, color: isDark ? const Color(0xFFBB86FC) : Colors.purpleAccent, size: 18),
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
        child: const Text(
          'Lịch sử 🕒',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
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
                child: IconButton(
                  icon: Icon(Icons.auto_awesome, color: isDark ? const Color(0xFFBB86FC) : Colors.purpleAccent, size: 18),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parsedJson?['message'] ?? (replyStr.isNotEmpty ? replyStr : 'Không thể phân tích hoạt động. Vui lòng nhập rõ dạng: "Chạy bộ 30 phút"')),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phân tích bài tập: $e'), backgroundColor: Colors.redAccent),
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

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🔥 Đã lưu thành công $caloriesBurned kcal!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context); // Hide loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi lưu: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
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
                    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
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
                    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
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
                child: Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
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
                child: const Icon(Icons.photo_library_outlined, color: Colors.purple),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải ảnh: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showConfirmationSheet(Map<String, dynamic> data) {
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
                'Xác nhận dinh dưỡng', 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF2F3F5) : Colors.black87
                )
              ),
              const SizedBox(height: 16),
              if (data['imageUrl'] != null && data['imageUrl'].toString().startsWith('data:')) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      base64Decode(data['imageUrl'].toString().split(',')[1]),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildNutrientRow('Món ăn', data['foodName'] ?? 'Không rõ'),
              if (data['servingSize'] != null && data['servingSize'].toString().isNotEmpty)
                _buildNutrientRow('Khẩu phần', data['servingSize'].toString()),
              _buildNutrientRow('Calories', '${data['estimatedCalories']} kcal'),
              _buildNutrientRow('Protein', '${data['protein']}g'),
              _buildNutrientRow('Carbs', '${data['carbs']}g'),
              _buildNutrientRow('Fat', '${data['fat']}g'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: PurpleGradientButton(
                  onPressed: () async {
                    await _apiService.addMeal(
                      name: data['foodName'],
                      calories: (data['estimatedCalories'] as num).toDouble(),
                      mealType: 'AI Log',
                      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      imageUrl: data['imageUrl'],
                      servingSize: data['servingSize'],
                    );
                    Navigator.pop(context);
                    ref.read(healthProvider.notifier).refreshAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu món ăn thành công! 🎉'), backgroundColor: Colors.green),
                    );
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

  Widget _buildBentoCard({
    Key? key,
    required String title,
    required Widget child,
    required Color color,
    Widget? action,
    VoidCallback? onTap,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
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
                        fontSize: 14,
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
        Text('Lịch sử tập luyện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          }, 
          child: const Row(
            children: [
              Text('Xem tất cả', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
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
          border: Border.all(color: Theme.of(context).dividerColor),
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
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
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
                child: const Icon(Icons.directions_run_outlined, color: Colors.blueAccent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.activityType, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      '${w.duration.toInt()} phút • ${DateFormat('dd/MM HH:mm').format(DateTime.parse(w.date))}', 
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontWeight: FontWeight.w500),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startInteractiveTour() {
    final tourKeys = ref.read(tourKeysProvider);

    // Kiểm tra xem các widget có được render trên màn hình không
    if (tourKeys.bmiKey.currentContext == null ||
        tourKeys.aiDiaryKey.currentContext == null ||
        tourKeys.chatbotKey.currentContext == null ||
        tourKeys.menuTabKey.currentContext == null) {
      debugPrint("Một số widget tour guide chưa được render!");
      return;
    }

    final List<TargetFocus> targets = [];

    // Bước 1: BMI Card
    targets.add(
      TargetFocus(
        identify: "bmiTarget",
        keyTarget: tourKeys.bmiKey,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTourBubble(
              title: "📊 Chỉ số BMI của bạn",
              message: "Đây là chỉ số BMI động của bạn, tự động tính toán từ cân nặng và chiều cao ở mục cá nhân.",
            ),
          )
        ],
      ),
    );

    // Bước 2: AI Diary Card
    targets.add(
      TargetFocus(
        identify: "aiDiaryTarget",
        keyTarget: tourKeys.aiDiaryKey,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTourBubble(
              title: "📝 Nhật ký AI & Gợi ý nhanh",
              message: "Nhập nhanh món ăn tại đây hoặc bấm các thẻ gợi ý nhanh để trợ lý AI tính calo nạp vào cho bạn nhé!",
            ),
          )
        ],
      ),
    );

    // Bước 3: Floating Chatbot Icon
    targets.add(
      TargetFocus(
        identify: "chatbotTarget",
        keyTarget: tourKeys.chatbotKey,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTourBubble(
              title: "🤖 Trợ lý Sức khỏe AI",
              message: "Bấm vào đây để chat trực tiếp với Trợ lý. Bạn có thể gõ \"Tôi vừa đi bộ 30 phút\" rồi bấm nút Lưu để đồng bộ lên biểu đồ.",
            ),
          )
        ],
      ),
    );

    // Bước 4: Menu Tab icon
    targets.add(
      TargetFocus(
        identify: "menuTabTarget",
        keyTarget: tourKeys.menuTabKey,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTourBubble(
              title: "📅 Thực đơn Dinh dưỡng AI",
              message: "Chuyển sang tab này để nhờ AI thiết kế thực đơn ăn chay, ăn kiêng 7 ngày theo sở thích của bạn.",
            ),
          )
        ],
      ),
    );

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 10,
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
              const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 18),
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
            final notifications = [
              {
                'type': 'Dinh dưỡng',
                'title': 'Dinh dưỡng & Thực đơn',
                'message': 'Bạn mới nạp 550/2000 kcal hôm nay. Hãy dùng Nhật ký AI để cập nhật thêm bữa tối nhé!',
                'time': '10 phút trước',
                'icon': Icons.fastfood_outlined,
                'color': Colors.orangeAccent,
              },
              {
                'type': 'Tập luyện',
                'title': 'Google Fit Sync',
                'message': 'Dữ liệu Google Fit Sync đã cập nhật: +63 kcal từ hoạt động Đi bộ của bạn.',
                'time': '1 giờ trước',
                'icon': Icons.directions_run,
                'color': Colors.cyanAccent,
              },
              {
                'type': 'Hệ thống',
                'title': 'Trợ lý AI',
                'message': 'Trợ lý AI đã chuẩn bị xong Thực đơn 7 ngày mới cho bạn.',
                'time': '3 giờ trước',
                'icon': Icons.auto_awesome,
                'color': Colors.purpleAccent,
              },
              {
                'type': 'Đạt mục tiêu',
                'title': 'Đạt mục tiêu ngày',
                'message': 'Xuất sắc! Bạn đã hoàn thành mục tiêu calo hôm nay với chỉ số dinh dưỡng vô cùng cân đối 🌟.',
                'time': '1 ngày trước',
                'icon': Icons.stars,
                'color': Colors.amber,
              },
              {
                'type': 'Streak',
                'title': 'Giữ vững phong độ',
                'message': 'Bạn đã duy trì nhật ký ăn uống liên tục 3 ngày rồi! Cố gắng giữ vững phong độ cùng HealthAI nhé 💪.',
                'time': '2 ngày trước',
                'icon': Icons.local_fire_department,
                'color': Colors.redAccent,
              },
            ];

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
                                  Icons.notifications_active_rounded,
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Đã đánh dấu toàn bộ thông báo là đã đọc'),
                                    backgroundColor: Colors.purple,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.done_all, size: 16, color: Colors.purpleAccent),
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