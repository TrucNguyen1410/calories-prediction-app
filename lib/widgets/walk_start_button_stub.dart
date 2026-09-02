// Bản cho native app (Android/iOS) — không có vấn đề "trusted user gesture"
// của trình duyệt nên chỉ cần nút Flutter bình thường, coi như luôn được phép.
import 'package:flutter/material.dart';
import '../theme.dart';

typedef PermissionResultCallback = void Function(bool granted);

class WalkStartButton extends StatelessWidget {
  const WalkStartButton({super.key, required this.onPermissionResult, required this.label});

  final PermissionResultCallback onPermissionResult;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PurpleGradientButton(
      onPressed: () => onPermissionResult(true),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}
