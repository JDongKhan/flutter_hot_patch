import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 运算符语法 demo：自定义运算符重载（`+` / 一元 `-` / `==`）、setter，
/// 声明侧改写为 `__op$…` 成员 / JS 属性写访问器。
@PatchEntry('OperatorDetail')
class OperatorDetail extends StatelessWidget {
  const OperatorDetail({super.key});

  /// `+` / 一元 `-` / `==` 走 `__op$` 分派，`p.cents = v` 走 setter。
  ///
  /// hashCode 只验证**契约**（`a == b` ⇒ hash 相等），不比较原生 / JS 的原始
  /// 散列值——Dart 只保证同一执行内一致，跨运行时数值本来就不同。
  String _operatorText() {
    final Price a = Price(100);
    final Price b = Price(23);
    final Price total = a + b;
    total.cents = 150; // setter
    final Price sameValue = Price(150);
    final bool same = total == sameValue;
    final bool hashSame = total.hashCode == sameValue.hashCode;
    final Price neg = -b;
    return 'setter/运算符：sum=${total.cents} / 相等=$same / hash一致=$hashSame '
        '/ 取负=${neg.cents}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '运算符重载 · setter · == / hashCode',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_operatorText()),
      ],
    );
  }
}

class Price {
  Price(this._cents);

  int _cents;

  int get cents => _cents;

  /// setter → JS 属性写访问器 `set cents(v)`；`p.cents = v` 原样生效。
  set cents(int v) => _cents = v;

  Price operator +(Price other) => Price(_cents + other._cents);

  Price operator -() => Price(-_cents);

  bool operator ==(Object other) => other is Price && other._cents == _cents;

  int get hashCode => _cents.hashCode;
}
