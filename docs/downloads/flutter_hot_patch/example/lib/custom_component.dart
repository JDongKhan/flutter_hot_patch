import 'package:flutter/cupertino.dart';
import 'package:hot_patch/hot_patch.dart';

import 'components/composite_component.dart';

/// @author jd

void registerAllNativeComponent() {
  jsWidgetRegistry.register(
    '_LabeledDivider',
    (c) => LabeledDivider(text: c.str('text') ?? '', child: c.children['child'] as Widget?),
  );
}
