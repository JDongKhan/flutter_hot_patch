// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/mount_fail_card.dart 自动生成
// 重新生成：dart run build_runner build

import { StateError, StatefulWidget, Text, WidgetsBinding } from '../flutter.js';

// 组件 MountFailCard
export class MountFailCard extends StatefulWidget {
  constructor(args) {
    super(args);
  }
  initState() {
    super.initState();
    WidgetsBinding.instance.addPersistentFrameCallback((_) => {});
    throw new StateError({message: "mount fail demo（预期错误：验证挂载失败回滚）"});
  }
  build(context) {
    return (this.__k0 || (this.__k0 = new Text({
      "data": "unreachable"
    })));
  }
}

