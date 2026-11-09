/// `import ... show` 覆盖载体：使用方只引入 [ShownModel] / [shownConst] /
/// [shownGreeting]，未 show 的 [NotShownModel] / [notShownConst] 不进入可见符号表。
library;

const String shownConst = 'shown';

const String notShownConst = 'not-shown';

String shownGreeting() => 'show-greeting';

String notShownGreeting() => 'not-shown-greeting';

class ShownModel {
  const ShownModel(this.value);

  final int value;
}

class NotShownModel {
  const NotShownModel(this.value);

  final int value;
}
