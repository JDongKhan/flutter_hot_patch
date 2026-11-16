/// 方法 / 访问器 → JS 源码的**唯一**发射器。
///
/// 类体成员（`name(..) { }`、`get name() { }`）与对象字面量成员值
/// （`function (..) { }`、`{ get: .., set: .. }`）都从这里产出：
///   - 类的 `renderClassDecl` 负责前者；
///   - extension 的 `registerExtension(members)` 负责后者。
///
/// 生成器只有这一处规则（`sync*` → `*`，`async*` → 包 `Stream.fromAsyncGenerator`，
/// 因为裸异步生成器没有 `listen`）；`async`、访问器、运算符改名后的成员名同样
/// 不走第二条分支。新增成员形态只改本文件，类与 extension 同时生效。
library;

/// 方法体已经由收集阶段预渲染（含缩进），本层只做拼装。
///
/// 返回**函数表达式**（值形态）：`function (a, b) { … }` / `async function …` /
/// `function* …` / `async*` 的 `Stream` 包装。`this` 在调用时由调用方决定
/// （原型调用、`.call(接收者)` 都正确）。
String jsMethodValue({
  required List<String> params,
  required String body,
  bool isAsync = false,
  bool isGenerator = false,
}) {
  final p = params.join(', ');
  final b = body.trimRight();
  if (isGenerator && isAsync) {
    // `async*` 必须返回 Stream：生成器本体是 `async function*`，`.bind(this)`
    // 把方法体里的 `this` 固定到接收者（原型调用 / `.call(receiver)` 同一语义）。
    return 'function ($p) {\n'
        '    return Stream.fromAsyncGenerator((async function* () {\n'
        '$b\n'
        '    }).bind(this)());\n'
        '  }';
  }
  if (isGenerator) return 'function* ($p) {\n$b\n  }';
  final kw = isAsync ? 'async function' : 'function';
  return '$kw ($p) {\n$b\n  }';
}

/// 类体成员方法（含 static）。
String jsClassMember({
  required String name,
  required List<String> params,
  required String body,
  bool isStatic = false,
  bool isAsync = false,
  bool isGenerator = false,
}) {
  final st = isStatic ? 'static ' : '';
  final p = params.join(', ');
  final b = body.trimRight();
  if (isGenerator && isAsync) {
    // 方法形态不能写成 `async *name(..)`：裸异步生成器没有 listen，必须包 Stream；
    // 与值形态共用同一条语义（见 [jsMethodValue]）。
    return '  $st$name($p) {\n'
        '    return Stream.fromAsyncGenerator((async function* () {\n'
        '$b\n'
        '    }).bind(this)());\n'
        '  }';
  }
  final kw = isGenerator ? '*' : (isAsync ? 'async ' : '');
  return '  $st$kw$name($p) {\n$b\n  }';
}

/// 类体访问器（`get name()` / `set name(v)`）。Dart 的同名 get/set 在 JS 类体里
/// 是两个独立成员，天然共存。
String jsClassAccessor({
  required String name,
  required bool isGetter,
  required String body,
  List<String> setParams = const [],
  bool isStatic = false,
}) {
  final st = isStatic ? 'static ' : '';
  final b = body.trimRight();
  return isGetter
      ? '  ${st}get $name() {\n$b\n  }'
      : '  ${st}set $name(${setParams.join(', ')}) {\n$b\n  }';
}

/// 对象字面量里的访问器成员项（extension 静态成员表用，与类体访问器同一规则，
/// 只是不带类体缩进）：`get name() { … }` / `set name(v) { … }`。
String jsLiteralAccessor({
  required String name,
  required bool isGetter,
  required String body,
  List<String> setParams = const [],
}) {
  final b = body.trimRight();
  return isGetter
      ? 'get $name() {\n$b\n  }'
      : 'set $name(${setParams.join(', ')}) {\n$b\n  }';
}

/// 对象字面量里的访问器值：同名 get / set 合并成**一个**描述符。
///
/// extension 的成员表按名字存放，Dart 允许同时声明 `get value` 与 `set value`；
/// 若按「先写 get 项、再写 set 项」发射，后者会把前者覆盖掉（同名键只保留一个）。
/// 这里以名字为唯一槽位，两个方向都写进同一个 `{ get, set }`。
String jsAccessorValue({
  String? getBody,
  String? setBody,
  List<String> setParams = const [],
}) {
  final parts = <String>[
    if (getBody != null) 'get: function () {\n${getBody.trimRight()}\n    }',
    if (setBody != null)
      'set: function (${setParams.join(', ')}) {\n${setBody.trimRight()}\n    }',
  ];
  return '{ ${parts.join(', ')} }';
}
