import 'package:flutter/cupertino.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';

import 'components/composite_component.dart';

/// @author jd

void registerAllNativeComponent() {
  jsWidgetRegistry.register(
    '_LabeledDivider',
    (c) => LabeledDivider(text: c.str('text') ?? '', child: c.children['child'] as Widget?),
  );
}
