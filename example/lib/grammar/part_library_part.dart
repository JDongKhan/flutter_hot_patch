part of 'part_library.dart';

/// part 文件里的模型：与根文件同一命名空间，产物写在库根。
class PartModel {
  const PartModel(this.value);

  final int value;
}

/// part 里的公共顶层常量。
const String partTag = 'part-tag';

/// part 里的公共顶层函数（引用本库私有常量）。
String partSummary(PartModel model) => '$partTag:${model.value}/$_privateValue';

const String _privateValue = 'private-part';

/// 根文件调用的私有函数（跨 part 的私有符号）。
String _privatePartLabel() => 'private-fn(partTag=$partTag)';
