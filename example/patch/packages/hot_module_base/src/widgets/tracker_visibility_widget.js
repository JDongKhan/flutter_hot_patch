// GENERATED CODE - DO NOT EDIT
// 跨包产物（package: hot_module_base）：由 dynamic_flutter_generator 生成
// 源文件：package:hot_module_base/src/widgets/tracker_visibility_widget.dart（一个源文件一份产物）

import { StatefulWidget, UniqueKey } from '../../../../flutter.js';
import { VisibilityDetector } from '../../../visibility_detector.js';

// 组件 TrackerVisibilityWidget
export class TrackerVisibilityWidget extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._hasExposure = false;
    this._visibilityKey = new UniqueKey();
  }
  __applyProps(args) {
    this.onExposure = (args && args.onExposure !== undefined) ? args.onExposure : null;
    this.child = (args && args.child !== undefined) ? args.child : null;
  }
  initState() {
    super.initState();
  }
  build(context) {
    return new VisibilityDetector({
      "onVisibilityChanged": (info) => { if (this._hasExposure) {
          return;
        }
        const isVisibleOnScreen = (((info.visibleFraction > 0) && (info.size.width > 0)) && (info.size.height > 0));
        if ((!isVisibleOnScreen)) {
          return;
        }
        this._hasExposure = true;
        const onExposure = this.onExposure;
        onExposure(); },
      "child": this.child,
      "key": this._visibilityKey
    });
  }
}
