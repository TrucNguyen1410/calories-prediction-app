// Nút "Bắt đầu" bằng phần tử <button> HTML gốc, không phải widget Flutter —
// bắt buộc phải làm vậy vì DeviceMotionEvent.requestPermission() trên Safari
// (iPhone) chỉ được chấp nhận khi gọi ĐỒNG BỘ, ngay trong 1 sự kiện click DOM
// thật do người dùng chạm. Nút Flutter thường đi qua bộ máy xử lý cử chỉ
// (gesture arena) riêng của Flutter nên tới lúc gọi JS thì Safari đã không
// còn coi đó là thao tác người dùng đáng tin nữa, âm thầm không cấp quyền dù
// promise vẫn resolve — đây là nguyên nhân cảm biến chỉ nhận đúng 1 mẫu rồi
// im bặt trong lần thử trước.
//
// Dùng dart:html (đã deprecated từ Dart 3.7 nhưng vẫn biên dịch tốt với
// dart2js — pipeline build web hiện tại của dự án dùng dart2js, không dùng
// --wasm) thay vì package:web vì API tạo/gắn sự kiện cho phần tử đơn giản và
// ít rủi ro sai cú pháp hơn nhiều so với static interop kiểu mới.
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';
import 'package:flutter/material.dart';

@JS('requestMotionPermission')
external JSPromise<JSBoolean> _requestMotionPermissionJS();

typedef PermissionResultCallback = void Function(bool granted);

class WalkStartButton extends StatefulWidget {
  const WalkStartButton({super.key, required this.onPermissionResult, required this.label});

  final PermissionResultCallback onPermissionResult;
  final String label;

  @override
  State<WalkStartButton> createState() => _WalkStartButtonState();
}

class _WalkStartButtonState extends State<WalkStartButton> {
  static int _counter = 0;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'walk-start-native-btn-${_counter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final button = html.ButtonElement()
        ..text = widget.label
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.borderRadius = '16px'
        ..style.background = 'linear-gradient(135deg, #BB86FC, #8A2BE2)'
        ..style.color = '#FFFFFF'
        ..style.fontWeight = 'bold'
        ..style.fontSize = '15px'
        ..style.fontFamily = 'inherit'
        ..style.cursor = 'pointer';

      button.onClick.listen((_) {
        // Gọi NGAY, đồng bộ, ngay dòng đầu trong callback click DOM gốc —
        // không được await/delay gì trước dòng này.
        _requestMotionPermissionJS().toDart.then((jsGranted) {
          widget.onPermissionResult(jsGranted.toDart);
        });
      });

      return button;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
