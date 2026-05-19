import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../providers/health_provider.dart';
import '../services/api_service.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int _activeSegment = 0; // 0: Hôm nay, 1: Tuần này
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Tự động load plan nếu chưa có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthProvider.notifier).loadPlan();
    });
  }

  List<dynamic> _getTodaysMeals(HealthState healthState) {
    if (healthState.currentPlan == null) return [];
    
    final weeklyPlan = (healthState.currentPlan!['weeklyPlan'] ?? healthState.currentPlan!['meal_plan']) as List<dynamic>?;
    if (weeklyPlan == null || weeklyPlan.isEmpty) return [];

    // Lấy ngày hiện tại: 1 -> Thứ 2, 7 -> Chủ nhật
    final weekday = DateTime.now().weekday;
    
    // Bộ từ điển mapping toàn diện cho mọi định dạng AI có thể sinh ra
    final Map<int, List<String>> weekdayNames = {
      1: ['T2', 'THỨ 2', 'THỨ HAI', 'MONDAY'],
      2: ['T3', 'THỨ 3', 'THỨ BA', 'TUESDAY'],
      3: ['T4', 'THỨ 4', 'THỨ TƯ', 'WEDNESDAY'],
      4: ['T5', 'THỨ 5', 'THỨ NĂM', 'THURSDAY'],
      5: ['T6', 'THỨ 6', 'THỨ SÁU', 'FRIDAY'],
      6: ['T7', 'THỨ 7', 'THỨ BẢY', 'SATURDAY'],
      7: ['CN', 'CHỦ NHẬT', 'SUNDAY'],
    };
    
    final validNames = weekdayNames[weekday] ?? [];

    // Tìm ngày hôm nay trong kế hoạch
    dynamic todayPlan = weeklyPlan.firstWhere(
      (plan) {
        final planDay = plan['day']?.toString().toUpperCase().trim() ?? '';
        return validNames.any((name) => planDay == name || planDay.contains(name));
      },
      orElse: () => null,
    );

    // ✅ FALLBACK: Nếu không match được, lấy ngày đầu tiên trong danh sách
    // (AI có thể bắt đầu từ T2 nhưng hôm nay là T5 -> vẫn hiển thị thay vì trống)
    todayPlan ??= weeklyPlan.first;

    final meals = todayPlan['meals'];
    if (meals == null) return [];
    return meals as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1F22) : const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAISuggestionBanner(healthState),
                const SizedBox(height: 32),
                _buildSegmentedControl(),
                const SizedBox(height: 24),
                _activeSegment == 0 
                  ? _buildDailyListSection(healthState)
                  : _buildWeeklyListSection(healthState),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B1FA2).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAIChatbotDialog(healthState),
          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          label: const Text('Tạo Thực Đơn AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAISuggestionBanner(HealthState healthState) {
    double bmi = 0.0;
    if (healthState.userData != null) {
      double h = (healthState.userData!['height'] ?? 0).toDouble();
      double w = (healthState.userData!['weight'] ?? 0).toDouble();
      if (h > 0 && w > 0) {
        bmi = w / ((h / 100) * (h / 100));
      }
    }

    String advice = 'Đang đề xuất dựa trên BMI hiện tại của bạn: ${bmi.toStringAsFixed(1)}';
    if (healthState.currentPlan != null && healthState.currentPlan!['advice'] != null) {
       advice = healthState.currentPlan!['advice'];
    } else if (bmi == 0) {
       advice = 'Hãy tạo thực đơn cá nhân bằng cách nhấn nút "Tạo thực đơn AI" bên dưới!';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF2A2A40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thực đơn Dinh dưỡng AI',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2D31) : Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSegment = 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _activeSegment == 0 ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Hôm nay',
                  style: TextStyle(
                    color: _activeSegment == 0 ? Colors.white : (isDark ? const Color(0xFFB5BAC1) : Colors.black54),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSegment = 1),
              child: Container(
                decoration: BoxDecoration(
                  color: _activeSegment == 1 ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Tuần này',
                  style: TextStyle(
                    color: _activeSegment == 1 ? Colors.white : (isDark ? const Color(0xFFB5BAC1) : Colors.black54),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyListSection(HealthState healthState) {
    final todaysMeals = _getTodaysMeals(healthState);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (todaysMeals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.fastfood_outlined, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              const Text('Chưa có thực đơn cho hôm nay.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Hãy nhấn Tạo Thực Đơn AI ở góc dưới nhé!', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kế hoạch Ăn uống', 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: isDark ? const Color(0xFFF2F3F5) : Colors.black87
              )
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                'Tổng Calo Nạp: ${healthState.todayIntake.toInt()} kcal',
                key: ValueKey<int>(healthState.todayIntake.toInt()),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: todaysMeals.length,
          itemBuilder: (context, index) {
            final meal = todaysMeals[index];
            return _buildMealCard(meal, healthState);
          },
        ),
      ],
    );
  }

  Widget _buildWeeklyListSection(HealthState healthState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (healthState.currentPlan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.calendar_month, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              const Text('Bạn chưa tạo thực đơn 7 ngày từ AI', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              PurpleGradientButton(
                onPressed: () => _showAIChatbotDialog(healthState),
                width: 200,
                child: const Text('Tạo Thực Đơn Ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final mealPlanList = (healthState.currentPlan!['weeklyPlan'] ?? healthState.currentPlan!['meal_plan']) as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thực đơn 7 ngày AI', 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: isDark ? const Color(0xFFF2F3F5) : Colors.black87
          )
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mealPlanList.length,
          itemBuilder: (context, index) {
            final plan = mealPlanList[index];
            final dayName = plan['day']?.toString() ?? 'T${index + 2}';
            
            // Lấy danh sách món ăn trong ngày này
            final List<dynamic> meals = plan['meals'] as List<dynamic>? ?? [];
            final double totalCal = (plan['totalCalories'] ?? plan['daily_calories'] ?? 0).toDouble();
            final String desc = plan['daily_desc'] ?? 'Thực đơn dinh dưỡng';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B2D31) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF35373C) : Colors.grey.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Header Row
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(
                          dayName.replaceAll('Thứ ', 'T'),
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          desc,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '${totalCal.toInt()} kcal',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? const Color(0xFF35373C) : Colors.grey[200], height: 1),
                  const SizedBox(height: 8),
                  
                  // Render each meal inside this day card
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: meals.length,
                    itemBuilder: (context, mIndex) {
                      final meal = meals[mIndex];
                      
                      Color color = Colors.orangeAccent;
                      IconData icon = Icons.wb_sunny_outlined;
                      String timeStr = "07:30 AM";
                      String mealTypeStr = meal['type']?.toString().toLowerCase() ?? '';

                      if (mealTypeStr.contains('trưa')) {
                        color = Colors.blueAccent;
                        icon = Icons.wb_twilight;
                        timeStr = "12:15 PM";
                      } else if (mealTypeStr.contains('tối')) {
                        color = Colors.indigoAccent;
                        icon = Icons.nights_stay_outlined;
                        timeStr = "06:45 PM";
                      } else if (mealTypeStr.contains('phụ')) {
                        color = Colors.greenAccent;
                        icon = Icons.spa_outlined;
                        timeStr = "03:00 PM";
                      }

                      String macros = 'Carb: ${meal['carbs']}g • Protein: ${meal['protein']}g • Fat: ${meal['fat']}g';
                      if (meal['carbs'] == null) macros = 'Thông tin dinh dưỡng đang cập nhật';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        meal['type'] ?? 'Bữa ăn', 
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeStr, 
                                        style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w500)
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    meal['name'] ?? 'Món ăn',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    macros,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${meal['calories']} kcal',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => _showCustomMealDialog(
                                    mealType: meal['type'] ?? 'Bữa ăn',
                                    healthState: healthState,
                                    initialFoodName: meal['name'],
                                    dayName: dayName,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit, size: 12, color: isDark ? Colors.white70 : Colors.black54),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: isDark ? const Color(0xFF1E1F22) : Colors.white,
                                        title: const Text('Xóa món ăn'),
                                        content: Text('Bạn có chắc chắn muốn xóa bữa ${meal['type']?.toLowerCase()} này của ${dayName.toLowerCase()}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(healthProvider.notifier).removeMealFromPlan(
                                        mealType: meal['type'] ?? 'Bữa ăn',
                                        dayName: dayName,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_outline, size: 12, color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, HealthState healthState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color = Colors.orangeAccent;
    IconData icon = Icons.wb_sunny_outlined;
    String timeStr = "07:30 AM";
    String mealTypeStr = meal['type']?.toString().toLowerCase() ?? '';

    if (mealTypeStr.contains('trưa')) {
      color = Colors.blueAccent;
      icon = Icons.wb_twilight;
      timeStr = "12:15 PM";
    } else if (mealTypeStr.contains('tối')) {
      color = Colors.indigoAccent;
      icon = Icons.nights_stay_outlined;
      timeStr = "06:45 PM";
    } else if (mealTypeStr.contains('phụ')) {
      color = Colors.greenAccent;
      icon = Icons.spa_outlined;
      timeStr = "03:00 PM";
    }

    String macros = 'Carb: ${meal['carbs']}g • Protein: ${meal['protein']}g • Fat: ${meal['fat']}g';
    if (meal['carbs'] == null) macros = 'Thông tin dinh dưỡng đang cập nhật';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2D31) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF35373C) : Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(meal['type'] ?? 'Bữa ăn', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  meal['name'] ?? 'Món ăn',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, 
                    color: isDark ? const Color(0xFFF2F3F5) : Colors.black87
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(macros, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${meal['calories']} kcal',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showCustomMealDialog(
                      mealType: meal['type'] ?? 'Bữa ăn',
                      healthState: healthState,
                      initialFoodName: meal['name'],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showCustomMealDialog(
                      mealType: meal['type'] ?? 'Bữa ăn',
                      healthState: healthState,
                      initialFoodName: meal['name'],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDark ? const Color(0xFF1E1F22) : Colors.white,
                          title: const Text('Xóa món ăn'),
                          content: Text('Bạn có chắc chắn muốn xóa bữa ${meal['type']?.toLowerCase()} này?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(healthProvider.notifier).removeMealFromPlan(
                          mealType: meal['type'] ?? 'Bữa ăn',
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- POPUP 'TÙY CHỈNH BỮA ĂN' (EDIT/ADD MODE WITH AI VERIFICATION) ---
  void _showCustomMealDialog({
    required String mealType,
    required HealthState healthState,
    String? initialFoodName,
    String? dayName,
  }) {
    final foodController = TextEditingController(text: initialFoodName);
    bool isAnalyzing = false;
    bool isAnalyzed = false;
    bool showWarning = false;
    String warningMessage = '';
    String? validationErrorMessage;
    
    double estimatedCalories = 0.0;
    String detectedName = '';
    double carbs = 0.0;
    double protein = 0.0;
    double fat = 0.0;
    String macrosText = '';

    double targetDailyCalories = 2000.0;
    final double remainingCalories = targetDailyCalories - healthState.todayIntake;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1F22) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Tùy chỉnh bữa ăn', 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? const Color(0xFFF2F3F5) : Colors.black87
                  )
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thay đổi món ăn cho bữa ${mealType.toLowerCase()}:',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF949BA4) : Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: foodController,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Nhập tên món ăn...',
                    hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2B2D31) : Colors.grey[50],
                  ),
                  onChanged: (val) {
                    if (validationErrorMessage != null || showWarning || isAnalyzed) {
                      setDialogState(() {
                        validationErrorMessage = null;
                        showWarning = false;
                        isAnalyzed = false;
                      });
                    }
                  },
                ),
                if (validationErrorMessage != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      validationErrorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                if (isAnalyzing) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          '🤖 AI đang phân tích dinh dưỡng...',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF949BA4) : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showWarning) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.orangeAccent.withOpacity(0.15) : Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            warningMessage,
                            style: TextStyle(
                              color: isDark ? Colors.orangeAccent : Colors.orange[900],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isAnalyzed && !showWarning && validationErrorMessage == null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.greenAccent.withOpacity(0.15) : Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✅ Phân tích hoàn tất: $detectedName',
                                style: TextStyle(
                                  color: isDark ? Colors.greenAccent : Colors.green[900],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Năng lượng: ${estimatedCalories.toInt()} kcal',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                macrosText,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF949BA4) : Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actionsPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isAnalyzing)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (foodController.text.trim().isEmpty) return;

                        setDialogState(() {
                          isAnalyzing = true;
                          validationErrorMessage = null;
                          showWarning = false;
                          isAnalyzed = false;
                        });

                        try {
                          final result = await _apiService.analyzeFood(
                            text: foodController.text,
                            remainingCalories: remainingCalories,
                            todayIntake: healthState.todayIntake,
                            targetCalories: targetDailyCalories,
                          );

                          if (result != null && result.isNotEmpty) {
                            final bool isFood = result['isFood'] ?? true;

                            if (!isFood) {
                              setDialogState(() {
                                isAnalyzing = false;
                                validationErrorMessage = result['message'] ??
                                    'Đây không phải là thức ăn hoặc đồ uống hợp lệ. Vui lòng nhập lại!';
                              });
                              return;
                            }

                            estimatedCalories = (result['estimatedCalories'] ?? result['calories'] ?? 0).toDouble();
                            detectedName = result['foodName'] ?? foodController.text;
                            carbs = (result['carbs'] ?? 0.0).toDouble();
                            protein = (result['protein'] ?? 0.0).toDouble();
                            fat = (result['fat'] ?? 0.0).toDouble();
                            macrosText = result['macros'] ??
                                'Carb: ${carbs.toInt()}g • Protein: ${protein.toInt()}g • Fat: ${fat.toInt()}g';

                            final bool isReasonable = result['isReasonable'] ?? true;
                            final String warnMsg = result['warningMessage'] ?? '';

                            setDialogState(() {
                              isAnalyzing = false;
                              isAnalyzed = true;
                              if (!isReasonable && warnMsg.isNotEmpty) {
                                showWarning = true;
                                warningMessage = warnMsg;
                              }
                            });
                          } else {
                            setDialogState(() {
                              isAnalyzing = false;
                              validationErrorMessage = 'Không thể phân tích món ăn này. Vui lòng thử lại!';
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            isAnalyzing = false;
                            validationErrorMessage = 'Không thể phân tích món ăn này. Vui lòng thử lại!';
                          });
                        }
                      },
                      child: const Text('Kiểm tra AI', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  if (isAnalyzed) ...[
                    const SizedBox(height: 12),
                    PurpleGradientButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⏳ Đang cập nhật thực đơn và đồng bộ dữ liệu...'),
                            duration: Duration(milliseconds: 800),
                          ),
                        );

                        try {
                          // 1. Lưu đè món mới vào thực đơn (Plan)
                          await ref.read(healthProvider.notifier).updateMealInPlan(
                            mealType: mealType,
                            newName: detectedName,
                            newCalories: estimatedCalories,
                            carbs: carbs,
                            protein: protein,
                            fat: fat,
                            dayName: dayName,
                          );

                          // 2. Lưu món ăn vào Database qua API để cập nhật tổng calo (chỉ khi là hôm nay)
                          final isToday = dayName == null || dayName == 'Hôm nay';
                          if (isToday) {
                            final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                            await _apiService.addMeal(
                              name: detectedName,
                              calories: estimatedCalories,
                              mealType: mealType,
                              date: todayStr,
                            );
                          }

                          // 3. Ép ứng dụng tải lại dữ liệu mới nhất từ Server để đồng bộ hiển thị
                          await ref.read(healthProvider.notifier).refreshAll();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Đã đồng bộ và cập nhật bữa ${mealType.toLowerCase()} thành món "$detectedName"!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (err) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Lỗi đồng bộ thực đơn: $err'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(
                        showWarning ? 'Xác nhận' : 'Lưu',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF949BA4) : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // --- OVERLAY POPUP CHATBOT 'TẠO THỰC ĐƠN AI' (CONTEXT-AWARE DIALOG FLOW) ---
  void _showAIChatbotDialog(HealthState healthState) {
    double bmi = 0.0;
    if (healthState.userData != null) {
      double h = (healthState.userData!['height'] ?? 0).toDouble();
      double w = (healthState.userData!['weight'] ?? 0).toDouble();
      if (h > 0 && w > 0) {
        bmi = w / ((h / 100) * (h / 100));
      }
    }

    final allergyController = TextEditingController();
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E), // Futuristic Dark Theme
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Trợ lý thiết lập Thực đơn AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A40),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🤖 Chào bạn! Tôi đã phân tích chỉ số sinh thể của bạn:\n• BMI hiện tại: ${bmi > 0 ? bmi.toStringAsFixed(1) : '22.5'} (Trạng thái cân đối).\n• Mục tiêu: Duy trì & Tăng cơ giảm mỡ.\n\nBạn có bị dị ứng hay cần kiêng cữ món ăn nào không? Hãy cho tôi biết để tôi thiết kế Thực đơn 7 ngày phù hợp nhất nhé!',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: allergyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'VD: "Tôi dị ứng hải sản", "Tôi ăn chay"...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF2A2A40),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              if (isGenerating) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.purpleAccent),
                      SizedBox(height: 12),
                      Text(
                        '🤖 Đang biên dịch thực đơn 7 ngày dạng JSON từ AI...',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

                PurpleGradientButton(
                  onPressed: () async {
                    setDialogState(() => isGenerating = true);
                    
                    try {
                       await ref.read(healthProvider.notifier).loadPlan(
                           allergies: allergyController.text, 
                           forceRefresh: true
                       );
                       
                       setDialogState(() => isGenerating = false);
                       Navigator.pop(context);
                       
                       setState(() {
                          _activeSegment = 0; // Chuyển về tab Hôm nay để xem bữa ăn mới tạo
                       });
                       
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                           content: Text('🎉 Thực đơn 7 ngày của bạn đã được AI tạo thành công!'),
                           backgroundColor: Colors.green,
                         ),
                       );
                    } catch (e) {
                       setDialogState(() => isGenerating = false);
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tạo thực đơn: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text(
                    'Tạo thực đơn ngay',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
