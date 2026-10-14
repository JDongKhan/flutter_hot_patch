// 临时：把注入的 JS 运行时整段源码落盘，供 `node --check` 做语法校验。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hot_patch/src/js_ui/runtime_source.dart';

void main() {
  test('dump runtime js', () {
    File('/tmp/jsui_runtime.js').writeAsStringSync(jsUiRuntimeSource());
  });
}
