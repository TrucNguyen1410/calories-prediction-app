import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme.dart';

enum AppToastType { success, error, warning, info }

/// Popup thông báo ngắn hiện Ở GIỮA màn hình (không phải SnackBar ở đáy màn hình),
/// tự động tắt sau [duration]. Dùng cho các thông báo một chiều (thành công/lỗi/info)
/// — KHÔNG dùng cho các trường hợp cần người dùng xác nhận/lựa chọn (vẫn dùng
/// showDialog/AlertDialog như bình thường cho các trường hợp đó).
class AppToast {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 5),
  }) {
    _dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (ctx) => _AppToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismissed: _dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);

    _timer = Timer(duration + const Duration(milliseconds: 250), _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (Color, IconData) _visualsFor(AppToastType type, bool isDark) {
    switch (type) {
      case AppToastType.success:
        return (const Color(0xFF3DBE7A), LucideIcons.checkCircle2);
      case AppToastType.error:
        return (const Color(0xFFE5484D), LucideIcons.alertCircle);
      case AppToastType.warning:
        return (const Color(0xFFF5A524), LucideIcons.alertTriangle);
      case AppToastType.info:
        return (isDark ? const Color(0xFFBB86FC) : AppTheme.primary, LucideIcons.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (accent, icon) = _visualsFor(widget.type, isDark);

    final bubble = Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2D31) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.18), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: accent.withOpacity(0.14), shape: BoxShape.circle),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned.fill(
      // Toàn bộ vùng nền trong suốt phải cho chạm xuyên qua (không được chặn
      // các nút phía sau như X/Kết thúc) — chỉ riêng khung bubble nhỏ ở giữa
      // mới thật sự nhận chạm (để bấm vào tắt sớm), nhờ IgnorePointer lồng
      // nhau: cái ngoài ignoring:true, cái trong ignoring:false tự ghi đè lại.
      child: IgnorePointer(
        ignoring: true,
        child: Align(
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: IgnorePointer(
                ignoring: false,
                child: GestureDetector(
                  onTap: () => _controller.reverse().whenComplete(widget.onDismissed),
                  child: bubble,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
