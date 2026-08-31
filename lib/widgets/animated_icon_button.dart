import 'package:flutter/material.dart';

/// Icon bấm có hiệu ứng nảy nhẹ (scale bounce) khi ấn xuống/thả ra — dùng thay
/// cho `IconButton` thông thường ở MỌI icon có thể bấm trong app, để đồng bộ
/// cảm giác tương tác giống concept mẫu (icon "di chuyển" khi chạm).
///
/// Cách dùng: thay `IconButton(icon: Icon(x), onPressed: y, tooltip: z, color: c)`
/// bằng `AnimatedIconButton(icon: x, onPressed: y, tooltip: z, color: c)`.
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.8).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null) _controller.forward();
  }

  void _onTapEnd() {
    if (_controller.isAnimating || _controller.value != 0) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? IconTheme.of(context).color;
    final effectiveColor = widget.onPressed == null ? iconColor?.withOpacity(0.38) : iconColor;

    Widget child = AnimatedBuilder(
      animation: _scale,
      builder: (context, iconChild) => Transform.scale(scale: _scale.value, child: iconChild),
      child: Icon(widget.icon, size: widget.size, color: effectiveColor),
    );

    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: (_) => _onTapEnd(),
      onTapCancel: _onTapEnd,
      onTap: widget.onPressed,
      child: Padding(padding: widget.padding, child: child),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }

    return child;
  }
}
