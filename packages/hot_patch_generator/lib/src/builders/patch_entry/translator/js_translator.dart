import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart' show log;

import '../class_info.dart';
import '../../shared/ctor_signatures.dart';
import '../../shared/runtime_global_types.dart';
import '../../shared/sdk_enum_index.dart';
import '../../shared/source_location.dart';
import 'js_value.dart';

// ===========================================================================
// 表达式 / 语句翻译：Dart 语言 → JS 语言
//
// 只做语言层转换，不认识 widget / 组件，也不承担类结构收集：
//   - 类结构模型见 class_info.dart；
//   - 字面量 / 作用域 / SDK 映射等共享值工具见 js_value.dart；
//   - 本文件负责：exprToJs / rhsToJs / methodCallExprJs / closureToJs /
//     exprStmtToJs / translateStmtList / translateMethodBody /
//     translateClassMethodBody 等表达式与语句翻译。
//
// 依赖方向单向、无环：analyze_dart_class / dart2js / element2js → 本文件。
// 新增一门表达式 / 语句语法只改本文件，各调用方同时生效。
//
// 唯一的「向上」缝：方法体里 `return Container(...)` 需要 widget 层参与，
// 用 js_value.dart 的 [ExprRenderer] 接口解耦——本文件只依赖接口，
// 由 element2js 实现。
// ===========================================================================

// ---------------------------------------------------------------------------
// 表达式 / 语句翻译（以 FieldScope + 已知类表为键）
// ---------------------------------------------------------------------------


/// 已告警过的「带常量参数、未生成 JS 值类」的 SDK 枚举（同一次构建只出声一次）。
final Set<String> _warnedUnsupportedEnums = {};

/// 产物里引用到未生成值类的 SDK 枚举时出声。
///
/// 这类枚举（`enum E { a(1) }`）无法在 JS 侧还原常量参数语义，`flutter.js` 不
/// 生成同名类；产物里的 `E.member` 因此是未定义引用。索引阶段对整包 SDK 保持
/// 安静（绝大多数枚举项目不引用），只在**真正命中**时告警，避免刷屏。
void _warnUnsupportedSdkEnum(String owner) {
  final file = sdkUnsupportedEnums()[owner];
  if (file == null) return;
  if (!_warnedUnsupportedEnums.add(owner)) return;
  log.warning('[hot_patch_generator] 引用了带常量参数的 SDK 枚举 $owner'
      '（$file）：未生成 JS 值类，产物里 `$owner.xxx` 是未定义引用'
      '（需补能力模块或改用常量）');
}

// Dart 集合 / 字符串 / 数字的同名成员（`first` / `where` / `add` / `compareTo` …）
// **不在生成器做名字映射**：生成器看不到接收者类型，按名字改写会把同名业务方法
// 静默改错。统一原样产出 `x.first` / `x.where(...)` / `x.add(...)`，由运行时
//【1c】节给 Array / Number / String 内建原型补同名同义成员，按接收者类型分发。

/// 读位置表达式 → JS 表达式（this._model.n / this._model / 字面量 / 形参）。
String? exprToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // 函数表达式（闭包）本身就是表达式：变量初始化器、实参、三元分支等位置
  // 统一在这里翻译，可选 / 具名形参与默认值由 [closureToJs] 同一实现处理。
  if (e is FunctionExpression) return closureToJs(e, scope, classes);
  // 显式 extension 调用 `E(x).m(args)`：必须在构造翻译之前拦截——[valueCtorJs]
  // 会把 `E(x)` 当成 `new E({...})` 构造（E 是扩展名，不是类）。改写为
  // `x.m(args)`：成员已由 `registerExtension` 装在目标原型上。
  if (e is MethodInvocation) {
    // 显式扩展调用：按**扩展身份**分派（`E.m.call(x, …)`），不走原型。
    final explicit = _explicitExtensionCallJs(e, scope, classes);
    if (explicit != null) return explicit;
  }
  // 显式扩展 getter：`E(x).g` → `E.g.get.call(x)`。
  final explicitGetter = _explicitExtensionGetterJs(e, scope, classes);
  if (explicitGetter != null) return explicitGetter;
  // 构造表达式（`Color(0xFF…)` / `Color.fromARGB(…)` / 任意 `X(…)`）→
  // `new X({...})`（命名构造 `X.b({...})` 仅在签名表命中时接管）。
  // 颜色不是特殊形态：`Color` 与其它类一样由运行时注入同名类。
  final ctorJs = valueCtorJs(e, scope, classes);
  if (ctorJs != null) return ctorJs;
  // Platform.isAndroid 等（PrefixedIdentifier 是 Identifier 子类，必须先判）
  if (e is PrefixedIdentifier && e.prefix.name == 'Platform') {
    final flag = platformFlagJs(e.identifier.name);
    if (flag != null) return flag;
  }
  // 通用 `a.b`：前缀与属性都是简单标识符时 analyzer 用 PrefixedIdentifier
  // （不是 PropertyAccess），如 `ids.length` / `_user.name` / `m.keys`。
  // 不在这里拦下来，它会落到下面的 Identifier 分支，用整串 `a.b` 去查字段
  // 必然失败——这是「属性访问普遍翻译不出来」的根因。
  if (e is PrefixedIdentifier) {
    // State 内 `widget.x`（访问 widget 自身字段）→ 合并类的实例属性 `this.x`：
    // widget 与 State 在 JS 侧是同一个类，widget 字段即实例字段。
    if (e.prefix.name == 'widget') {
      return scope.fieldRef(e.identifier.name);
    }
    // 其余 `Owner.member` 一律按通用规则原样保留（`Icons.edit` → `Icons.edit`，
    // 由 flutter.js 的同名常量表承接）。这里不能再按 owner 名字做特判：
    // 曾把 `Icons.xxx` 硬编码成图标名字符串，等于按类名白名单翻译。
    final p = scope.fieldRef(e.prefix.name);
    String? base;
    if (p != null) {
      base = p;
    } else if (scope.globalConsts.contains(e.prefix.name)) {
      // 前缀是顶层常量（如 `kOrderStatus.first`）→ JS 侧同名模块级常量。
      base = e.prefix.name;
    } else if (runtimeGlobalNamespaces().contains(e.prefix.name)) {
      // 前缀是运行时注入的小写命名空间（如 `double.infinity`）→ 同名模块导出。
      base = e.prefix.name;
    } else if (e.prefix.name.isNotEmpty &&
        RegExp(r'^[A-Z]').hasMatch(e.prefix.name)) {
      // prefix 是大写开头的外部类名（如 Network.post）→ 原样保留。
      _warnUnsupportedSdkEnum(e.prefix.name);
      base = e.prefix.name;
    }
    if (base == null) return null;
    final member = _mapPropertyMember(e.prefix, e.identifier.name, scope, classes);
    // `obj.method` 值位置：方法 tear-off 需绑定接收者（getter 是值读取；
    // 类型不可判定时保持原样，不按名字猜）。
    final tear = _tearOffMemberJs(
      receiverJs: base,
      receiver: e.prefix,
      member: member,
      scope: scope,
      classes: classes,
    );
    return tear ?? '$base.$member';
  }
  // StringInterpolation 是 StringLiteral 子类，必须先判（否则被字面量分支
  // 吞成 ""——插值表达式丢失）。
  if (e is StringInterpolation) return _stringInterpolationJs(e, scope, classes);
  // 相邻字符串字面量（`'a' 'b'`）→ `+` 拼接。
  if (e is AdjacentStrings) {
    final parts = <String>[];
    for (final s in e.strings) {
      final v = exprToJs(s, scope, classes);
      if (v == null) return null;
      parts.add(v);
    }
    return parts.join(' + ');
  }
  // `throw` 出现在**表达式位置**（`a ?? throw e` / 三目分支 / 实参 / switch
  // 表达式分支）：JS 没有 throw 表达式，落成「立即抛出的 IIFE」；语句位置仍由
  // [exprStmtToJs] 产出原生 `throw ...;`（箭头体见 [closureToJs] 的语句体路径）。
  if (e is ThrowExpression) {
    final v = rhsToJs(e.expression, scope, classes);
    return v == null ? null : '(() => { throw $v; })()';
  }
  // 赋值出现在**表达式位置**（`while ((x = f()) < n)` / `if ((v = f()) != null)`）：
  // 统一走 [_assignValueJs]（值语义见该函数；语句位置仍是 [exprStmtToJs]）。
  if (e is AssignmentExpression) return _assignValueJs(e, scope, classes);
  // `a ?? b` → JS 原生空值合并（方法体内如 `_switchOn = v ?? false`）
  if (e is BinaryExpression && e.operator.lexeme == '??') {
    final l = exprToJs(e.leftOperand, scope, classes);
    final r = exprToJs(e.rightOperand, scope, classes);
    if (l == null || r == null) return null;
    return '($l ?? ${_fnParen(r, e.rightOperand)})';
  }
  // 比较 / 逻辑 / 算术二元运算：一比一翻译（条件、循环、三目、数据绑定都用得到；
  // 组件数据表达式与模型方法体共用这一处，不再各写一套）。
  if (e is BinaryExpression) {
    final op = e.operator.lexeme;
    // 类型值比较（`T == String` / `T != int`）：任一侧是类型参数时进入专用分支，
    // 两侧都按「类型名」翻译（T 读 `this.__ta["T"]`，`String` → `"String"`）。
    // 判据只看操作数是不是作用域登记的类型参数，不按类名 / 方法名判断。
    if ((op == '==' || op == '!=') &&
        (_isTypeParamOperand(e.leftOperand, scope) ||
            _isTypeParamOperand(e.rightOperand, scope))) {
      final l = _typeValueJs(e.leftOperand, scope, classes) ??
          exprToJs(e.leftOperand, scope, classes);
      final r = _typeValueJs(e.rightOperand, scope, classes) ??
          exprToJs(e.rightOperand, scope, classes);
      if (l != null && r != null) return '($l $op $r)';
    }
    if (const <String>{
      '>', '<', '>=', '<=', '==', '!=', '&&', '||', '+', '-', '*', '/',
      // 位运算与移位：JS 同名运算符语义一致（`>>` 算术右移、`>>>` 无符号右移）。
      // 数值口径随运行时（Dart int 在 JS 侧就是 number），按 32 位位宽参与运算。
      '&', '|', '^', '<<', '>>', '>>>'
    }.contains(op)) {
      final l = exprToJs(e.leftOperand, scope, classes);
      final r = exprToJs(e.rightOperand, scope, classes);
      if (l == null || r == null) return null;
      // 运算符重载：只有左操作数静态类型可判定、且该类型声明了对应运算符时才
      // 改写成 `l.__op$xxx(r)`；否则保持 JS 原生运算（Dart 未重载的类型本就如此）。
      final owner = _operatorOwnerOf(e.leftOperand, op, scope, classes);
      if (owner != null) {
        if (op == '==' || op == '!=') {
          // Dart 的 `==` 是方法调用：接收者为 null 时走 null 的 ==（不等于
          // 任何非空值）。两侧先求值一次，再判空 / 分派（`== null` 同时命中
          // null 与 undefined，不在此处额外归一）。
          final neg = op == '!=' ? '!' : '';
          return '$neg((__a, __b) => __a == null ? __b == null '
              ': __a.${operatorJsName('==', unary: false)}'
              '(__b))($l, $r)';
        }
        final jsOp = operatorJsName(op, unary: false);
        if (jsOp != null) return '$l.$jsOp($r)';
      }
      // extension 运算符：静态类型命中 extension 的 `on` 目标时，同样落成
      // `receiver.__op$xxx(rhs)`（成员由 `registerExtension` 装到目标原型上）。
      final extOp = extensionOperatorMember(
        scope.extensionOperators,
        _staticTypeOf(e.leftOperand, scope, classes),
        op,
      );
      if (extOp != null) return '$l.$extOp($r)';
      // 判空 / 相等：Dart 只有 null，JS 有 null 与 undefined —— 两侧先 `__nn`
      // 归一（undefined → null），判空保持 `== null`（禁止 `=== null`），
      // 其余相等用严格相等，避免 JS 宽松相等做类型转换。
      if (op == '==' || op == '!=') {
        final leftNull = e.leftOperand is NullLiteral;
        final rightNull = e.rightOperand is NullLiteral;
        if (leftNull || rightNull) {
          final otherExpr = leftNull ? e.rightOperand : e.leftOperand;
          final otherJs = leftNull ? r : l;
          // 判空：只有另一侧**可能为空**时才包 `__nn`（非空类型的字段 / 形参、
          // 字面量、构造等不会产出 undefined，不归一）。
          final wrapped = _mayBeNull(otherExpr, scope, classes)
              ? '__nn(${_fnParen(otherJs, otherExpr)})'
              : otherJs;
          return '($wrapped $op null)';
        }
        // 非判空相等：Dart 的 `==` 语义要求两侧都按「空值只有一个」比较。
        // **只要有一侧确定非空**（字面量 / 非空类型 / 构造等），另一侧的
        // null 与 undefined 对比较结果完全一致（都 `!==` 该非空值），不需要
        // 归一；只有两侧都可能为空时，才需要把 undefined 归一成 null
        // （否则 `null === undefined` 会与 Dart 的 `null == null` 不一致）。
        final strict = op == '==' ? '===' : '!==';
        if (!_mayBeNull(e.leftOperand, scope, classes) ||
            !_mayBeNull(e.rightOperand, scope, classes)) {
          return '($l $strict $r)';
        }
        final lw = '__nn(${_fnParen(l, e.leftOperand)})';
        final rw = '__nn(${_fnParen(r, e.rightOperand)})';
        return '($lw $strict $rw)';
      }
      return '(${_fnParen(l, e.leftOperand)} $op ${_fnParen(r, e.rightOperand)})';
    }
    // Dart `%` 是欧几里得取模（结果非负），JS `%` 是截断余数（`-7 % 3 == -1`）。
    if (op == '%') {
      final l = exprToJs(e.leftOperand, scope, classes);
      final r = exprToJs(e.rightOperand, scope, classes);
      if (l == null || r == null) return null;
      final extOp = extensionOperatorMember(
        scope.extensionOperators,
        _staticTypeOf(e.leftOperand, scope, classes),
        op,
      );
      if (extOp != null) return '$l.$extOp($r)';
      return '__mod(${_fnParen(l, e.leftOperand)}, '
          '${_fnParen(r, e.rightOperand)})';
    }
    // Dart 整除 `a ~/ b`：JS 无对应运算符，转「向零取整」的除法。
    // 必须用 Math.trunc 而不是 Math.floor：Dart 的 `~/` 向零截断
    // （`-3 ~/ 2 == -1`），Math.floor 对负数会向下取整得到 -2。
    if (op == '~/') {
      final l = exprToJs(e.leftOperand, scope, classes);
      final r = exprToJs(e.rightOperand, scope, classes);
      if (l == null || r == null) return null;
      return 'Math.trunc(${_fnParen(l, e.leftOperand)} / '
          '${_fnParen(r, e.rightOperand)})';
    }
  }
  // 级联 `target..m(a)..n(b)`：Dart 返回 target 本身。译成 IIFE：
  // `(() => { const _t = <target>; _t.m(a); _t.n(b); return _t; })()`。
  // 常见形态 `list..sort(cmp)`（原方法体内就地排序）与 `c..addListener(..)`，
  // 顺序与返回值都与 Dart 一致。空安全形态 `a?..b()` 见下方入口守卫。
  if (e is CascadeExpression) {
    final t = exprToJs(e.target, scope, classes);
    if (t == null) return null;
    // 级联 target 的根级下标读写：Map → get/set；类型不可判定 → 运行时
    // `__idx` / `__idxSet`（Map 与普通对象都可用）。
    final cascadeType = _staticTypeOf(e.target, scope, classes);
    final stmts = <String>[];
    for (final s in e.cascadeSections) {
      if (s is MethodInvocation) {
        final argsJs = <String>[];
        for (final a in s.argumentList.arguments) {
          final inner = a is NamedExpression ? a.expression : a;
          final v = inner is FunctionExpression
              ? closureToJs(inner, scope, classes)
              : rhsToJs(inner, scope, classes);
          if (v == null) return null;
          argsJs.add(v);
        }
        stmts.add('_t.${_memberCallName(e.target, s.methodName.name, scope, classes)}'
            '(${argsJs.join(', ')})');
      } else if (s is AssignmentExpression) {
        // 级联里**赋值** `..x = v` / `..[i] = v` / `..x += v`：目标链以 `_t`
        // 为根（级联 target 已只求值一次），落成 IIFE 内的一条语句；赋值结果
        // 不作为级联结果（级联结果恒为 target 本身）。`~/=` 与普通赋值位置的
        // 展开口径一致。
        final lhs = s.leftHandSide;
        final op = s.operator.lexeme;
        final rhs = rhsToJs(s.rightHandSide, scope, classes);
        if (rhs == null) return null;
        if (op == '=' &&
            lhs is IndexExpression &&
            lhs.target == null &&
            cascadeType == 'Map') {
          final idx = exprToJs(lhs.index, scope, classes);
          if (idx == null) return null;
          stmts.add('__idxSet(_t, $idx, $rhs)');
          continue;
        }
        final ref = _cascadeRefJs(lhs, scope, classes);
        if (ref == null) return null;
        stmts.add(op == '~/='
            ? '$ref = Math.trunc($ref / $rhs)'
            : '$ref $op $rhs');
      } else if (s is PropertyAccess ||
          s is IndexExpression) {
        // 级联里**读**访问 `..x` / `..a.b` / `..[i]`：同样以 `_t` 为根展开，
        // 多级链（`..a.b`）不会丢掉中间层。
        if (s is IndexExpression && s.target == null && cascadeType == 'Map') {
          final idx = exprToJs(s.index, scope, classes);
          if (idx == null) return null;
          stmts.add('__idx(_t, $idx)');
          continue;
        }
        final ref = _cascadeRefJs(s, scope, classes);
        if (ref == null) return null;
        stmts.add(ref);
      } else {
        return null;
      }
    }
    // 空安全级联 `a?..b()..c()`：目标为 null / undefined 时**整条级联短路**，
    // 表达式求值为目标本身（null），后续 section 一律不执行。JS 没有等价的
    // 可选链 + 级联组合语法，故在 IIFE 入口加一层非空守卫。
    if (e.isNullAware) {
      return '((_t) => { if (_t == null) return _t; '
          '${stmts.join('; ')}; return _t; })($t)';
    }
    return '(() => { const _t = $t; ${stmts.join('; ')}; return _t; })()';
  }
  // 三目 `c ? a : b`（组件数据/样式与模型方法体共用）。
  if (e is ConditionalExpression) {
    final c = exprToJs(e.condition, scope, classes);
    final t = exprToJs(e.thenExpression, scope, classes);
    final f = exprToJs(e.elseExpression, scope, classes);
    if (c == null || t == null || f == null) return null;
    return '($c ? ${_fnParen(t, e.thenExpression)} '
        ': ${_fnParen(f, e.elseExpression)})';
  }
  // switch 表达式（Dart 3）→ IIFE + JS switch（JS 无 switch 表达式语法）。
  if (e is SwitchExpression) return _switchExpressionJs(e, scope, classes);
  // 类型判断 `x is T` / `x is! T`：按 Dart 语义映射成 JS 判别（见 typeTestJs）。
  // 类型在 JS 侧不可解析时整条不翻译，避免产出 `instanceof <未定义>`。
  if (e is IsExpression) {
    final v = exprToJs(e.expression, scope, classes);
    if (v == null) return null;
    final test = typeTestJs(
      e.type.toSource(),
      v,
      knownClasses: classes.keys.toSet(),
    );
    if (test == null) return null;
    return e.notOperator == null ? '($test)' : '(!$test)';
  }
  // `x as T`：类型断言在 JS 侧无运行时语义（Dart 泛型擦除），**目标类型是
  // 类型参数**时直接擦除断言（`value as T` → `value`）；其它具体类型的断言
  // 仍按原策略不翻译（保持既有行为，不静默放宽）。
  if (e is AsExpression) {
    if (scope.typeParams.containsKey(e.type.toSource().trim())) {
      return exprToJs(e.expression, scope, classes);
    }
    return null;
  }
  // `this`（如 `TabController(length: n, vsync: this)`）：JS 侧方法/构造实参里
  // 的 this 就是组件实例，一比一透传；Dart 侧专属的实参（vsync）由 JS 代理类
  // 构造自行忽略。
  if (e is ThisExpression) return scope.thisRef;
  // `super`：只能作为成员访问 / 调用的接收者出现（Dart 语法限制，JS 的 class
  // 语法完全同形）。属性读取 `super.x` 走下面的 `a.b` 分支拼成 `super.x`；
  // 方法调用 `super.m()` 由 `_methodCallJs` 的 SuperExpression 分支处理；
  // `super.x = v` 由 `_assignValueJs` 直接发射（super 不是值，不能作 IIFE 参数）。
  if (e is SuperExpression) return 'super';
  if (e is Identifier) {
    // 类型参数（`T` / `E`）：Dart 里是类型值，JS 侧读实例保存的类型名元信息。
    final tp = scope.typeParams[e.name];
    if (tp != null) return tp;
    // kDebugMode / kReleaseMode → 运行时注入的全局标志
    final flag = globalFlagJs(e.name);
    if (flag != null) return flag;
    // State.mounted：JS 组件基类有 __unmounted 标记，未卸载即视为已挂载
    if (e.name == 'mounted') return '!this.__unmounted';
    // 顶层常量（如 `kBanners`）：JS 侧是同名模块级常量，原样引用。
    if (scope.globalConsts.contains(e.name)) return e.name;
    // 运行时注入的小写命名空间（`int.parse` / `num.parse` 的接收方）：
    // JS 侧是同名模块导出对象，原样引用（不是构造函数，不走 instanceof）。
    if (runtimeGlobalNamespaces().contains(e.name)) return e.name;
    final ref = scope.fieldRef(e.name);
    if (ref != null) return ref;
    // `State.context`：方法体里没有 `context` 形参时（`_open() { showDialog(
    // context: context, …) }`），裸 `context` 就是 State 继承来的实例成员。
    // 运行时每个组件的原型上都有 `context` getter（按执行位置返回代理，见
    // build_context_js），故落成 `this.context`。只在**其余解析都落空**时兜底
    // （形参 / 局部变量 / 字段已在上面返回，不会被它抢走）。
    if (e.name == 'context') return 'this.context';
    return null;
  }
  // null 字面量（`data ?? null` 等）：只影响表达式位置，字段默认值仍走
  // literalToJs 的 undefined 语义，故不并入 literalToJs。
  if (e is NullLiteral) return 'null';
  final lit = literalToJs(e);
  if (lit != null) return lit;
  if (e is PropertyAccess && e.target is Identifier &&
      (e.target as Identifier).name == 'Platform') {
    // Platform.isAndroid 等 → 运行时注入的平台标志
    final flag = platformFlagJs(e.propertyName.name);
    if (flag != null) return flag;
  }
  // `super.x`：父类**字段**在 JS 侧是实例属性（父类构造里 `this.x = …`），
  // 而 `super.x` 只沿父类**原型**查找，读不到实例属性；故字段落成 `this.x`。
  // getter / 方法定义在原型上，保持 `super.x`（子类 override 时语义才与 Dart 一致）。
  // 判据是源码事实：该名字是否在继承链字段视图（[FieldScope.instanceFields]
  // 本身就是 objectFieldsOf 的「含父类字段」视图）。
  if (e is PropertyAccess && e.target is SuperExpression) {
    final name = e.propertyName.name;
    if (scope.instanceFields.contains(name)) return 'this.$name';
    // 基类在 JS 侧没有实现（类声明里不会写 extends）时，发射 super 是语法错误。
    if (!scope.hasJsBase) return null;
    // 方法 tear-off（`super.m` 作为值）：取到的是原型方法，this 仍是当前实例，
    // 需显式绑定；getter 是值读取，保持 `super.x`。
    if (scope.methods.contains(name) && !scope.getterNames.contains(name)) {
      return 'super.$name.bind(this)';
    }
    return 'super.$name';
  }
  if (e is PropertyAccess && e.target != null) {
    final t = exprToJs(e.target!, scope, classes);
    if (t == null) return null;
    final member = _mapPropertyMember(e.target!, e.propertyName.name, scope, classes);
    // 空安全属性访问 `a?.b` → JS 原生可选链：与 Dart 源码 1:1，且链式
    // （`a?.b?.c` / `a?.b.c`）的「接收者单次求值 + 整链短路」由 JS 语义天然
    // 保证。旧的 `($t == null ? null : $t.b)` 展开在链上会重复求值接收者，
    // 且 `a?.b.c` 丢失整链短路（a 为 null 时直接 TypeError）。
    if (e.operator.lexeme == '?.') {
      // `a?.m`（方法 tear-off）：a 为 null 时整链短路；方法判定同普通成员。
      final tear = _tearOffMemberJs(
        receiverJs: t,
        receiver: e.target!,
        member: member,
        scope: scope,
        classes: classes,
        nullAware: true,
      );
      return tear ?? '$t?.$member';
    }
    // `obj.method` 值位置：方法 tear-off 绑定接收者（与 PrefixedIdentifier 同一实现）。
    final tear = _tearOffMemberJs(
      receiverJs: t,
      receiver: e.target!,
      member: member,
      scope: scope,
      classes: classes,
    );
    return tear ?? '$t.$member';
  }
  // 下标访问 `a[b]`（如 `userMap["code"]`）：JS 的方括号语法一一对应。
  // 与上面的通用 `a.b` 同理，不在 exprToJs 里兜住就会整条翻译失败（在插值里
  // 表现为片段被丢弃，如 `"用户信息:${userMap["code"]}"` → `"用户信息:"`）。
  if (e is IndexExpression) {
    final tgt = e.target;
    if (tgt == null) return null;
    final t = exprToJs(tgt, scope, classes);
    final i = exprToJs(e.index, scope, classes);
    if (t == null || i == null) return null;
    // `operator []`：接收者静态类型声明了下标运算符时改写成成员调用。
    if (_operatorOwnerOf(tgt, '[]', scope, classes) != null) {
      final get = operatorJsName('[]', unary: false)!;
      return e.isNullAware ? '$t?.$get($i)' : '$t.$get($i)';
    }
    // extension `operator []`：目标类型命中时同样落成员调用。
    final extGet = extensionOperatorMember(
      scope.extensionOperators,
      _staticTypeOf(tgt, scope, classes),
      '[]',
    );
    if (extGet != null) {
      return e.isNullAware ? '$t?.$extGet($i)' : '$t.$extGet($i)';
    }
    // Map 下标：原生 JS Map 只有 `get`；但声明为 Map 的值也可能来自宿主回包
    // （普通对象），故统一走 `__idx`（Map → get，普通对象 → 下标）。
    // 其它类型（List / 项目类 / 不可判定）**一律保持原生下标**。
    final type = _staticTypeOf(tgt, scope, classes);
    // `a?[i]` → JS 原生可选下标 `a?.[i]`：接收者为 null / undefined 时整个
    // 表达式短路，且下标**不求值**（与 Dart 语义一致）。这里不能包 `__nn`：
    // 可选链可能继续被外层选择器链住（`a?[i].x` 在 a 为 null 时应整链短路）。
    if (e.isNullAware) {
      return type == 'Map' ? '$t?.get($i)' : '$t?.[$i]';
    }
    if (type == 'Map') return '__idx($t, $i)';
    // Map 未命中的 undefined → null 归一放在**值位置**（初始化器 / 赋值右侧 /
    // 实参 / 返回 / 插值，见 [rhsToJs] / [_stringInterpolationJs]），不在读取
    // 本身统一包：`for (x of m[k])` 对 null 与 undefined 同样 TypeError，包了
    // 没有意义；判断位置由相等比较分支按可空性包。
    return '$t[$i]';
  }
  if (e is ParenthesizedExpression) {
    final inner = exprToJs(e.expression, scope, classes);
    return inner == null ? null : '($inner)';
  }
  // 自增/自减（表达式位置，如 for 更新子 `i++`）。Postfix `!` 是 Dart null
  // 断言：项目口径直接取操作数（不额外抛错；访问位置由 JS 自然抛 TypeError，
  // 独立值位置不校验）。`a?[i]++` / `a?.x++` 的写入目标含可选链，JS 不允许，
  // 落成接收者单次求值的守卫 IIFE。
  if (e is PostfixExpression) {
    final op = e.operator.lexeme;
    if (op == '!') {
      return exprToJs(e.operand, scope, classes);
    }
    if ((op == '++' || op == '--') && _chainHasNullAware(e.operand)) {
      return _nullAwareUpdateJs(
          e.operand, op, scope, classes, prefix: false);
    }
    final v = exprToJs(e.operand, scope, classes);
    if (v == null) return null;
    return '($v$op)';
  }
  // 前缀一元（`!flag` / `-n` / `++i` / `--i`）。
  if (e is PrefixExpression) {
    final op = e.operator.lexeme;
    if ((op == '++' || op == '--') && _chainHasNullAware(e.operand)) {
      return _nullAwareUpdateJs(e.operand, op, scope, classes, prefix: true);
    }
    final v = exprToJs(e.operand, scope, classes);
    if (v == null) return null;
    // `operator -()`（一元取负）：操作数静态类型声明了它 → 成员调用。
    if (op == '-' &&
        _operatorOwnerOf(e.operand, '-', scope, classes, unary: true) != null) {
      return '$v.${operatorJsName('-', unary: true)}()';
    }
    // extension 一元运算符：目标类型命中时 → `receiver.__op$neg()`。
    final extUnary = extensionOperatorMember(
      scope.extensionOperators,
      _staticTypeOf(e.operand, scope, classes),
      op,
    );
    if (extUnary != null) return '$v.$extUnary()';
    return '($op${_fnParen(v, e.operand)})';
  }
  if (e is MethodInvocation) return methodCallExprJs(e, scope, classes);
  // 函数值调用 `(f)(args)` / `((x) => x)(v)`：AST 是 FunctionExpressionInvocation
  //（普通 `f(...)` 是 MethodInvocation，已由上一行处理）。
  if (e is FunctionExpressionInvocation) {
    return _fnValueCallJs(e, scope, classes);
  }
  // 集合字面量：与 rhsToJs 共用同一对实现（ListLiteral / SetOrMapLiteral）。
  // 任意表达式位置都可能出现（`for (final x in ['a', 'b'])` 的迭代源、三元
  // 分支、函数实参、`??` 右操作数……），缺了会让外层整条表达式翻不出来。
  if (e is RecordLiteral) return _recordLiteralJs(e, scope, classes);
  if (e is SetOrMapLiteral) return _collectionLiteralJs(e, scope, classes);
  if (e is ListLiteral) return _listLiteralJs(e.elements, scope, classes);
  return null;
}

/// 闭包作为**运算符操作数**时必须加括号：`a ?? (v) => v` 在 JS 里是语法错误
///（箭头函数优先级低于 `??` / 二元运算 / 三目）。只在这种位置加；实参 /
/// 数组元素 / return / 赋值右侧等位置保持原样（可读性优先）。
String _fnParen(String js, Expression e) =>
    e is FunctionExpression ? '($js)' : js;

/// 函数值调用 `(f)(args)` / `((x) => x)(v)`（AST: [FunctionExpressionInvocation]）。
///
/// 与会话约定一致：位置实参在前、具名实参合并成一个尾参对象；闭包实参走
/// [closureToJs]。类型实参暂不支持（需要运行时类型元信息，先返回 null 让
/// 调用方出声告警，避免产出错误形态）。
String? _fnValueCallJs(
  FunctionExpressionInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e.typeArguments != null) return null;
  final f = exprToJs(e.function, scope, classes);
  if (f == null) return null;
  final positional = <String>[];
  final named = <String>[];
  for (final a in e.argumentList.arguments) {
    if (a is NamedExpression) {
      final inner = a.expression;
      final v = inner is FunctionExpression
          ? closureToJs(inner, scope, classes)
          : rhsToJs(inner, scope, classes);
      if (v == null) return null;
      named.add('${jsString(a.name.label.name)}: $v');
    } else {
      final v = a is FunctionExpression
          ? closureToJs(a, scope, classes)
          : rhsToJs(a, scope, classes);
      if (v == null) return null;
      positional.add(v);
    }
  }
  final tail = named.isEmpty ? null : '{${named.join(', ')}}';
  return '$f(${[...positional, if (tail != null) tail].join(', ')})';
}

/// 赋值右侧：字面量 / 形参 / 字段读 / 模型构造 `new X({...})` /
/// 插值、`??` 等其余形态兜底走 exprToJs。
String? rhsToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // 显式 extension 调用 `E(x).m(...)`：先于构造钩子 / 构造翻译拦截——否则
  // `E(x)` 会被当成 `new E({...})` 构造（E 是扩展名，不是类）。
  if (e is MethodInvocation) {
    // 显式扩展调用：按**扩展身份**分派（`E.m.call(x, …)`），不走原型。
    final explicit = _explicitExtensionCallJs(e, scope, classes);
    if (explicit != null) return explicit;
  }
  // 显式扩展 getter：`E(x).g` → `E.g.get.call(x)`。
  final explicitGetter = _explicitExtensionGetterJs(e, scope, classes);
  if (explicitGetter != null) return explicitGetter;
  // 组件/值对象出现在**任意表达式位置**（方法实参、三元分支、列表元素）时，
  // 先交给属性管线（[constructionHook]，由 element2js 安装）：子结点槽位与
  // 值转换器必须与 children 里的组件一致，否则会出现「JS 侧不存在的类调用」
  // （如 `ImageFilter.blur`）。钩子只接管 JS 侧能解析成类的类型，其余回落。
  final hooked = constructionHook?.call(e);
  if (hooked != null) return hooked;
  // StringInterpolation 是 StringLiteral 子类，必须先判（否则被吞成 ""）
  if (e is StringInterpolation) return _stringInterpolationJs(e, scope, classes);
  // 相邻字符串字面量拼接（`'a' 'b'`，Dart 语义是**拼接**）同为 StringLiteral 子类，
  // 在 literalToJs 里只能翻「全为常量」的情况；这里交给 exprToJs 的
  // AdjacentStrings 分支逐段翻译，含插值的段才翻得出来（必须早于下面的 literalToJs）。
  if (e is AdjacentStrings) return exprToJs(e, scope, classes);
  // `await <expr>` 统一在这里处理：声明初始化、赋值右侧、实参、独立语句
  // 全都经过 rhsToJs，await 不再只认声明那一种位置（原来 `_x = await f()`
  // 会整条丢掉）。内层表达式按普通表达式翻译——`Future.delayed(...)` 与其它
  // 构造/静态调用同一条规则，JS 侧由 flutter.js 的同名 `Future` 承接。
  if (e is AwaitExpression) {
    final v = rhsToJs(e.expression, scope, classes);
    return v == null ? null : 'await $v';
  }
  final lit = literalToJs(e);
  if (lit != null) return lit;
  // 构造统一翻译（唯一一条规则）：
  //   `A(args)`   → `new A({...})`
  //   `A.b(args)` → `A.b({...})`
  // 位置实参按**源码构造签名**映射成形参名（CtorSignatures 自动抽取，覆盖
  // 项目类 / SDK / 全部依赖包）。不再维护 Key / 控制器 / 值类 / 异常的类名表：
  // 这些类由运行时注入同名类（capabilities/ 下），翻译层与运行时都不感知扩展。
  final ctorJs = valueCtorJs(e, scope, classes);
  if (ctorJs != null) return ctorJs;
  // PrefixedIdentifier（`a.b`）不是单纯字段名，交给 exprToJs 的属性分支；
  // 若走下面的 Identifier 分支会用整串名字查字段而必然失败。
  if (e is PrefixedIdentifier) return exprToJs(e, scope, classes);
  // Identifier 一律交给 exprToJs 统一处理（全局标志 kDebugMode、State.mounted、
  // 字段/形参/局部变量同一套解析）——不再在此处单独 fieldRef，否则这些
  // 「非字段标识符」会被漏掉。
  if (e is InstanceCreationExpression) return modelCtorToJs(e, scope, classes);
  // 无 `const`/`new` 的模型构造（如 `const kX = [HomeBanner(...)]` 的元素）在无
  // resolution 的 parseString 下是 MethodInvocation。仅当名字命中已知类表时才按
  // 模型构造处理（避免把 widget 构造 `Text(...)` 误当模型）。
  if (e is MethodInvocation && e.target == null && e.typeArguments == null) {
    final n = e.methodName.name;
    if (classes.containsKey(n)) {
      final ctor = modelCtorFromPartsJs(
          n, e.argumentList.arguments.toList(), scope, classes);
      if (ctor != null) return ctor;
    }
  }
  // 集合字面量：与 JS 对象/数组一一对应（元素递归翻译）。
  // 缺了这两条，`Network.post({"name": name})` 这类调用会因「参数翻译不了」
  // 整体返回 null，调用方再把整条语句丢掉（原来的静默丢代码就出在这里）。
  if (e is RecordLiteral) return _recordLiteralJs(e, scope, classes);
  if (e is SetOrMapLiteral) return _collectionLiteralJs(e, scope, classes);
  if (e is ListLiteral) return _listLiteralJs(e.elements, scope, classes);
  // Map 读取在**值位置**归一（未命中 undefined → null，与 Dart 一致）。
  final mapRead = _mapReadValueJs(e, scope, classes);
  if (mapRead != null) return mapRead;
  return exprToJs(e, scope, classes);
}

/// Map 读取的**值位置**归一：`m[k]` 未命中返回 undefined，Dart 返回 null。
///
/// 只在会被存储 / 传递 / 拼接 / 返回的位置包 `__nn`；读取本身与 for-in 迭代
/// 源保持原样（null 与 undefined 在 for-of 里同样抛 TypeError，归一没有意义）。
String? _mapReadValueJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is IndexExpression &&
      !e.isNullAware &&
      e.target != null &&
      _staticTypeOf(e.target!, scope, classes) == 'Map') {
    final v = exprToJs(e, scope, classes);
    return v == null ? null : '__nn($v)';
  }
  return null;
}

/// Dart record 字面量 → JS 对象（手册 record 行）。
///
/// 位置字段用 `"$1".."$N"` 作键（`$1` 是合法 JS 标识符，`r.$1` 原样读取），
/// 命名字段用原名；混合记录因此也只需一种承载，`.$1` / `.x` 都不必按类型改写。
/// 已知差异：Dart record 的 `==` 是结构相等，JS 对象仍是同一性（不伪造）。
String? _recordLiteralJs(
  RecordLiteral e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final parts = <String>[];
  var positional = 0;
  for (final f in e.fields) {
    if (f is NamedExpression) {
      final v = rhsToJs(f.expression, scope, classes);
      if (v == null) return null;
      parts.add('${jsString(f.name.label.name)}: $v');
    } else {
      final v = rhsToJs(f, scope, classes);
      if (v == null) return null;
      positional++;
      parts.add('${jsString('\$$positional')}: $v');
    }
  }
  return '{${parts.join(', ')}}';
}

/// `{k: v, ...}` → JS 对象字面量；`{a, b}`（Set）→ `new Set([a, b])`。
String? _collectionLiteralJs(
  SetOrMapLiteral e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final entries = e.elements;
  // 无 resolution 下不依赖 isMap：元素全是 entry 即 Map，否则按 Set 处理。
  if (entries.every((el) => el is MapLiteralEntry)) {
    final parts = <String>[];
    for (final el in entries.whereType<MapLiteralEntry>()) {
      final k = rhsToJs(el.key, scope, classes);
      final v = rhsToJs(el.value, scope, classes);
      if (k == null || v == null) return null;
      parts.add('[$k, $v]');
    }
    // Dart `Map` 字面量 → 原生 JS `Map`：`{k: v}` → `new Map([[k, v], …])`。
    // 下标由生成器翻成 `get` / `set`；宿主桥序列化由 `Map.prototype.toJSON` 还原。
    return parts.isEmpty ? 'new Map()' : 'new Map([${parts.join(', ')}])';
  }
  final items = _listLiteralJs(entries, scope, classes);
  return items == null ? null : 'new Set($items)';
}

/// `[a, b]` → JS 数组字面量。支持 collection-if / collection-for / `...` 展开：
///   - `[a, if (c) b else d]` → `[a, ...(c ? [b] : [d])]`
///   - `[for (x in xs) f(x)]` → `[...(xs).map((x) => [f(x)])]`
///   - `[...xs]` → `[...xs]`；`[...?xs]` → `[...((__s) => __s == null ? [] : __s)(xs)]`
/// 不可翻译返回 null（调用方出声告警）。
String? _listLiteralJs(
  NodeList<CollectionElement> elements,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final parts = <String>[];
  for (final el in elements) {
    final v = _collectionFragmentJs(el, scope, classes);
    if (v == null) return null;
    parts.add(v);
  }
  return '[${parts.join(', ')}]';
}

/// 集合元素 → 数组**片段**（普通元素原样、展开带 `...`、if/for 用展开的三元 / map）。
String? _collectionFragmentJs(
  CollectionElement el,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (el is Expression) return rhsToJs(el, scope, classes);
  if (el is SpreadElement) {
    final v = rhsToJs(el.expression, scope, classes);
    if (v == null) return null;
    // Dart `...?xs`：接收者为 null 时展开为空；JS 直接 `...null` 会抛错。
    return el.isNullAware
        ? '...((__s) => __s == null ? [] : __s)($v)'
        : '...$v';
  }
  if (el is IfElement) {
    final caseClause = el.caseClause;
    if (caseClause != null) {
      // 集合 if-case：`[if (v case P) a else b]`。接收值单次求值，模式检查 +
      // 绑定放进 IIFE，命中返回 then 的数组、未命中返回 else 的数组（外层展开）。
      final v = exprToJs(el.expression, scope, classes);
      if (v == null) return null;
      final plan = _PatternPlan();
      final before = {...scope.localVars};
      final gp = caseClause.guardedPattern;
      if (!_compilePatternWithGuard(
          gp.pattern, gp.whenClause?.expression, plan, scope, classes)) {
        scope.localVars
          ..clear()
          ..addAll(before);
        return null;
      }
      if (gp.whenClause == null) plan.lines.add('return true;');
      final a = _collectionArrayJs(el.thenElement, scope, classes);
      final b = el.elseElement == null
          ? '[]'
          : _collectionArrayJs(el.elseElement!, scope, classes);
      scope.localVars
        ..clear()
        ..addAll(before);
      if (a == null || b == null) return null;
      final bf = StringBuffer('...(() => {\n  const __v0 = $v;\n');
      if (plan.names.isNotEmpty) {
        bf.write('  let ${plan.names.toSet().join(', ')};\n');
      }
      bf.write('  const __ok = (() => { ${plan.lines.join(' ')} })();\n');
      bf.write('  return __ok ? $a : $b;\n})()');
      return bf.toString();
    }
    final c = exprToJs(el.expression, scope, classes);
    final a = _collectionArrayJs(el.thenElement, scope, classes);
    final b = el.elseElement == null
        ? '[]'
        : _collectionArrayJs(el.elseElement!, scope, classes);
    if (c == null || a == null || b == null) return null;
    return '...($c ? $a : $b)';
  }
  if (el is ForElement) {
    final loop = el.forLoopParts;
    final String? name;
    if (loop is ForEachPartsWithDeclaration) {
      name = loop.loopVariable.name.lexeme;
    } else if (loop is ForEachPartsWithIdentifier) {
      name = loop.identifier.name;
    } else {
      name = null;
    }
    if (name != null && loop is ForEachParts) {
      final iterable = loop is ForEachPartsWithDeclaration
          ? exprToJs(loop.iterable, scope, classes)
          : exprToJs(
              (loop as ForEachPartsWithIdentifier).iterable, scope, classes);
      final body =
          _collectionArrayJs(el.body, scope.withParams([name]), classes);
      if (iterable == null || body == null) return null;
      return '...($iterable).map(($name) => $body)';
    }
    if (loop is! ForParts) return null; // 其它 for 头形态
    // 三段式：`[for (var i = 0; i < n; i++) f(i)]` → IIFE 内跑原生 for，
    // 每轮把元素数组 push 进结果（返回数组后由外层展开）。
    final before = {...scope.localVars};
    final inits = <String>[];
    if (loop is ForPartsWithDeclarations) {
      for (final v in loop.variables.variables) {
        final n = v.name.lexeme;
        scope.localVars.add(n);
        final declared = loop.variables.type?.toSource();
        if (declared != null) scope.localTypes[n] = declared;
        if (v.initializer == null) {
          inits.add('let $n');
          continue;
        }
        final rhs = rhsToJs(v.initializer!, scope, classes);
        if (rhs == null) {
          scope.localVars
            ..clear()
            ..addAll(before);
          return null;
        }
        inits.add('let $n = $rhs');
      }
    } else if (loop is ForPartsWithExpression) {
      final init = loop.initialization;
      if (init != null) {
        final t = exprToJs(init, scope, classes);
        if (t == null) {
          scope.localVars
            ..clear()
            ..addAll(before);
          return null;
        }
        inits.add(t);
      }
    } else {
      scope.localVars
        ..clear()
        ..addAll(before);
      return null;
    }
    final condJs =
        loop.condition == null ? '' : exprToJs(loop.condition!, scope, classes);
    final upds = <String>[];
    if (condJs != null) {
      for (final u in loop.updaters) {
        final t = exprToJs(u, scope, classes);
        if (t == null) {
          scope.localVars
            ..clear()
            ..addAll(before);
          return null;
        }
        upds.add(t);
      }
    }
    final body = _collectionArrayJs(el.body, scope, classes);
    scope.localVars
      ..clear()
      ..addAll(before);
    if (condJs == null || body == null) return null;
    return '...(() => {\n  const __r = [];\n'
        '  for (${inits.join(', ')}; $condJs; ${upds.join(', ')}) {\n'
        '    __r.push(...$body);\n  }\n  return __r;\n})()';
  }
  return null;
}

/// 集合元素 → 数组字面量（if/for 的分支与循环体必须是数组才能被展开）。
String? _collectionArrayJs(
  CollectionElement el,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final frag = _collectionFragmentJs(el, scope, classes);
  return frag == null ? null : '[$frag]';
}

/// 构造表达式 → JS 构造调用；非构造返回 null。
///
/// 唯一规则（所有类一视同仁，不含任何类名表）：
/// - `A(args)` → `new A({...})`
/// - `A.b(args)` → `A.b({...})`（签名表能证明 `A` 有构造 `b` 时才接管，避免
///   把 `Theme.of(context)` 这类静态方法/普通调用误当构造）
///
/// 位置实参用 [CtorSignatures] 从源码签名映射成形参名；签名缺失时落
/// `__pos` 下标数组并出声告警，由运行时按构造签名展开——不静默丢弃。
String? valueCtorJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // 标准库 `Map` 的实例构造：Map 在 JS 侧是普通对象，没有 JS `Map` 构造语义。
  //   - `Map()` / `Map<K, V>()` → `{}`（空对象）；
  //   - `Map.from(other)` / `Map.of(other)` → `__mapFrom(other)`（浅拷贝）。
  // 这是「内建类型 + 成员名」的固定映射表项，只对可判定为 SDK `Map` 的构造生效。
  if (e is InstanceCreationExpression) {
    final typeName = e.constructorName.type.name2.lexeme;
    if (typeName == 'Map') {
      final ctor = e.constructorName.name?.name;
      final args = e.argumentList.arguments;
      if (ctor == null && args.isEmpty) return 'new Map()';
      if ((ctor == 'from' || ctor == 'of') && args.length == 1) {
        final v = rhsToJs(args.first, scope, classes);
        return v == null ? null : 'new Map($v)';
      }
    }
  }
  String? cls;
  String? ctorName;
  List<Expression> args = const [];
  if (e is InstanceCreationExpression) {
    // 类型实参在 JS 里不存在（Dart→JS 语义即擦除），构造名只取类型实参之前
    // 的部分：`GlobalKey<AnimatedListState>()` 与 `GlobalKey()` 是同一个类。
    // 命名构造的名字在 `constructorName.name`（类型部分的 toSource 不含它）：
    // `StreamController<int>.broadcast()` 必须落 `new StreamController.broadcast(...)`，
    // 只按类型源码解析会把 `.broadcast` 丢掉。
    var src = e.constructorName.type.toSource();
    final lt = src.indexOf('<');
    if (lt >= 0) src = src.substring(0, lt).trim();
    final ctorTok = e.constructorName.name?.name;
    if (ctorTok != null) {
      // 带 import 前缀的类型（`p.A.b(...)`）交给通用调用分支，避免把前缀当类名。
      if (src.contains('.')) return null;
      cls = src.trim();
      ctorName = ctorTok;
    } else {
      final dot = src.indexOf('.');
      cls = dot < 0 ? src : src.substring(0, dot);
      ctorName = dot < 0 ? null : src.substring(dot + 1);
    }
    args = e.argumentList.arguments.toList();
  } else if (e is MethodInvocation && e.target is SimpleIdentifier) {
    cls = (e.target! as SimpleIdentifier).name;
    ctorName = e.methodName.name;
    args = e.argumentList.arguments.toList();
  } else if (e is MethodInvocation && e.target == null) {
    // 无 `new` 的构造调用：`GlobalKey()` / `GlobalKey<AnimatedListState>()` ——
    // 类型实参在 JS 里不存在，一律擦除；非类名（首字母非大写）由下面拦掉。
    cls = e.methodName.name;
    args = e.argumentList.arguments.toList();
  }
  if (cls == null || !_isClassLikeName(cls)) return null;
  final posCount = args.where((a) => a is! NamedExpression).length;
  // 命名形态（`A.b(...)`）只在签名表命中时接管：否则可能是静态方法调用。
  final signatures = CtorSignatures.instance;
  final sig = signatures?.of(cls,
      ctorName: ctorName, positionalCount: posCount);
  // 项目类的命名构造：类表里已按同一份源码 AST 收集了构造形参名，签名索引在
  // 当前构建上下文不可得时用它兜底——两条来源都是「源码事实」，不维护白名单。
  ClassCtor? projectCtor;
  if (ctorName != null && sig == null) {
    for (final c in classes[cls]?.ctors ?? const <ClassCtor>[]) {
      if (c.name == ctorName) {
        projectCtor = c;
        break;
      }
    }
    if (projectCtor == null) return null;
  }
  final positional = sig?.positional ?? projectCtor?.positional ?? const <String>[];
  final entries = <String>[];
  final rest = <String>[];
  var posIndex = 0;
  for (final a in args) {
    if (a is NamedExpression) {
      final v = _ctorArgJs(a.expression, scope, classes);
      if (v == null) return null;
      entries.add('${a.name.label.name}: $v');
      continue;
    }
    final v = _ctorArgJs(a, scope, classes);
    if (v == null) return null;
    if (posIndex < positional.length) {
      entries.add('${positional[posIndex]}: $v');
    } else {
      rest.add(v);
    }
    posIndex++;
  }
  if (rest.isNotEmpty) {
    // 签名未知（源码里找不到该类）→ 下标兜底，运行时按构造签名展开。
    log.warning('[hot_patch_generator] ${sourceAt(scope.sourcePath, e)}: '
        '构造 $cls${ctorName == null ? '' : '.$ctorName'} '
        '的位置实参缺少形参名签名，落 __pos 兜底：${rest.join(', ')}');
    entries.add('__pos: [${rest.join(', ')}]');
  }
  // 类型实参 → `typeArguments` **元信息 Map**（唯一解析见 [typeArgsOf]）。
  // 运行时/宿主谁需要谁取（如 `GlobalKey<T>` 的 currentState 代理类、provider
  // 的类型键），翻译层不做类型判断、不维护名单。
  final typeArgs = typeArgsOf(
    e,
    declared: sig?.typeParams ?? signatures?.typeParamsOf(cls) ?? const [],
  );
  if (typeArgs.isNotEmpty) {
    entries.add('typeArguments: ${typeArgsMapJs(typeArgs)}');
  }
  final props = entries.isEmpty ? '' : '{${entries.join(', ')}}';
  return ctorName == null ? 'new $cls($props)' : '$cls.$ctorName($props)';
}

/// 类型实参 → **元信息 Map**（key = 声明侧类型参数名，value = 实参类型名）。
///
/// 唯一实现，构造（值 / 组件结点）与泛型方法调用共用。Dart 泛型在 JS 侧的
/// 唯一边界是**元信息**：`<String, int>` → `{"K": "String", "V": "int"}`。
/// [declared] 是声明侧的类型参数名（`class Pair<K, V>` → `['K', 'V']`，
/// `m<T>()` → `['T']`）；查不到声明时退化为位置序号键（`"0"` / `"1"`），
/// 保证形态唯一且多泛型不丢失。谁需要谁读，翻译层不按类名 / 方法名判断。
///
/// 覆盖三种写法：`const A<T>()`、`A<T>.b()`、`A<T>()`（无 const，parseString 下
/// 是 MethodInvocation）。嵌套泛型保留源码文本（`List<int>`）。
Map<String, String> typeArgsOf(
  Expression? e, {
  List<String> declared = const [],
}) {
  final List<TypeAnnotation>? args = switch (e) {
    InstanceCreationExpression() => e.constructorName.type.typeArguments?.arguments,
    MethodInvocation() => e.typeArguments?.arguments,
    _ => null,
  };
  final list = args ?? const <TypeAnnotation>[];
  return {
    for (var i = 0; i < list.length; i++)
      (i < declared.length ? declared[i] : '$i'): _bareTypeSource(list[i].toSource()),
  };
}

/// 类型源码去掉 import 前缀（`vm.CounterVm` → `CounterVm`）。
///
/// `typeArguments` 是**类型身份**（provider 作用域按它键控）：Dart 里不同库的
/// 同名类在名字上就是同一个标识，前缀只用于消解引用。嵌套泛型（`List<vm.X>`）
/// 保持源码文本，与既有规则一致。
String _bareTypeSource(String src) =>
    src.replaceFirst(RegExp(r'^[a-zA-Z_$][\w$]*\.(?=[A-Z_$])'), '');

/// 类型实参 Map → JS 对象字面量源码（`{ "K": "String", "V": "int" }`）。
String typeArgsMapJs(Map<String, String> args) =>
    '{${args.entries.map((e) => '${jsString(e.key)}: ${jsString(e.value)}').join(', ')}}';

/// 操作数是否是**类型参数**（`T` / `E`）。只看作用域里登记的类型参数名，
/// 不按名字形态猜——`T == String` 这类「类型值比较」据此进入专用翻译分支。
bool _isTypeParamOperand(Expression e, FieldScope scope) =>
    e is SimpleIdentifier && scope.typeParams.containsKey(e.name);

/// 类型字面量在值语境下的 JS 表示：类型名 → 字符串（`String` → `"String"`）。
///
/// Dart 的 `T == String` 比较的是 Type 对象；JS 侧没有类型对象，统一用**类型名
/// 字符串**比较（T 就是 `typeArguments` 里保存的类型名）。类型参数自身返回
/// 作用域登记的读取表达式（`this.__ta["T"]`）。非类型名返回 null，交回普通路径。
String? _typeValueJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is! SimpleIdentifier) return null;
  final tp = scope.typeParams[e.name];
  if (tp != null) return tp;
  const builders = {
    'String',
    'int',
    'double',
    'num',
    'bool',
    'Object',
    'dynamic',
    'void',
    'Null',
    'Function',
    'List',
    'Map',
    'Set',
    'Iterable',
    'Future',
  };
  if (builders.contains(e.name)) return jsString(e.name);
  if (classes.containsKey(e.name) || runtimeGlobalTypes().contains(e.name)) {
    return jsString(e.name);
  }
  // 首字母大写 = 类名形态（项目内 / 三方类型）；未知小写名不当作类型。
  final bare = e.name.replaceFirst(RegExp('^_+'), '');
  if (bare.isNotEmpty && bare[0] == bare[0].toUpperCase()) return jsString(e.name);
  return null;
}

/// 构造表达式的「结构化值」钩子：由 element2js 在翻译表达式期间安装
/// （[ElementTranslateContext.jsDataExpr]）。命中返回 JS 源码时，该构造按
/// **属性管线**翻译（子结点槽位协议、值转换器、builder 展开全部生效）；
/// 返回 null 则回落到通用构造翻译。
///
/// 必要性：通用构造翻译（[valueCtorJs]）只有签名表，没有属性管线。于是
/// `helper(ImageFiltered(imageFilter: ImageFilter.blur(...)))` 这种「构造当
/// 实参」的位置会把 `ImageFilter.blur` 译成 JS 类调用（JS 侧不存在该类），
/// 子结点也不会拆成槽位。钩子让这类构造与 children 里的结点走**同一条**
/// 翻译路径，不再有两套产物形态。
typedef ConstructionHook = String? Function(Expression e);

/// 当前生效的构造钩子（翻译是单线程的，按表达式翻译调用期安装/还原）。
ConstructionHook? constructionHook;

/// 类引用钩子：静态成员调用（`Overlay.of(context)` / `Alignment.values` 这类
/// `X.m(...)` 形态）的 receiver 是**模块里确有类定义**的类型时，返回该
/// 类的 JS 引用串（并负责登记 import）；返回 null 表示「按既有路径处理」。
///
/// 为什么需要：`X.of(context)` 的 receiver 是一个**类引用**，而它不是
/// [runtimeGlobalTypes] 里的运行时注入类（`MediaQuery` 那类），也不是
/// [FieldScope] 可解析的字段 / 方法 / 局部变量——通用规则会把整条调用判为不可
/// 翻译。判据只看「这个类型的类定义在哪」（由 element2js 用类文件解析回答），
/// 与它是不是组件无关。
typedef ClassRefHook = String? Function(String className);

/// 当前生效的类引用钩子（由 element2js 安装；翻译单线程，按调用期安装/还原）。
ClassRefHook? classRefHook;

bool _isClassLikeName(String name) {
  if (name.isEmpty) return false;
  final c = name.codeUnitAt(0);
  return c >= 0x41 && c <= 0x5A;
}

/// 构造实参 → JS：闭包走 [closureToJs]（与普通方法调用 `addListener(() {...})`
/// 同一口径），其余走 [rhsToJs]。
///
/// 构造实参里的闭包在 Dart 里很常见（`Timer.periodic(d, (t) {...})`、
/// `ValueNotifier(...)` 包装、`XxxModel(onDone: () {...})`）。缺了这一条，
/// [rhsToJs] 对 FunctionExpression 返回 null，整个构造翻译失败，外层语句被
/// 丢弃——正是「静默丢代码」的来源。
String? _ctorArgJs(
  Expression a,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (a is FunctionExpression) return closureToJs(a, scope, classes);
  return rhsToJs(a, scope, classes);
}



/// 模型构造调用 → JS：`new User({name:..., age:...})`。
/// 位置参数按类实例字段声明顺序映射；命名参数按 label。
String? modelCtorToJs(
  InstanceCreationExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) =>
    modelCtorFromPartsJs(e.constructorName.type.name2.lexeme,
        e.argumentList.arguments.toList(), scope, classes);

/// 按「构造名 + 参数」生成 `new X({...})`。供 modelCtorToJs（InstanceCreation）
/// 与字段初始化的 MethodInvocation 形式（parseString 无 resolution 下 `Foo()`
/// 会被解析成 MethodInvocation）共用同一套映射逻辑。
String? modelCtorFromPartsJs(
  String name,
  List<Expression> args,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final info = classes[name];
  if (info == null) return null;
  final named = <String>[];
  final positional = <String>[];
  for (final a in args) {
    if (a is NamedExpression) {
      final v = rhsToJs(a.expression, scope, classes);
      if (v == null) return null;
      named.add('${a.name.label.name}: $v');
    } else {
      final v = rhsToJs(a, scope, classes);
      if (v == null) return null;
      positional.add(v);
    }
  }
  final entries = <String>[];
  // 位置参数按**对象字段视图**映射（父类字段在前）：Dart 里 `super.name` 形参
  // 占据父类字段位置，与这个顺序一致，父类构造的 `__applyProps(args)` 才拿得到值。
  final fields = objectFieldsOf(info, classes);
  for (var i = 0; i < fields.length && i < positional.length; i++) {
    entries.add('${fields[i].name}: ${positional[i]}');
  }
  entries.addAll(named);
  return 'new $name({${entries.join(', ')}})';
}

/// 方法调用（语句位置，带分号）：`_model.inc()` → `this._model.inc();`；
/// 裸调用 `notifyListeners()`（MethodScope 白名单）→ `this.notifyListeners();`。
String? methodCallStmtJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // `print` / `debugPrint` 不做任何特殊处理：它们就是运行时注入的全局函数
  //（`G.print` / `G.debugPrint`，见 runtime_js 的【1】），按一比一产出同名
  // 裸调用，由 [methodCallExprJs] 的「运行时全局函数」分支兜住。
  final call = methodCallExprJs(e, scope, classes);
  return call == null ? null : '$call;';
}

/// 字符串插值 → JS 表达式：`'a $x b'` → `"a " + x + " b"`。
///
/// 插值片段原样拼接（Dart 的 `'$x'` 走 `toString()`，JS 的 `+` 对字符串/数字
/// 同样成立）。对象直接作为日志实参时由运行时的 `print` / `debugPrint` 展开，
/// 不在这里包 `__str`——否则 widget 文案、props 数据、模型初始化等位置都会
/// 无谓地引入 `__str` 全局依赖。
String? _stringInterpolationJs(
  Expression a,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // 注意：StringInterpolation 是 StringLiteral 的子类，必须先判插值
  //（否则 stringValue 会把插值表达式拼进字面量、丢失 this._x 引用）。
  if (a is StringInterpolation) {
    final parts = <String>[];
    for (final el in a.elements) {
      if (el is InterpolationString) {
        if (el.value.isNotEmpty) parts.add(jsString(el.value));
      } else if (el is InterpolationExpression) {
        final v = _mapReadValueJs(el.expression, scope, classes) ??
            exprToJs(el.expression, scope, classes);
        if (v != null) {
          parts.add(v);
        } else {
          // 丢片段会让产物「看着对、其实少东西」（如 `"用户信息:$x"` →
          // `"用户信息:"`），故必须出声，不能静默。
          log.warning('[hot_patch_generator] '
              '${sourceAt(scope.sourcePath, el.expression)}: 插值片段无法翻译，已在 JS 产物中'
              '丢失：\${${el.expression.toSource()}}');
        }
      }
    }
    return parts.isEmpty ? '""' : parts.join(' + ');
  }
  return exprToJs(a, scope, classes);
}

/// 混合调用时承载**位置实参**的哨兵键。
///
/// 用哨兵键而不是靠「有没有 `p`/`n` 两个键」来猜，是因为 Dart 标识符
/// 不允许 `@`：任何具名形参都不可能叫 `@args`，判定零歧义。
const String hostPositionalKey = '@args';

/// 宿主通道调用的参数载荷（按实参形态给最简编码）。
///
/// 用于**顶层** `@HostInjected` 函数的调用点（类上的宿主方法见
/// [hostMethodBodyJs]，载荷形态由方法内的 `arguments` 重建，规则一致）。
///
///   - 纯位置：数组 `[a, b]`（运行时用 `Array.isArray` 判定）
///   - 纯具名：具名表本身 `{"times": 2}`
///   - 混合：具名表 + [hostPositionalKey] 装位置实参
///     `{"@args": ["hi"], "times": 2}`
///
/// 位置实参与具名实参**必须分开传**，宿主侧才能用
/// `Function.apply(impl, 位置, 具名)` 还原 Dart 调用语义。绝不能像普通 JS
/// 调用那样把具名实参扁平化进数组：`Network.post(params: {...})` 会变成 1 个
/// 位置实参，而该函数只接受具名参数 `params`，`Function.apply` 直接抛异常。
///
/// 实参**个数不限**（位置数组与具名键数量都无上限）；未传的可选位置参数
/// (`[int b]`) / 具名默认值 (`int times = 1`) 由 Dart 函数自身兜底，
/// `Function.apply` 自动走默认值。
String hostArgsJs(List<String> positional, List<String> named) {
  if (named.isEmpty) return '[${positional.join(', ')}]';
  if (positional.isEmpty) return '{${named.join(', ')}}';
  return '{${jsString(hostPositionalKey)}: [${positional.join(', ')}], '
      '${named.join(', ')}}';
}

/// 运行时注入的全局函数调用的实参串（`showDialog(context: …, builder: …)`）。
///
/// 与 [hostArgsJs] 同一套载荷形态，但**纯位置实参不包数组**——全局函数是普通
/// JS 函数，直接按位置调用即可；具名实参 Dart 与 JS 都没有，故对象形态只是
/// 「函数只接受一个配置对象」的表示法，由该函数的实现自己解构：
///
///   - 纯位置：`a, b`
///   - 纯具名：`{"context": c, "builder": b}`
///   - 混合：`{"@args": [a], "k": v}`（同 [hostPositionalKey] 约定）
String globalFnArgsJs(List<String> positional, List<String> named) {
  if (named.isEmpty) return positional.join(', ');
  if (positional.isEmpty) return '{${named.join(', ')}}';
  return '{${jsString(hostPositionalKey)}: [${positional.join(', ')}], '
      '${named.join(', ')}}';
}

/// Dart 函数形参 → JS 签名 + 函数体前导（闭包 / 局部函数 / 类方法共用）。
///
/// 调用约定（全仓库唯一，见 `_methodCallJs`）：位置实参在前、**具名实参合并成
/// 一个尾参对象**。因此：
///   - 位置形参按原名进 JS 签名；可选位置形参在函数体开头补缺省
///     （Dart 缺省即 null，显式默认值按源码翻译）；
///   - 具名形参不占位置，函数体开头从尾参对象 `__o` 解构出同名局部变量，
///     缺省时取默认值 / null（required 具名由调用方保证传入）。
/// [defaultJs] 负责翻译默认值表达式；返回 null 时出声告警并退回 null。
class _ParamPlan {
  final List<String> names = []; // 所有 Dart 形参名（作用域登记）
  final List<String> jsParams = []; // JS 签名形参
  final List<String> prologue = []; // 函数体前导语句（不带缩进）
}

_ParamPlan _functionParamPlan(
  FormalParameterList? parameters,
  String? Function(Expression) defaultJs,
) {
  final plan = _ParamPlan();
  var hasNamed = false;
  for (final p in parameters?.parameters ?? const <FormalParameter>[]) {
    final inner = p is DefaultFormalParameter ? p.parameter : p;
    final name = inner.name?.lexeme;
    if (name == null || name.isEmpty) continue;
    plan.names.add(name);
    final defaultValue = p is DefaultFormalParameter ? p.defaultValue : null;
    String? dj;
    if (defaultValue != null) {
      dj = defaultJs(defaultValue);
      if (dj == null) {
        log.warning('[hot_patch_generator] 形参 $name 的默认值无法翻译，'
            '已退回 null：${defaultValue.toSource()}');
      }
    }
    if (p.isNamed) {
      hasNamed = true;
      // `required` 由 Dart 编译期校验：所有调用点都来自编译通过的源码，
      // 产物无需重复做运行期缺参检查。
      plan.prologue.add('let $name = (__o && __o.$name !== undefined) '
          '? __o.$name : ${dj ?? 'null'};');
    } else {
      plan.jsParams.add(name);
      if (p is DefaultFormalParameter) {
        plan.prologue
            .add('$name = ($name === undefined) ? ${dj ?? 'null'} : $name;');
      }
    }
  }
  if (hasNamed) plan.jsParams.add('__o');
  return plan;
}

/// 闭包参数 → JS 函数表达式：`() {...}` → `() => { ... }`、
/// `(v) => expr` → `(v) => { return <expr>; }`（一律箭头函数）。
///
/// 闭包体逐语句翻译，其中 `setState(() {...})` 展开为
/// `this.setState(() => { ... })`（与组件方法体里的 setState 同构）。
String? closureToJs(
  FunctionExpression fn,
  FieldScope scope,
  Map<String, ClassInfo> classes, [
  ExprRenderer? renderer,
]) {
  // 形参与默认值走全仓库唯一实现：可选位置参数补缺省、具名形参从尾参对象
  // `__o` 解构。默认值是常量表达式，用闭包定义处的作用域翻译。
  final plan = _functionParamPlan(
      fn.parameters, (e) => rhsToJs(e, scope, classes));
  // 泛型闭包 / 泛型局部函数（`T f<T>(...)`）：调用点把类型实参（与具名实参）
  // 合并成**尾参对象**下发，定义侧追加 `__ta` 接住（已有具名时直接复用 `__o`）。
  // 函数体里的 `T` 从 `尾参.typeArguments["T"]` 读，与类方法泛型同一口径。
  final typeParamRefs = <String, String>{};
  final typeParams =
      fn.typeParameters?.typeParameters ?? const <TypeParameter>[];
  if (typeParams.isNotEmpty) {
    final tail = plan.jsParams.contains('__o') ? '__o' : '__ta';
    if (!plan.jsParams.contains(tail)) plan.jsParams.add(tail);
    for (final tp in typeParams) {
      final name = tp.name.lexeme;
      typeParamRefs[name] =
          '((($tail && $tail.typeArguments) || {})[${jsString(name)}])';
    }
  }
  final pjs = plan.jsParams.join(', ');
  final pro = plan.prologue.isEmpty ? '' : '${plan.prologue.join(' ')} ';
  // 闭包形参登记进作用域：`where((o) => o.status == _status)` 里的 `o` 必须
  // 解析为形参，否则谓词翻译失败、连带整个 `where(...)` 与外围表达式被丢弃。
  final bodyScope = plan.names.isEmpty && typeParamRefs.isEmpty
      ? scope
      : scope.withParams(plan.names, typeParamRefs: typeParamRefs);
  final body = fn.body;
  // 生成器闭包 / 生成器局部函数（`() sync* { … }`）：JS 箭头函数不能是生成器，
  // 外层仍是箭头（保住 this 与默认值求值时机），内层用 `function*` 产出生成器；
  // `sync*` 直接返回生成器，`async*` 包成 `Stream.fromAsyncGenerator(...)`。
  if (body is BlockFunctionBody && body.isGenerator) {
    final stmts =
        translateStmtList(body.block.statements, bodyScope, classes, renderer);
    final inner = body.isAsynchronous ? 'async function*' : 'function*';
    final genExpr = '($inner () { ${stmts.trim()} }).bind(this)()';
    final call = body.isAsynchronous
        ? 'Stream.fromAsyncGenerator($genExpr)'
        : genExpr;
    return pro.isEmpty
        ? '($pjs) => $call'
        : '($pjs) => { ${pro}return $call; }';
  }
  final asyncKw = body.isAsynchronous ? 'async ' : '';
  // 一律输出箭头函数：this 词法绑定到定义处（组件实例），与 Dart 闭包
  // 捕获 this 的语义一致——回调（如 addListener 闭包）由宿主经 invoke
  // 普通调用触发时 this 不会丢失，无需 .bind。引擎为 flutter_js
  // （macOS/iOS JavaScriptCore、Android QuickJS），均完整支持 ES6。
  if (body is ExpressionFunctionBody) {
    // 表达式体在 Dart 里就是一个**值**，JS 侧必须 `return`，否则
    // `sort((a, b) => a.compareTo(b))` / `map((e) => e.name)` 这类回调会把
    // 返回值丢掉（谓词恒为 undefined）。先按值翻译并 return；只有值形态翻译
    // 不出来（赋值 `_x = 5`、`setState(...)` 等语句形态）才退回语句翻译。
    // 组件构造（`(context, o) => Row(...)`）必须先走 widget 管线：属性要按
    // 组件规则归一（`MainAxisSize.min` → `"min"`、`EdgeInsets` → edges JSON），
    // 且类所在文件要登记 import，否则产物里是未定义变量。
    //
    // 但**只有元素构造**才进管线：闭包体同样是值表达式（`where((o) =>
    // o.status == _status)` / `sort((a, b) => b.like.compareTo(a.like))` /
    // `() => _items`），这些不是组件、所在的列表也不一定是组件列表。无条件送
    // 进管线会因「表达式翻不出来」被降级成占位组件（产物里是 `new SizedBox({})`）：
    // 谓词恒假 → 列表被筛空、比较器恒 0 → 排序失效，且产物里看不出问题。
    // 判据与 `return` 位置一致：有没有 JS 类定义（[ExprRenderer.ctorJsClassFile]）。
    final wv = renderer != null && renderer.ctorJsClassFile(body.expression) != null
        ? _widgetExprToJs(renderer, body.expression, 0)
        : null;
    if (wv != null) {
      return pro.isEmpty
          ? '$asyncKw($pjs) => $wv'
          : '$asyncKw($pjs) => { ${pro}return $wv; }';
    }
    // `throw` 箭头体（`() => throw e`）：Dart 允许，JS 箭头体只能是表达式。
    // 直接产出语句体 `{ throw e; }`，既符合 Dart 源码意图，也避免多包一层 IIFE
    // （表达式位置的 throw 走 `exprToJs` 的 IIFE 形态）。
    if (body.expression is ThrowExpression) {
      final v = closureBodyStmtJs(body.expression, bodyScope, classes);
      if (v != null) return '$asyncKw($pjs) => { ${pro}${v} }';
      return null;
    }
    final rv = rhsToJs(body.expression, bodyScope, classes);
    if (rv != null) return '$asyncKw($pjs) => { ${pro}return $rv; }';
    final v = closureBodyStmtJs(body.expression, bodyScope, classes);
    if (v != null) return '$asyncKw($pjs) => { ${pro}${v} }';
    return null;
  }
  if (body is BlockFunctionBody) {
    // 空块体（`() {}`）是合法的空操作闭包（有形参默认值前导时仍需块体）。
    if (body.block.statements.isEmpty) {
      return pro.isEmpty ? '($pjs) => {}' : '$asyncKw($pjs) => { ${pro}}';
    }
    // 块体逐语句翻译——与方法体、`_setStateJs` 共用**同一条** [translateStmtList]：
    // 声明、if/for/while/switch、setState 展开全部覆盖。旧实现只收
    // `ExpressionStatement`，`onPick: (k, v) { setState(() { switch ... }) }`
    // 这类块体会被静默丢成 `(...) => {}`（筛选面板点选条件无任何反应）。
    final stmts =
        translateStmtList(body.block.statements, bodyScope, classes, renderer);
    if (stmts.trim().isEmpty) return null;
    return '$asyncKw($pjs) => { ${pro}${stmts.trim()} }';
  }
  return null;
}

/// 泛型方法调用点能定位到的声明侧类型参数名。
///
/// 1. receiver 是**类名**且类是项目类 / 运行时注入类（`C.parse<T>()`）：按静态
///    方法声明取参数名；
/// 2. 其余（注入代理方法 `context.watch<T>()`、实例方法）：按**方法名**查源码里
///    唯一的泛型方法声明（`watch` → `['T']`）；
/// 3. 仍不可判定（同名方法有多个参数名组合）→ 空，调用方退化为位置序号键。
///    消费方按 `Object.values(...)` 取值，与 key 无关。
List<String> _declaredTypeParamsFor(
  MethodInvocation e,
  Map<String, ClassInfo> classes,
  FieldScope scope,
) {
  // 局部泛型函数：声明就在当前方法体内，类型参数名由 [_localFunctionJs] 登记。
  if (e.target == null) {
    final local = scope.localTypeParams[e.methodName.name];
    if (local != null && local.isNotEmpty) return local;
  }
  final tgt = e.target;
  if (tgt is SimpleIdentifier &&
      (classes.containsKey(tgt.name) || runtimeGlobalTypes().contains(tgt.name))) {
    final declared = CtorSignatures.instance
        ?.staticMethodTypeParamsOf(tgt.name, e.methodName.name);
    if (declared != null && declared.isNotEmpty) return declared;
  }
  return CtorSignatures.instance?.methodTypeParamsOfName(e.methodName.name) ??
      const [];
}

/// 闭包体内的单条表达式语句 → JS：与方法体共用 [\_bodyExprStmtJs]
/// （`setState(...)` 展开 + 赋值/自增/对象方法调用等）。保留本函数只为兼容
/// 表达式体闭包的调用点（`(v) => expr` 分支）。
String? closureBodyStmtJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) =>
    _bodyExprStmtJs(e, scope, classes);

/// 方法调用（表达式位置）：返回 `obj.method(args)` / `this.method(args)`。
///
/// 空安全调用 `a?.m(args)` → JS 原生可选调用 `a?.m(args)`（ES2020）：接收者
/// 只求值一次，为 null / undefined 时整个表达式短路、**实参不求值**，与 Dart
/// 语义一致；链式 `a?.b?.c()` 的整链短路同样由 JS 语义保证。
String? methodCallExprJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e.isNullAware) {
    // `?..`（空安全级联）不是方法调用语义，本层不接管（交由调用方丢弃并出声）。
    if (e.operator?.lexeme != '?.') return null;
    final target = e.target;
    if (target == null) return null;
    final recv = exprToJs(target, scope, classes);
    if (recv == null) return null;
    return _methodCallJs(e, scope, classes, receiverJs: recv, nullAware: true);
  }
  // 显式 extension 调用 `E(x).m(args)`：按扩展身份分派（`E.m.call(x, …)`）。
  final explicit = _explicitExtensionCallJs(e, scope, classes);
  if (explicit != null) return explicit;
  return _methodCallJs(e, scope, classes);
}

/// 显式 extension 调用的**身份分派**：`E(x).m(a)` → `E.m.call(x, a)`。
///
/// 原型只承接隐式调用（实例成员优先 + 原型链特异性）；显式调用必须按扩展身份
/// 分派——同目标同名扩展时只有身份能区分（Dart 里隐式调用本身是歧义编译错误）。
/// 返回 null 表示不是「可见具名扩展的实例方法」，交回通用调用路径。
String? _explicitExtensionCallJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final resolved = _extensionOverrideInfo(e.target, scope);
  if (resolved == null) return null;
  final scopeInfo = scope.extensionNames[resolved.$1];
  if (scopeInfo == null) return null;
  final member = e.methodName.name;
  if (scopeInfo.members[member]?.contains(ExtensionMemberKind.method) != true) {
    return null;
  }
  final recvJs = exprToJs(resolved.$2, scope, classes);
  if (recvJs == null) return null;
  final args = _extensionArgsJs(e, scope, classes);
  if (args == null) return null;
  return '${resolved.$1}.$member.call($recvJs${args.isEmpty ? '' : ', $args'})';
}

/// 显式 extension getter：`E(x).g` → `E.g.get.call(x)`。
String? _explicitExtensionGetterJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is! PropertyAccess) return null;
  final resolved = _extensionOverrideInfo(e.target, scope);
  if (resolved == null) return null;
  final scopeInfo = scope.extensionNames[resolved.$1];
  if (scopeInfo == null) return null;
  final member = e.propertyName.name;
  if (scopeInfo.members[member]?.contains(ExtensionMemberKind.getter) != true) {
    return null;
  }
  final recvJs = exprToJs(resolved.$2, scope, classes);
  if (recvJs == null) return null;
  return '${resolved.$1}.$member.get.call($recvJs)';
}

/// 显式扩展 setter：`E(x).g = v` / `E(x).g op= v` → `E.g.set.call(x, v)`。
///
/// 接收者与右值各求值一次（顺序与 Dart 一致：先接收者，再右值），赋值表达式的
/// 值是右值 / 复合运算结果（IIFE 里 `const __v` / `const __n` 承载）。
/// 只在该扩展确实声明了同名 setter 时接管；`??=` 需要 getter，未支持（出声丢弃）。
String? _explicitExtensionSetterJs(
  AssignmentExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final lhs = e.leftHandSide;
  if (lhs is! PropertyAccess) return null;
  final resolved = _extensionOverrideInfo(lhs.target, scope);
  if (resolved == null) return null;
  final ext = resolved.$1;
  final scopeInfo = scope.extensionNames[ext];
  if (scopeInfo == null) return null;
  final member = lhs.propertyName.name;
  final kinds = scopeInfo.members[member];
  if (kinds == null || !kinds.contains(ExtensionMemberKind.setter)) return null;
  final op = e.operator.lexeme;
  // 复合赋值要读回旧值：该扩展必须同时声明 getter（否则无值可读）。
  if (op != '=' &&
      (kinds == null || !kinds.contains(ExtensionMemberKind.getter))) {
    return null;
  }
  if (op == '??=') return null;
  final recvJs = exprToJs(resolved.$2, scope, classes);
  if (recvJs == null) return null;
  final rhsJs = rhsToJs(e.rightHandSide, scope, classes);
  if (rhsJs == null) return null;
  if (op == '=') {
    return '((__r) => { const __v = $rhsJs; $ext.$member.set.call(__r, __v); '
        'return __v; })($recvJs)';
  }
  final compound = _compoundBinaryJs('$ext.$member.get.call(__r)', op, '__v');
  if (compound == null) return null;
  return '((__r) => { const __v = $rhsJs; const __n = $compound; '
      '$ext.$member.set.call(__r, __n); return __n; })($recvJs)';
}

/// `E(x)` 的两种 AST 形态 → (扩展名, 接收者表达式)；不是扩展覆盖则 null。
///
///   - 已解析：`ExtensionOverride`（analyzer 给出专用节点）；
///   - 未解析：无接收者的裸名 `MethodInvocation`（`target == null` + 名称即扩展名）。
(String, Expression)? _extensionOverrideInfo(
  Expression? target,
  FieldScope scope,
) {
  if (target is ExtensionOverride) {
    if (target.importPrefix != null) return null;
    final name = target.name.lexeme;
    if (!scope.extensionNames.containsKey(name)) return null;
    final args = target.argumentList.arguments;
    if (args.length != 1 || args.first is NamedExpression) return null;
    return (name, args.first);
  }
  if (target is! MethodInvocation) return null;
  if (target.typeArguments != null || target.target != null) return null;
  final name = target.methodName.name;
  if (!scope.extensionNames.containsKey(name)) return null;
  final args = target.argumentList.arguments;
  if (args.length != 1 || args.first is NamedExpression) return null;
  return (name, args.first);
}

/// 扩展成员调用的实参：位置实参扁平 + 具名实参合并成尾参对象（与类方法同一
/// 调用约定）；不掺入 Map / 可调用对象等「按接收者类型改写」的分支。
String? _extensionArgsJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final positional = <String>[];
  final named = <String>[];
  for (final a in e.argumentList.arguments) {
    if (a is NamedExpression) {
      final inner = a.expression;
      final v = inner is FunctionExpression
          ? closureToJs(inner, scope, classes)
          : rhsToJs(inner, scope, classes);
      if (v == null) return null;
      named.add('${jsString(a.name.label.name)}: $v');
    } else if (a is FunctionExpression) {
      final v = closureToJs(a, scope, classes);
      if (v == null) return null;
      positional.add(v);
    } else {
      final v = rhsToJs(a, scope, classes);
      if (v == null) return null;
      positional.add(v);
    }
  }
  return [
    ...positional,
    if (named.isNotEmpty) '{ ${named.join(', ')} }',
  ].join(', ');
}

/// 方法调用的唯一实现；[receiverJs] 非空时跳过接收者解析（供空安全调用复用，
/// 接收者由外层解析好后直接拼在这里）；[nullAware] 决定接收者与成员之间用
/// `?.`（空安全）还是 `.`。
String? _methodCallJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes, {
  String? receiverJs,
  bool nullAware = false,
}) {
  // 泛型方法的类型实参（`context.watch<T>()` / `m<T>()`）不在这里特判：与构造
  // 走同一条规则——原样并入调用的尾参对象 `{ typeArguments: ['T'] }`（见下方
  // [typeArgs]，接收方 / 方法名一概不看）。
  final args = e.argumentList.arguments;
  final argJs = <String>[]; // 普通调用：位置化扁平（JS 无具名参数）
  final posJs = <String>[]; // 宿主注入：位置实参
  final namedJs = <String>[]; // 宿主注入：具名实参（`"名": 值`）
  for (final a in args) {
    // 闭包参数（addListener(() {...}) / TextButton(onPressed: () => ...) 等）：
    // 翻译成 JS 函数表达式，匿名天然支持——不合成方法名、无重名问题。
    // 闭包体逐语句翻译，setState(...) 展开为 this.setState(() => {...})。
    if (a is FunctionExpression) {
      final fnJs = closureToJs(a, scope, classes);
      if (fnJs == null) return null;
      argJs.add(fnJs);
      posJs.add(fnJs);
      continue;
    }
    // 命名方法引用（`_controller.addListener(_onControllerChanged)`）：Dart
    // tear-off 语义 → 箭头包装（this 词法绑定组件实例，与匿名闭包形态一致），
    // 参数透传以便用于带参回调（builder 等）。仅当名字是本组件方法时包装，
    // 状态字段/局部变量照常 rhsToJs。
    if (a is Identifier) {
      final ref = scope.methodRef(a.name);
      if (ref != null) {
        final wrap = '(...args) => $ref(...args)';
        argJs.add(wrap);
        posJs.add(wrap);
        continue;
      }
    }
    if (a is NamedExpression) {
      // 具名实参的闭包（`showDialog(context: …, builder: (ctx) => …)`、
      // `model.configure(onDone: () {...})`）：与位置实参同一口径走
      // [closureToJs]，否则 rhsToJs 对 FunctionExpression 返回 null，连带整个
      // 调用被判为不可翻译而丢弃（`builder` 里的组件树一起消失）。
      final inner = a.expression;
      final v = inner is FunctionExpression
          ? closureToJs(inner, scope, classes)
          : rhsToJs(inner, scope, classes);
      if (v == null) return null;
      // 具名实参只进尾参对象，不占位置（Dart `f(a, b: 1)` ⟺ JS `f(a, {b: 1})`）：
      // 运行时值类静态工厂（`EdgeInsets.symmetric({vertical: 4})`）与实例方法
      // 都按 props 取具名实参。
      namedJs.add('${jsString(a.name.label.name)}: $v');
    } else {
      final v = rhsToJs(a, scope, classes);
      if (v == null) return null;
      argJs.add(v);
      posJs.add(v);
    }
  }
  // 类型实参（`m<T>()` 的 `<T,...>`）→ 元信息 `typeArguments`，并入尾参对象。
  // 规则只看**实参形态**（不看接收方、不看方法名、不看类型）：
  //   - 无位置实参：尾参对象是唯一载体，任何 JS 方法都能安全收下
  //     （`context.watch<T>()` → `watch({ typeArguments: ['T'] })`）；
  //   - 有位置实参 + 有具名实参：并入同一个尾参对象（它本就是 props 约定载体）；
  //   - 有位置实参 + 无具名实参：尾对象会被目标当成第 N+1 个**位置实参**
  //     （如原生 `Array.reduce<T>(fn)` 的 initialValue），属语义污染，故擦除
  //     元信息并出声——与 dart2js 的擦除行为一致，绝不静默错译。
  final typeArgs = typeArgsOf(e, declared: _declaredTypeParamsFor(e, classes, scope));
  final typeArgsJs =
      typeArgs.isEmpty ? null : 'typeArguments: ${typeArgsMapJs(typeArgs)}';
  final keepTypeArgs =
      typeArgsJs != null && (argJs.isEmpty || namedJs.isNotEmpty);
  // 接收者以 **JS 内建**为运行时（List/Set/Map/String/Iterable 等）时，泛型
  // 实参在 JS 侧本就没有语义，擦除是正常行为、不需要出声；只有自定义类 /
  // 类型不可判定时，`typeArguments` 才可能是实现要读的元信息，擦除要告警。
  final receiverType =
      e.target == null ? null : _staticTypeOf(e.target!, scope, classes);
  final erasedByJsBuiltin =
      _jsBuiltinReceiverTypes.contains(eraseType(receiverType ?? ''));
  if (typeArgsJs != null && !keepTypeArgs && !erasedByJsBuiltin) {
    log.warning('[hot_patch_generator] ${sourceAt(scope.sourcePath, e)}: '
        '${e.methodName.name}<${typeArgs.values.join(', ')}> '
        '带位置实参且无具名实参，尾参对象会被当成位置实参，已擦除类型实参元信息');
  }
  final tailJs = [...namedJs, if (keepTypeArgs) typeArgsJs];
  // 位置实参原样，具名实参（与类型实参）合并成**尾参对象**（与构造
  // `new X({...})` 同形）；无尾参时不加空对象（`f()` 保持 `f()`）。
  // Map 的 `forEach`：原生 Map 回调是 (value, key)，Dart 是 (key, value)。
  // 不覆盖原生方法，只在调用点把回调参数交换后转发。
  if (e.methodName.name == 'forEach' &&
      e.target != null &&
      argJs.length == 1 &&
      namedJs.isEmpty &&
      _staticTypeOf(e.target!, scope, classes) == 'Map') {
    argJs[0] = '((__v, __k) => (${argJs[0]})(__k, __v))';
  }
  final passed = [
    ...argJs,
    if (tailJs.isNotEmpty) '{ ${tailJs.join(', ')} }',
  ].join(', ');
  if (receiverJs != null) {
    // Function 的 `call`：`fn?.call(a, b)` → `fn?.(a, b)`（Dart 的 call 没有
    // thisArg 参数，JS 的 Function.prototype.call 首参是 thisArg）。
    final tgt = e.target;
    if (tgt != null &&
        e.methodName.name == 'call' &&
        _isFunctionType(_staticTypeOf(tgt, scope, classes))) {
      return nullAware ? '$receiverJs?.($passed)' : '$receiverJs($passed)';
    }
    final dot = nullAware ? '?.' : '.';
    return '$receiverJs$dot${_memberCallName(e.target, e.methodName.name, scope, classes)}($passed)';
  }
  // Dart `E.values.byName('x')`（EnumByName 扩展）→ `E.byName('x')`：
  // 判据是标准库扩展的固定形态（`byName` + 接收者为 `<类/枚举>.values`），
  // 且前缀不是本作用域里的值（局部 / 形参 / 字段），不按业务方法名猜测。
  final byNameReceiver = e.target;
  if (e.methodName.name == 'byName' &&
      byNameReceiver is PrefixedIdentifier &&
      byNameReceiver.identifier.name == 'values' &&
      _rawTypeOfName(byNameReceiver.prefix.name, scope) == null) {
    return '${byNameReceiver.prefix.name}.byName($passed)';
  }
  final target = e.target;
  if (target == null) {
    // 方法体内的局部函数 / 持有函数的局部变量（`void f(){}` 后 `f(x)`）：
    // 名字已在作用域里登记，JS 侧就是同名局部标识符。局部名优先于宿主顶层
    // 函数与运行时全局函数（Dart 作用域同样遮蔽）。
    final name = e.methodName.name;
    // 可调用对象（声明了实例方法 call）：`f(...)` / 字段 `cb(...)` 落成
    // `recv.invoke(...)`（声明侧同名改名为 invoke，见手册 `call(...)` 行）。
    final recv = scope.fieldRef(name);
    if (recv != null &&
        _typeIsCallable(_rawTypeOfName(name, scope), classes)) {
      return '$recv.invoke($passed)';
    }
    // Function 的 `call`：Dart `fn.call(a, b)` 等价 `fn(a, b)`；JS
    // `Function.prototype.call` 的首参是 thisArg，语义不同 → 直接调用。
    // （可调用对象的 call 已在上面走 invoke；这里只处理函数类型。）
    if (name == 'call' && _isFunctionType(_rawTypeOfName(name, scope))) {
      return '${recv ?? name}($passed)';
    }
    // 类内部裸调用自身的 `call(...)`：方法已改名为 invoke。
    if (name == 'call' &&
        scope.methodRef('call') == null &&
        _typeIsCallable(scope.className, classes)) {
      return 'this.invoke($passed)';
    }
    if (scope.localVars.contains(name) || scope.params.contains(name)) {
      return '$name($passed)';
    }
    // Dart 顶层函数 `identical(a, b)` → `Object.is(a, b)`：NaN 与 -0 的语义
    // 与 Dart 一致。判据是**标准库顶层函数名**（不是业务方法名白名单），
    // 且只命中恰好两个位置实参、无具名实参 / 类型实参的形态。
    if (name == 'identical' &&
        argJs.length == 2 &&
        namedJs.isEmpty &&
        e.typeArguments == null) {
      return 'Object.is(${argJs[0]}, ${argJs[1]})';
    }
    // 顶层函数（全局方法）：**只有顶层** `@HostInjected` 函数在这里走通道——
    // 顶层函数没有可承载的 JS 类，产物里不存在同名函数。
    // 宿主通道的载荷会经 `Function.apply(impl, 位置, 具名)` 还原 Dart 调用语义，
    // 多出来的键会被当成真实具名参数而报「no named parameter」，故只传具名实参。
    final topChannel = scope.hostFunctions.contains(e.methodName.name)
        ? e.methodName.name
        : null;
    if (topChannel != null) {
      return '_app_host_.invoke(${jsString(topChannel)}, ${hostArgsJs(posJs, namedJs)})';
    }
    // 运行时注入的全局函数（`export function showDialog …` / `G.showModalBottomSheet`
    // 等）：Dart 的裸顶层调用在 JS 侧既没有 `this` 也没有宿主通道，只有 JS 侧
    // 确实存在同名函数时才能翻译，原样产出同名调用（纯 JS 函数，可安全带元信息）。
    if (runtimeGlobalFunctions().contains(e.methodName.name)) {
      return '${e.methodName.name}(${globalFnArgsJs(posJs, tailJs)})';
    }
    final member = scope.methodRef(e.methodName.name);
    if (member == null) return null;
    return '$member($passed)';
  }
  if (target is Identifier) {
    final callMember = _memberCallName(target, e.methodName.name, scope, classes);
    final ref = scope.fieldRef(target.name);
    if (ref != null) {
      // Function 的 `call`：`fn.call(a, b)` → `fn(a, b)`（去掉 thisArg 语义）。
      if (e.methodName.name == 'call' &&
          _isFunctionType(_staticTypeOf(target, scope, classes))) {
        return '$ref($passed)';
      }
      // 成员字段本身是「可调用对象」：`holder.cb(1)` → `holder.cb.invoke(1)`。
      if (e.methodName.name != 'invoke' &&
          _typeIsCallable(
              _rawMemberType(target, e.methodName.name, scope, classes),
              classes)) {
        return '$ref.${e.methodName.name}.invoke($passed)';
      }
      return '$ref.$callMember($passed)';
    }
    // receiver 是「类定义在某个产物模块里的类型」（`Overlay.of(context)` 等）：
    // 产出 `<类引用>.m(args)`，类引用串由钩子给出（含 import 登记）。
    final clsRef = classRefHook?.call(target.name);
    if (clsRef != null) return '$clsRef.$callMember($passed)';
    // 项目类（模型 / 静态类 / 组件）的静态方法调用（`HomeFeed.fromJson(e)`）：
    // JS 侧就是同名 class，静态方法挂在类上，1:1 产出 `X.m(args)`。类表的键
    // 即「本次分析可见的项目类名」，跨文件时 import 已由依赖收集生成。
    if (classes.containsKey(target.name)) {
      return '${target.name}.$callMember($passed)';
    }
    // 类方法静态调用（`MediaQuery.of(context)` / `Theme.of(context)`）：
    // receiver 是**类定义在运行时注入里**的类（`G.MediaQuery = …`，见
    // [runtimeGlobalTypes]），原样产出 `X.m(args)`。判断只看「类定义在哪」，
    // 与是不是组件无关。
    if (runtimeGlobalTypes().contains(target.name)) {
      return '${target.name}.$callMember($passed)';
    }
  }
  // `super.m(...)` 出现在**表达式**位置（`'${super.greet()} x'` 这类插值 / 赋值右值）：
  // 与语句级同一套落法——原生基类 → `super.m`；无 JS 基类 → 丢弃。
  if (target is SuperExpression) {
    if (scope.hasJsBase) return 'super.${e.methodName.name}($passed)';
    return null;
  }
  final t = exprToJs(target, scope, classes);
  if (t != null) {
    // Function 的 `call`：`fn.call(a, b)` → `fn(a, b)`。
    if (e.methodName.name == 'call' &&
        _isFunctionType(_staticTypeOf(target, scope, classes))) {
      return '$t($passed)';
    }
    // 成员字段本身是「可调用对象」：`holder.cb(1)` → `holder.cb.invoke(1)`。
    if (e.methodName.name != 'invoke' &&
        _typeIsCallable(
            _rawMemberType(target, e.methodName.name, scope, classes),
            classes)) {
      return '$t.${e.methodName.name}.invoke($passed)';
    }
    final callMember = _memberCallName(target, e.methodName.name, scope, classes);
    return '$t.$callMember($passed)';
  }
  return null;
}

/// 以 **JS 内建**为运行时的接收者类型：它们的方法由 JS 原生 / 运行时补齐实现，
/// 泛型实参在 JS 侧没有语义（与 dart2js 的擦除一致），`typeArguments` 元信息
/// 被擦除时不算「丢失信息」。自定义类不在此列——它们的实现可能真的读该元信息。
const Set<String> _jsBuiltinReceiverTypes = {
  'List',
  'Array',
  'Iterable',
  'Set',
  'Map',
  'String',
  'num',
  'int',
  'double',
};

/// 构建期成员名映射：**只对可判定为 JS 内建 Array（Dart `List`）的接收者**
/// 改写 `sort` → `_sort`、`join` → `_join`、`indexOf` → `_indexOf`（原生同名但
/// 默认语义不同，运行时挂下划线版本，不覆盖原生）。接收者类型不可判定 /
/// 是自定义类 / 是 Map 等其它类型时一律原样返回——绝不按方法名全局替换。
String _memberCallName(
  Expression? receiver,
  String member,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (receiver == null) return member;
  final type = _staticTypeOf(receiver, scope, classes);
  if (type == 'List') {
    if (member == 'sort') return '_sort';
    if (member == 'join') return '_join';
    if (member == 'indexOf') return '_indexOf';
  }
  // 可调用对象：显式 `obj.call(...)` 与声明侧同步改名为 `invoke`（手册
  // `call(...)` 行）；仅接收者静态类型可判定为「可调用类」时改写。
  if (member == 'call' && _typeIsCallable(type, classes)) return 'invoke';
  return member;
}

/// 是否为 Dart 函数类型（`Function` / `int Function(int)` / `void Function()`）。
bool _isFunctionType(String? typeRaw) {
  if (typeRaw == null) return false;
  final t = typeRaw.trim();
  return t == 'Function' || t.contains('Function(');
}

/// 类型（含 extends 链）是否为**可调用对象**（声明了非 static 的 `call`）。
///
/// 判据只来自类表：`ClassInfo.isCallable` 由 `classInfoOf` 按源码成员计算；
/// 父子类继承链一并检查（子类未重写 call 仍可调用）。类型不可判定返回 false，
/// 保持原样（不按名字猜测）。
bool _typeIsCallable(String? typeRaw, Map<String, ClassInfo> classes) {
  if (typeRaw == null) return false;
  var name = eraseType(typeRaw.split('.').last);
  final seen = <String>{};
  while (seen.add(name)) {
    final info = classes[name];
    if (info == null) return false;
    if (info.isCallable) return true;
    final sup = info.superType;
    if (sup == null) return false;
    name = eraseType(sup.split('.').last);
  }
  return false;
}

/// Map 的**属性成员**映射：JS Map 的 `keys` / `values` / `entries` 是**方法**
/// （且返回迭代器），Dart 是**属性**——同名但语义不同，改用运行时的 `_` 前缀
/// getter（`Map.prototype._keys` 等）。`length` / `isEmpty` / `isNotEmpty` 在
/// JS Map 上不存在，运行时直接补同名 getter，无需改名。
String _mapPropertyMember(
  Expression receiver,
  String member,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (_staticTypeOf(receiver, scope, classes) != 'Map') return member;
  switch (member) {
    case 'keys':
      return '_keys';
    case 'values':
      return '_values';
    case 'entries':
      return '_entries';
  }
  return member;
}

/// `<字段>.<属性>`（PrefixedIdentifier）→ JS 引用串（`this._count.value`）。
///
/// 用于 SDK 值对象（`ValueNotifier<int>` 等）的典型用法：字段本身走
/// [FieldScope.fieldRef]（→ `this._count` / 局部变量名），属性部分原样拼接
/// （JS 侧同名属性 / get 访问器）。LHS 不是「本 scope 可解析字段」时返回 null，
/// 交由调用方丢弃（保持「不可翻译不静默错译」的纪律）。
String? _prefixedFieldRef(Expression e, FieldScope scope) {
  if (e is! PrefixedIdentifier) return null;
  final base = scope.fieldRef(e.prefix.name);
  if (base == null) return null;
  return '$base.${e.identifier.name}';
}

/// `list.length = n`（PrefixedIdentifier 形式）→ `list._setLength(n)`；
/// 仅接收者可判定为 List 时改写，其它类型 / 不可判定返回 null（保持原样）。
String? _listLengthWriteJs(
  PrefixedIdentifier lhs,
  String op,
  String rhs,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (lhs.identifier.name != 'length' || op != '=') return null;
  if (_staticTypeOf(lhs.prefix, scope, classes) != 'List') return null;
  final recv = exprToJs(lhs.prefix, scope, classes);
  return recv == null ? null : '$recv._setLength($rhs)';
}

/// 纯标识符判定：`_x` 是，`_x.y`（[PrefixedIdentifier]）**不是**。
///
/// **不能只写 `is Identifier`**：analyzer 里 `PrefixedIdentifier` 也
/// `implements Identifier`，裸判定会把 `_count.value++` 当成字段 `_count.value`
/// 的标识符，`fieldRef` 解析不到就整条丢弃（静默丢代码）。
bool _isPlainIdentifier(Expression e) => e is Identifier && e is! PrefixedIdentifier;

/// 复合赋值（目标可安全重复读写时）：Dart 的 `~/=` 在 JS 没有对应运算符，
/// 按语义展开为 `a = Math.trunc(a / b)`（向零截断与 Dart 一致）。
///
/// 其余复合赋值 JS 同名同义，一比一透传；未知运算符返回 null（由调用方丢弃）。
/// 目标含下标或可能有副作用时不要用它，改用单次求值的临时参数（见下标赋值分支）。
String? _compoundAssignJs(String lhsJs, String op, String rhsJs) {
  if (op == '~/=') return '$lhsJs = Math.trunc($lhsJs / $rhsJs)';
  const jsOps = <String>{
    '=', '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '<<=', '>>=', '>>>=',
    '??=',
  };
  return jsOps.contains(op) ? '$lhsJs $op $rhsJs' : null;
}

/// 复合赋值运算符 → 等价的**二元表达式**（用于「读 getter → 运算 → 写 setter」）。
///
/// 与 [_compoundAssignJs] 的语义逐项对齐：`~/=` 向零截断（`Math.trunc`），其余
/// 位运算 / 算术与 JS 同名运算符一致；不支持的运算符返回 null（调用方出声）。
String? _compoundBinaryJs(String lhsJs, String op, String rhsJs) {
  if (op == '~/=') return 'Math.trunc($lhsJs / $rhsJs)';
  const binary = <String, String>{
    '+=': '+',
    '-=': '-',
    '*=': '*',
    '/=': '/',
    '%=': '%',
    '&=': '&',
    '|=': '|',
    '^=': '^',
    '<<=': '<<',
    '>>=': '>>',
    '>>>=': '>>>',
  };
  final b = binary[op];
  return b == null ? null : '$lhsJs $b $rhsJs';
}

/// 赋值出现在**表达式位置**（`while ((x = f()) < n)` / `if ((v = f()) != null)`）。
///
/// Dart 赋值表达式的值就是赋值结果，JS 同义，因此普通目标一比一发射（外层加
/// 括号保证优先级）。目标链含 `?.` / `?[` 时不能直接作 JS 赋值目标，落成带守卫
/// 的 IIFE：目标为空时表达式值为 `null`，且**右值与下标不求值**（与 Dart 一致）。
/// 语句位置见 [exprStmtToJs]；两处共用 `_compoundAssignJs` / [_prefixedFieldRef] /
/// [_operatorOwnerOf] / [_chainHasNullAware] 同一套原语，不另立判据。
String? _assignValueJs(
  AssignmentExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final setter = _explicitExtensionSetterJs(e, scope, classes);
  if (setter != null) return setter;
  final op = e.operator.lexeme;
  final rhs = rhsToJs(e.rightHandSide, scope, classes);
  if (rhs == null) return null;
  // 只接受有 JS 等价形态的赋值运算符（`~/=` 在下面单独展开）。
  if (op != '~/=' && _compoundAssignJs('__x', op, '__y') == null) return null;
  final lhs = e.leftHandSide;

  // `list.length = n`（`growable.length = 4` 这类 PrefixedIdentifier 目标）：
  // 接收者可判定为 List 时改写为 `_setLength`（原生写 length 会静默截断 / 扩展）。
  if (lhs is PrefixedIdentifier) {
    final len = _listLengthWriteJs(lhs, op, rhs, scope, classes);
    if (len != null) return '($len)';
  }

  // 纯引用目标（`_x` / 局部变量 / 字段属性 `_x.y`）：可安全重复读写。
  final ref = _isPlainIdentifier(lhs)
      ? scope.fieldRef((lhs as Identifier).name)
      : _prefixedFieldRef(lhs, scope);
  if (ref != null) {
    final rewritten = _compoundAssignJs(ref, op, rhs);
    return rewritten == null ? null : '($rewritten)';
  }

  // `super.x = v`：`super` 只能出现在成员访问位置、**不能作为值传递**（放进
  // IIFE 参数会变 SyntaxError），故直接发射成员赋值；JS class 语法天然支持。
  if (lhs is PropertyAccess && lhs.target is SuperExpression) {
    // `~/=` 要读两次属性（getter 执行两次），不产出近似语义：交由调用方告警。
    if (op == '~/=') return null;
    final rewritten =
        _compoundAssignJs('super.${lhs.propertyName.name}', op, rhs);
    return rewritten == null ? null : '($rewritten)';
  }

  // 下标 / 属性目标：接收者、下标、右值都只求值一次。
  if (lhs is! IndexExpression && lhs is! PropertyAccess) return null;
  final target =
      lhs is IndexExpression ? lhs.target : (lhs as PropertyAccess).target;
  if (target == null) return null;
  final recv = exprToJs(target, scope, classes);
  if (recv == null) return null;
  final indexJs =
      lhs is IndexExpression ? exprToJs(lhs.index, scope, classes) : null;
  if (lhs is IndexExpression && indexJs == null) return null;
  final member = lhs is IndexExpression
      ? '[$indexJs]'
      : '.${(lhs as PropertyAccess).propertyName.name}';
  final nullAware = _chainHasNullAware(lhs);

  // `list.length = n`：仅当接收者可判定为 List（JS Array）时改写成运行时
  // `_setLength(n)`（原生写 length 会静默截断 / 扩展；Dart growable list 的
  // 「截断 / 补 null」语义由运行时方法承接）。其它类型 / 不可判定时原样。
  if (lhs is PropertyAccess &&
      lhs.propertyName.name == 'length' &&
      op == '=' &&
      _staticTypeOf(target, scope, classes) == 'List') {
    if (nullAware) {
      return '((__t) => { if (__t == null) return null; '
          'return __t._setLength($rhs); })($recv)';
    }
    return '($recv._setLength($rhs))';
  }

  // `operator []=`：只支持 `=` 形态（与语句位置一致）；表达式值为右值。
  final extSet = extensionOperatorMember(
    scope.extensionOperators,
    _staticTypeOf(target, scope, classes),
    '[]=',
  );
  if (lhs is IndexExpression &&
      op == '=' &&
      (_operatorOwnerOf(target, '[]=', scope, classes) != null ||
          extSet != null)) {
    final set = operatorJsName('[]=', unary: false)!;
    if (nullAware) {
      // 目标为空时右值不求值（IIFE 参数只传接收者）。
      return '((__t) => { if (__t == null) return null; '
          'const __v = $rhs; __t.$set($indexJs, __v); return __v; })($recv)';
    }
    return '((__t, __i, __v) => { __t.$set(__i, __v); return __v; })'
        '($recv, $indexJs, $rhs)';
  }

  // Map 下标写：类型可判定为 Map → `set`；不可判定 → `__idxSet`。
  if (lhs is IndexExpression &&
      op == '=' &&
      _operatorOwnerOf(target, '[]=', scope, classes) == null &&
      extSet == null) {
    if (_staticTypeOf(target, scope, classes) == 'Map') {
      if (nullAware) {
        return '((__t) => { if (__t == null) return null; '
            'const __v = $rhs; __idxSet(__t, $indexJs, __v); '
            'return __v; })($recv)';
      }
      return '((__t, __i, __v) => { __idxSet(__t, __i, __v); return __v; })'
          '($recv, $indexJs, $rhs)';
    }
  }

  // `~/=`：JS 没有该运算符，展开为「读 → 算 → 写」，表达式值即写入值。
  if (op == '~/=') {
    if (nullAware) {
      final read = lhs is IndexExpression ? '__t[$indexJs]' : '__t$member';
      return '((__t) => { if (__t == null) return null; '
          'return ($read = Math.trunc($read / $rhs)); })($recv)';
    }
    if (lhs is IndexExpression) {
      return '((__t, __i) => { '
          'return (__t[__i] = Math.trunc(__t[__i] / $rhs)); })'
          '($recv, $indexJs)';
    }
    return '((__t) => { '
        'return (__t$member = Math.trunc(__t$member / $rhs)); })($recv)';
  }

  // 其余赋值：空安全目标加守卫（下标 / 右值留在体内，目标为空时不求值），
  // 普通目标一比一发射，JS 赋值表达式本身就返回赋值结果。
  if (nullAware) {
    return '((__t) => { if (__t == null) return null; '
        'return (__t$member $op $rhs); })($recv)';
  }
  return '($recv$member $op $rhs)';
}

/// 一条表达式语句 → JS 语句（带分号）。
///
/// 支持：`_x++ / _x-- / ++_x / --_x`（字段→this）、赋值 `_x = rhs / _x op= rhs`、
/// 字段属性赋值/自增 `_x.y = rhs` / `_x.y++`（[`_prefixedFieldRef`]）、
/// 方法调用（对象方法 / 白名单裸调）。不可翻译返回 null（由调用方丢弃）。
String? exprStmtToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // `throw <expr>;`：Dart 的 throw 在 AST 里是 ThrowExpression（包在
  // ExpressionStatement 里），JS 的 throw 是语句，这里直接产出 `throw ...;`。
  if (e is ThrowExpression) {
    final v = rhsToJs(e.expression, scope, classes);
    return v == null ? null : 'throw $v;';
  }
  // `rethrow;`：Dart 只允许出现在 catch 内，抛出的必须是**原始异常对象**。
  // 捕获子句的唯一绑定名是 `__e`（见 [_tryStatementJs]），闭包内同样可见，
  // 因此一比一发射 `throw __e;`（不重建 Error，栈保持原样）。
  if (e is RethrowExpression) return 'throw __e;';
  // _x++ / ++_x / _x--（只认自增 / 自减；`x!` 是空断言，不能按 -= 1 处理）
  if (e is PostfixExpression && _isPlainIdentifier(e.operand) &&
      (e.operator.type.name == 'PLUS_PLUS' ||
          e.operator.type.name == 'MINUS_MINUS')) {
    final ref = scope.fieldRef((e.operand as Identifier).name);
    if (ref != null) {
      final delta = e.operator.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$ref += $delta;';
    }
    return null;
  }
  if (e is PrefixExpression && _isPlainIdentifier(e.operand) &&
      (e.operator.type.name == 'PLUS_PLUS' ||
          e.operator.type.name == 'MINUS_MINUS')) {
    final ref = scope.fieldRef((e.operand as Identifier).name);
    if (ref != null) {
      final delta = e.operator.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$ref += $delta;';
    }
    return null;
  }
  // 独立空断言语句 `s!;`：项目口径忽略断言，仅保留操作数求值。
  if (e is PostfixExpression && e.operator.lexeme == '!') {
    final v = exprToJs(e.operand, scope, classes);
    return v == null ? null : '$v;';
  }
  if (e is AssignmentExpression && _isPlainIdentifier(e.leftHandSide)) {
    final ref = scope.fieldRef((e.leftHandSide as Identifier).name);
    if (ref != null) {
      final rhs = rhsToJs(e.rightHandSide, scope, classes);
      if (rhs != null) {
        final rewritten = _compoundAssignJs(ref, e.operator.lexeme, rhs);
        if (rewritten != null) return '$rewritten;';
      }
    }
    return null;
  }
  // 显式扩展 setter：`E(x).g = v` / `E(x).g op= v` → `E.g.set.call(x, …)`。
  if (e is AssignmentExpression) {
    final setter = _explicitExtensionSetterJs(e, scope, classes);
    if (setter != null) return '$setter;';
  }
  // 下标 / 属性赋值（任意层）：`a[i] = v`、`a.b = v`、`a?.b.c = v`、
  // `a?._scores?[1] = 1` …… 只有一条规则，深度不增加任何分支。
  //
  // JS 不允许可选链出现在**赋值目标**里（`a?.[i] = v` / `a?.b[i] = v` 都是
  // SyntaxError），因此只要目标链上出现过 `?.` / `?[`，就落成「前缀单次求值 +
  // 非空守卫」：
  //   `((__t) => { if (__t != null) __t[1] = 1; })(this._obj?._scores)`
  // 前缀本身按普通表达式翻译（`?.` 链仍是原生可选链，null 时短路为 undefined），
  // 层数再多也只是前缀更长，不会嵌套守卫。链上没有空安全则直接赋值。
  if (e is AssignmentExpression &&
      (e.leftHandSide is IndexExpression ||
          e.leftHandSide is PropertyAccess)) {
    final lhs = e.leftHandSide;
    final target = lhs is IndexExpression
        ? lhs.target
        : (lhs as PropertyAccess).target;
    if (target == null) return null;
    // `super` 不是值：`~/.` 的 IIFE 展开会把它当参数传递（非法 JS），不支持。
    if (target is SuperExpression && e.operator.lexeme == '~/=') return null;
    final recv = exprToJs(target, scope, classes);
    if (recv == null) return null;
    // `operator []=`：接收者静态类型声明了下标赋值运算符时改写成成员调用。
    // 只支持 `=` 形态（`+=` 等复合赋值语义不同，保持原生路径）。
    final extSet = extensionOperatorMember(
      scope.extensionOperators,
      _staticTypeOf(target, scope, classes),
      '[]=',
    );
    if (lhs is IndexExpression &&
        e.operator.lexeme == '=' &&
        (_operatorOwnerOf(target, '[]=', scope, classes) != null ||
            extSet != null)) {
      final index = exprToJs(lhs.index, scope, classes);
      final rhs = rhsToJs(e.rightHandSide, scope, classes);
      if (index == null || rhs == null) return null;
      final set = operatorJsName('[]=', unary: false)!;
      if (_chainHasNullAware(e.leftHandSide)) {
        return '((__t) => { if (__t != null) '
            '__t.$set($index, $rhs); })($recv);';
      }
      return '$recv.$set($index, $rhs);';
    }
    // Map 下标写：类型可判定为 Map → `set`；不可判定 → `__idxSet`。
    if (lhs is IndexExpression &&
        e.operator.lexeme == '=' &&
        _operatorOwnerOf(target, '[]=', scope, classes) == null &&
        extSet == null) {
      if (_staticTypeOf(target, scope, classes) == 'Map') {
        final index = exprToJs(lhs.index, scope, classes);
        final rhs = rhsToJs(e.rightHandSide, scope, classes);
        if (index == null || rhs == null) return null;
        if (_chainHasNullAware(e.leftHandSide)) {
          return '((__t) => { if (__t != null) __idxSet(__t, $index, $rhs); })($recv);';
        }
        return '__idxSet($recv, $index, $rhs);';
      }
    }
    final String member;
    final String? indexJs;
    if (lhs is IndexExpression) {
      final index = exprToJs(lhs.index, scope, classes);
      if (index == null) return null;
      indexJs = index;
      member = '[$index]';
    } else {
      indexJs = null;
      member = '.${(lhs as PropertyAccess).propertyName.name}';
    }
    final rhs = rhsToJs(e.rightHandSide, scope, classes);
    if (rhs == null) return null;
    final op = e.operator.lexeme;
    // `list.length = n`：仅当接收者可判定为 List（JS Array）时改写为
    // `_setLength(n)`（与值位置同一判据；其它对象 / 不可判定保持原样）。
    if (lhs is PropertyAccess &&
        lhs.propertyName.name == 'length' &&
        op == '=' &&
        _staticTypeOf(target, scope, classes) == 'List') {
      return _chainHasNullAware(e.leftHandSide)
          ? '((__t) => { if (__t != null) __t._setLength($rhs); })($recv);'
          : '$recv._setLength($rhs);';
    }
    // `~/=`：JS 没有这个复合运算符，按语义展开成「读 → 算 → 写」。
    // 接收者与下标都只求值一次（`a[f()] ~/= 2` 不能把 `f` 调两次），目标是
    // 下标时把下标绑成第二个临时参数。
    if (op == '~/=') {
      final read = indexJs == null ? '__t$member' : '__t[__i]';
      final write = '$read = Math.trunc($read / $rhs)';
      final body = _chainHasNullAware(e.leftHandSide)
          ? 'if (__t != null) $write'
          : write;
      if (indexJs != null) {
        return '((__t, __i) => { $body; })($recv, $indexJs);';
      }
      return '((__t) => { $body; })($recv);';
    }
    // 判据看**整条目标链**（含最外层选择器）：`a?[i] = v` 的空安全在 LHS 本身，
    // `a?.b.c = v` 的在更内层——两者都要守卫。
    if (_chainHasNullAware(e.leftHandSide)) {
      return '((__t) => { if (__t != null) '
          '__t$member $op $rhs; })($recv);';
    }
    return '$recv$member $op $rhs;';
  }
  // `list.length = n`（`growable.length = 4` 这类 PrefixedIdentifier 目标）：
  // 接收者可判定为 List 时改写为 `_setLength`。
  if (e is AssignmentExpression && e.leftHandSide is PrefixedIdentifier) {
    final rhs = rhsToJs(e.rightHandSide, scope, classes);
    if (rhs == null) return null;
    final len = _listLengthWriteJs(
        e.leftHandSide as PrefixedIdentifier, e.operator.lexeme, rhs, scope, classes);
    if (len != null) return '$len;';
  }
  // 字段的属性赋值 / 自增（`_count.value = 5`、`_count.value++`）：
  // SDK 值对象（ValueNotifier / Listenable 代理类）的典型用法，LHS 是
  // PrefixedIdentifier（`<字段>.<属性>`）。字段部分走 fieldRef（→ `this._count`），
  // 属性部分原样保留（JS 侧同名属性/访问器，如 ValueNotifier.prototype.value）。
  if (e is AssignmentExpression && _prefixedFieldRef(e.leftHandSide, scope) != null) {
    final lhs = _prefixedFieldRef(e.leftHandSide, scope)!;
    final rhs = rhsToJs(e.rightHandSide, scope, classes);
    if (rhs != null) {
      final rewritten = _compoundAssignJs(lhs, e.operator.lexeme, rhs);
      if (rewritten != null) return '$rewritten;';
    }
    return null;
  }
  if ((e is PostfixExpression || e is PrefixExpression)) {
    final operand = e is PostfixExpression ? e.operand : (e as PrefixExpression).operand;
    final op = e is PostfixExpression ? e.operator : (e as PrefixExpression).operator;
    // 空安全目标 `a?[i]++` / `a?.x++`：JS 可选链不能作写目标，走单次求值守卫。
    if ((op.lexeme == '++' || op.lexeme == '--') &&
        _chainHasNullAware(operand) &&
        (operand is IndexExpression || operand is PropertyAccess)) {
      final guarded = _nullAwareUpdateJs(
          operand, op.lexeme, scope, classes,
          prefix: e is PrefixExpression, statement: true);
      return guarded == null ? null : '$guarded;';
    }
    final lhs = _prefixedFieldRef(operand, scope);
    if (lhs != null) {
      final delta = op.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$lhs += $delta;';
    }
    // 普通下标 / 属性自增（`a[i]++` / `a.b++`）：语句位置不关心返回值，
    // 直接落成 `+= 1` / `-= 1`（接收者与下标都只求值一次）。
    if (operand is IndexExpression || operand is PropertyAccess) {
      final target = operand is IndexExpression
          ? operand.target
          : (operand as PropertyAccess).target;
      if (target == null) return null;
      final recv = exprToJs(target, scope, classes);
      if (recv == null) return null;
      final String member;
      if (operand is IndexExpression) {
        final index = exprToJs(operand.index, scope, classes);
        if (index == null) return null;
        member = '[$index]';
      } else {
        member = '.${(operand as PropertyAccess).propertyName.name}';
      }
      final delta = op.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$recv$member += $delta;';
    }
  }
  // 独立语句 `await <expr>;`：await 的翻译统一在 rhsToJs 里。
  if (e is AwaitExpression) {
    final v = rhsToJs(e, scope, classes);
    return v == null ? null : '$v;';
  }
  if (e is MethodInvocation) return methodCallStmtJs(e, scope, classes);
  return null;
}

/// 操作数的静态类型（显式注解 / 项目类构造推断）；未知返回 null。
///
/// 只有「类型可判定」时才把运算符重载改写成成员调用，避免按名字猜测类型。
String? _staticTypeOf(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is ParenthesizedExpression) {
    return _staticTypeOf(e.expression, scope, classes);
  }
  // 集合字面量的静态类型直接由源码形态给出（`[...]` → List、`{...}` →
  // Set / Map）：供「按接收者内建类型决定的成员映射」（Array sort / join）
  // 判定，不猜类型。
  if (e is ListLiteral) return 'List';
  if (e is SetOrMapLiteral) return e.isSet ? 'Set' : 'Map';
  // 级联表达式 `expr..m()` 的类型就是 target 的类型（级联返回 target 本身）。
  if (e is CascadeExpression) return _staticTypeOf(e.target, scope, classes);
  if (e is SimpleIdentifier) return scope.typeOf(e.name);
  if (e is ThisExpression) return scope.className;
  // `this._car`：字段声明类型（含继承链字段视图）。
  if (e is PropertyAccess && e.target is ThisExpression) {
    return scope.typeOf(e.propertyName.name);
  }
  // 成员链（`bucket.nums` / `oldWidget.list`）：按字段声明的原始类型解析，
  // 内置类型（List / Map / String 等）也照实返回，供成员映射表按接收者类型
  // 判定；解析不到时保持 null（不按名字猜测）。
  if (e is PrefixedIdentifier) {
    final t = _rawMemberType(e.prefix, e.identifier.name, scope, classes);
    return t == null ? null : eraseType(t.split('.').last);
  }
  if (e is PropertyAccess && e.target != null && e.target is! SuperExpression) {
    final t = _rawMemberType(e.target!, e.propertyName.name, scope, classes);
    return t == null ? null : eraseType(t.split('.').last);
  }
  String? raw;
  if (e is InstanceCreationExpression) {
    raw = e.constructorName.type.toSource();
  } else if (e is MethodInvocation && e.target is SimpleIdentifier) {
    // `Money.of(...)` / `Xxx.fromJson(...)`：receiver 是项目类名时按该类推断。
    raw = (e.target as SimpleIdentifier).name;
  } else if (e is MethodInvocation && e.target == null && e.typeArguments == null) {
    // 无 `new` 的项目类构造（`SportCar()`）：parseString 下是 MethodInvocation。
    // 名字命中类表才认（否则可能是普通函数调用）。
    raw = e.methodName.name;
  }
  if (raw == null) return null;
  final bare = eraseType(raw.split('.').last);
  return classes.containsKey(bare) ? bare : null;
}

/// 操作数是否**可能**为 null / undefined（决定判空 / 相等比较是否包 `__nn`）。
///
/// 判据只来自源码事实：字面量 / 构造 / 集合字面量不会为空；标识符与
/// `this.x` 看**声明的原始类型**（`String` 非空、`String?` / `dynamic` 可空）；
/// 类型不可判定（方法调用、下标、普通属性链等）按「可能为空」保守处理。
bool _mayBeNull(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is NullLiteral) return true;
  // 编译期字面量（字符串 / 数字 / bool / 常量运算）不会为空。
  if (literalToJs(e) != null) return false;
  // 字符串插值的结果一定是字符串。
  if (e is StringInterpolation) return false;
  // `x!` 的语义就是非空（项目按「忽略 !」翻译，但仍视为非空）。
  if (e is PostfixExpression && e.operator.lexeme == '!') return false;
  if (e is ThisExpression) return false;
  if (e is InstanceCreationExpression) return false;
  if (e is ListLiteral || e is SetOrMapLiteral) return false;
  String? raw;
  if (e is SimpleIdentifier) {
    raw = _rawTypeOfName(e.name, scope);
  } else if (e is PrefixedIdentifier) {
    // 前缀不是本作用域里的值（局部 / 形参 / 字段）时，它是类 / 命名空间引用：
    // `Orientation.portrait` / `Colors.red` 这类静态成员访问不会产出 undefined
    // （缺失的引用会直接抛 ReferenceError，而不是一个 undefined 值）。
    if (_rawTypeOfName(e.prefix.name, scope) == null) return false;
    raw = _rawMemberType(e.prefix, e.identifier.name, scope, classes);
  } else if (e is PropertyAccess &&
      e.target != null &&
      e.target is! SuperExpression) {
    raw = _rawMemberType(e.target!, e.propertyName.name, scope, classes);
  }
  if (raw == null) return true;
  final t = raw.trim();
  if (t == 'dynamic' || t == 'Object' || t == 'Null' || t.endsWith('?')) {
    return true;
  }
  return false;
}

/// 名字的**原始**声明类型（保留 `?`）：局部变量 / 形参 / 实例字段，未知返回 null。
String? _rawTypeOfName(String name, FieldScope scope) {
  if (scope.localVars.contains(name)) return scope.localTypes[name];
  if (scope.params.contains(name)) return scope.paramTypes[name];
  if (scope.instanceFields.contains(name)) return scope.fieldTypes[name];
  return null;
}

/// 成员访问的**原始**声明类型（保留 `?`），只解析能从源码事实得到的链：
/// `this.x` / `widget.x` / `expr.x`（expr 的声明类型是项目类时查类表字段）。
String? _rawMemberType(
  Expression receiver,
  String member,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // `this.x` 与 State 内 `widget.x` 在 JS 侧都是合并类的实例字段。
  if (receiver is ThisExpression ||
      (receiver is SimpleIdentifier && receiver.name == 'widget')) {
    return scope.fieldTypes[member];
  }
  final ownerRaw = _rawExprType(receiver, scope, classes);
  if (ownerRaw == null) return null;
  final owner = eraseType(ownerRaw.split('.').last);
  // 内建集合 / 字符串的已知非空成员（不属于“可能为空”的范围）。
  if (member == 'length' &&
      (owner == 'List' ||
          owner == 'Iterable' ||
          owner == 'Set' ||
          owner == 'Map' ||
          owner == 'String')) {
    return 'int';
  }
  // Dart 的 `hashCode` 在所有对象上都是 `int`（非空），无需按 owner 细分。
  if (member == 'hashCode') return 'int';
  if ((member == 'isEmpty' || member == 'isNotEmpty') &&
      (owner == 'List' ||
          owner == 'Iterable' ||
          owner == 'Set' ||
          owner == 'Map' ||
          owner == 'String')) {
    return 'bool';
  }
  final info = classes[owner];
  if (info == null) return null;
  for (final f in objectFieldsOf(info, classes)) {
    if (f.name == member) return f.typeName;
  }
  return null;
}

/// 表达式的**原始**声明类型（用于成员链解析）；无法从源码事实判定时返回 null。
String? _rawExprType(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is ParenthesizedExpression) {
    return _rawExprType(e.expression, scope, classes);
  }
  if (e is SimpleIdentifier) return _rawTypeOfName(e.name, scope);
  if (e is PropertyAccess && e.target is ThisExpression) {
    return scope.fieldTypes[e.propertyName.name];
  }
  if (e is PrefixedIdentifier) {
    return _rawMemberType(e.prefix, e.identifier.name, scope, classes);
  }
  if (e is PropertyAccess && e.target != null) {
    return _rawMemberType(e.target!, e.propertyName.name, scope, classes);
  }
  // `Map<K,V>.of(x)` 之类的构造：擦除类型实参后的类名，供局部变量类型推断
  // （`final m = Map.of(src)` 之后的 `m.keys` / `m[k]` 才能按 Map 映射）。
  if (e is InstanceCreationExpression) {
    var src = e.constructorName.type.toSource();
    final lt = src.indexOf('<');
    if (lt >= 0) src = src.substring(0, lt);
    return src.trim();
  }
  return null;
}

/// [member] 在 [typeName] 的实例成员里是否是**方法**（而非 getter）。
///
/// 返回 null = 类型不在类表（SDK / 常量 / 类名 / 无法推断）：无法判定，
/// 调用方保持原样产出，不按名字猜测。
bool? _isInstanceMethodMember(
  String? typeName,
  String member,
  Map<String, ClassInfo> classes,
) {
  final t = typeName == null ? null : eraseType(typeName);
  final info = t == null ? null : classes[t];
  if (info == null) return null;
  if (!objectMethodNamesOf(info, classes).contains(member)) return false;
  return !objectGetterNamesOf(info, classes).contains(member);
}

/// `obj.method` 值位置 → 绑定接收者的 tear-off；不适用时返回 null（原样产出）。
///
/// Dart 的 tear-off 自带 `this`，JS 的 `obj.m` 不带；getter 是值读取，不能绑定。
/// 接收者**只求值一次**：简单引用（`this` / 形参 / 局部变量 / 实例字段）直接
/// `recv.m.bind(recv)`，其余表达式落成 IIFE（避免 `make().m.bind(make())` 调两次）。
String? _tearOffMemberJs({
  required String receiverJs,
  required Expression receiver,
  required String member,
  required FieldScope scope,
  required Map<String, ClassInfo> classes,
  bool nullAware = false,
}) {
  final type = _staticTypeOf(receiver, scope, classes);
  if (_isInstanceMethodMember(type, member, classes) != true) return null;
  final simple = receiver is ThisExpression ||
      (receiver is SimpleIdentifier &&
          (scope.params.contains(receiver.name) ||
              scope.localVars.contains(receiver.name) ||
              scope.instanceFields.contains(receiver.name)));
  if (nullAware) {
    // `a?.m`：a 为 null 时整链短路（JS 可选链不会执行 `.bind`）。
    return simple
        ? '$receiverJs?.$member.bind($receiverJs)'
        : '((__o) => __o == null ? null : __o.$member.bind(__o))'
            '($receiverJs)';
  }
  return simple
      ? '$receiverJs.$member.bind($receiverJs)'
      : '((__o) => __o.$member.bind(__o))($receiverJs)';
}

/// 声明了 [symbol] 运算符的类（沿 extends 链查找）；没有则返回 null。
///
/// 一元 / 二元同名运算符（`operator -`）按形参个数区分：`unary` 为真时只认
/// 零参声明。`!=` 在 Dart 里不可重载，按 `==` 的声明判定。
ClassInfo? _operatorOwnerOf(
  Expression operand,
  String symbol,
  FieldScope scope,
  Map<String, ClassInfo> classes, {
  bool unary = false,
}) {
  final type = _staticTypeOf(operand, scope, classes);
  if (type == null) return null;
  final lookup = symbol == '!=' ? '==' : symbol;
  ClassInfo? c = classes[type];
  while (c != null) {
    for (final m in c.methods) {
      if (m.operatorSymbol != lookup) continue;
      final matches = unary ? m.params.isEmpty : m.params.isNotEmpty;
      if (matches) return c;
    }
    final sup = c.superType == null ? null : eraseType(c.superType);
    c = sup == null ? null : classes[sup];
  }
  return null;
}

/// 赋值目标链上是否出现空安全选择器（`?.` / `?[` / `?.m()`）。
///
/// 只看选择器链本身：括号会截断 Dart 的空安全短路（`(a?.b).c = v` 在 `a`
/// 为 null 时是抛错而非跳过），故不进入 [ParenthesizedExpression]。
bool _chainHasNullAware(Expression e) {
  if (e is PropertyAccess) {
    return e.operator.lexeme == '?.' ||
        (e.target != null && _chainHasNullAware(e.target!));
  }
  if (e is IndexExpression) {
    return e.isNullAware || (e.target != null && _chainHasNullAware(e.target!));
  }
  if (e is MethodInvocation) {
    return e.isNullAware || (e.target != null && _chainHasNullAware(e.target!));
  }
  return false;
}

/// `a?[i]++` / `a?.x++`（`++` / `--`）→ 接收者前缀单次求值的守卫 IIFE。
///
/// JS 的可选链不能出现在自增 / 自减的写目标里（`a?.[i]++` 是 SyntaxError），
/// 故取目标链的**前缀表达式**只求值一次，再在守卫内对成员执行更新：
///   - 值位置：目标为空时表达式值为 `null`，非空时返回 `++` / `--` 的结果
///     （后缀返回旧值、前缀返回新值，直接交给 JS 的更新表达式本身）；
///   - 语句位置：目标为空时整句跳过。
String? _nullAwareUpdateJs(
  Expression operand,
  String op,
  FieldScope scope,
  Map<String, ClassInfo> classes, {
  bool prefix = false,
  bool statement = false,
}) {
  final String member;
  final Expression? target;
  if (operand is IndexExpression) {
    target = operand.target;
    final idx = exprToJs(operand.index, scope, classes);
    if (idx == null) return null;
    member = '[$idx]';
  } else if (operand is PropertyAccess) {
    target = operand.target;
    member = '.${operand.propertyName.name}';
  } else {
    return null;
  }
  if (target == null) return null;
  final recv = exprToJs(target, scope, classes);
  if (recv == null) return null;
  final base = '__t$member';
  final update = prefix ? '$op$base' : '$base$op';
  if (statement) {
    return '((__t) => { if (__t != null) $update; })($recv)';
  }
  return '((__t) => { if (__t == null) return null; '
      'return ($update); })($recv)';
}

// ---------------------------------------------------------------------------
// 类 JS 声明渲染
// ---------------------------------------------------------------------------

/// **唯一**的「方法体 → JS」翻译器：组件动作/State 生命周期、模型方法、状态类
/// 方法全部走这里。
///
/// 语句（表达式语句 / 变量声明 / return / if …）与表达式（[exprToJs]/[rhsToJs]/
/// [exprStmtToJs]）都只在这一处与那一处处理——新增一种语法/能力，组件与普通类
/// 同时生效，不存在「组件的搞一遍、普通类再搞一遍」。
///
/// 参数：
///   - [scope]：标识符解析作用域（组件：状态字段→属性；模型：实例字段）。
///   - [renderer]：可选。传入后，返回 Widget 的表达式（如 `return Container(...)`）
///     走 widget 树翻译路径。
///   - [returnExpressionBody]：箭头体是否包 `return`（Dart 有返回值语义时为真；
///     组件动作方法为假，产物与语句一致）。
String translateMethodBody(
  FunctionBody? body,
  FieldScope scope,
  Map<String, ClassInfo> classes, {
  ExprRenderer? renderer,
  bool returnExpressionBody = false,
  bool returnsWidget = true,
  int depth = 2,
}) {
  final out = <String>[];
  final ind = '  ' * depth;
  if (body is ExpressionFunctionBody) {
    final e = body.expression;
    String? t;
    if (renderer != null && returnsWidget && renderer.ctorJsClassFile(e) != null) {
      t = _widgetExprToJs(renderer, e, depth);
    }
    t ??= _bodyExprStmtJs(e, scope, classes);
    if (t != null) {
      out.add('$ind${returnExpressionBody ? 'return $t;' : t}');
    } else {
      // 语句级不认的表达式（switch 表达式、集合字面量、纯值表达式）：回退到
      // 通用表达式翻译。缺这一步会让「箭头体方法」静默产出空方法体
      // （如 `Color _statusColor(s) => switch (s) {...}` → 空 `{}`）。
      final v = rhsToJs(e, scope, classes);
      if (v != null) {
        out.add('$ind${returnExpressionBody ? 'return $v;' : v}');
      } else {
        log.warning('[hot_patch_generator] 方法体表达式无法翻译，已在 JS '
            '产物中丢弃：${e.toSource()}');
      }
    }
  } else if (body is BlockFunctionBody) {
    final r = translateStmtList(body.block.statements, scope, classes, renderer,
        depth: depth, returnsWidget: returnsWidget);
    if (r.isNotEmpty) out.add(r);
  }
  return out.isEmpty ? '' : out.join('\n');
}

/// 「纯字段路径」形初始化器：`x` / `feed.spots` / `this.a.b`——只有标识符与点号，
/// 没有调用、下标、运算、await。变量声明的**别名折算**只对这类形态生效（见
/// [translateStmtList] 的声明分支）：折算出的别名是「按引用重求值」语义，
/// 带调用的表达式一旦被折算，每次使用都会重跑，语义就不再等价。
final RegExp _fieldPath = RegExp(
  r'^[A-Za-z_$][A-Za-z0-9_$]*(?:\s*\.\s*[A-Za-z_$][A-Za-z0-9_$]*)*\s*$',
);

/// 语句列表 → JS（方法体块、if 分支体共用同一套循环）。
///
/// 支持：表达式语句（super 调用忽略、setState 展开）、变量声明、return、
/// if/else、for（三段式 / for-in）、while、do-while、switch（常量 case）、
/// break / continue。无法翻译的语句出声告警（不静默丢代码）。
///
/// 输出为**多行可读**格式：每条语句一行、按 [depth] 缩进（2 空格/层）。
String translateStmtList(
  List<Statement> stmts,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  ExprRenderer? renderer, {
  int depth = 0,
  bool returnsWidget = true,
}) {
  final out = <String>[];
  final ind = '  ' * depth;
  for (final s in stmts) {
    if (s is ExpressionStatement) {
      final e = s.expression;
      // super 调用：有 JS 基类 → 原生 `super.m(...)`（application 类链由引擎沿
      // 原型链解析）；无 JS 基类（SDK 类在 JS 侧无实现）→ 丢弃。
      if (e is MethodInvocation && e.target is SuperExpression) {
        if (!scope.hasJsBase) continue;
        final argsJs = <String>[];
        var ok = true;
        for (final a in e.argumentList.arguments) {
          final inner = a is NamedExpression ? a.expression : a;
          final v = inner is FunctionExpression
              ? closureToJs(inner, scope, classes)
              : rhsToJs(inner, scope, classes);
          if (v == null) {
            ok = false;
            break;
          }
          argsJs.add(v);
        }
        if (!ok) {
          log.warning('[hot_patch_generator] '
              '${sourceAt(scope.sourcePath, e)}: super 调用实参无法翻译，已在 JS '
              '产物中丢弃：${e.toSource()}');
          continue;
        }
        // 表达式位置（`f(super.x())`）走 rhsToJs 的同一分支；这里覆盖语句级。
        out.add('$ind' 'super.${e.methodName.name}(${argsJs.join(', ')});');
        continue;
      }
      final t = _bodyExprStmtJs(e, scope, classes);
      if (t != null) {
        out.add('$ind$t');
      } else {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, e)}: 语句无法翻译，已在 JS 产物中'
            '丢弃：${e.toSource()}');
      }
    } else if (s is VariableDeclarationStatement) {
      // 局部变量声明 `String? name = await X.y();` → `let name = ...;` /
      // `const name = ...;`（`final` / `const` 声明生成 `const`，`var` 与
      // 无修饰声明生成 `let`；不生成 `var`）。无初始化器时显式补 `= null`：
      // Dart 的空值只有 null，JS 的 `let x;` 是 undefined（判空会漏掉）。
      final keyword = s.variables.isFinal || s.variables.isConst ? 'const' : 'let';
      for (final v in s.variables.variables) {
        final name = v.name.lexeme;
        // 同步登记到 widget 层：方法体里随后 `return Text('$name')` 时，
        // widget 翻译器要用同一份局部变量表解析标识符（与语句翻译同源）；
        // 类型一并登记，树里的 `m._keys` / `m[k]` 才能按 Map 接收者改写。
        if (v.initializer == null) {
          out.add('${ind}$keyword $name = null;');
          scope.localVars.add(name);
          final declared = s.variables.type?.toSource();
          if (declared != null) scope.localTypes[name] = declared;
          renderer?.registerLocal(name, type: declared);
          continue;
        }
        // 初始化器单独用一份作用域（[FieldScope.forInitializer]）：把**已登记
        // 的字段别名**折算进来，方法体其余语句不受影响。
        //
        // 只对「纯字段路径」（`x` / `feed.spots` / `this.a.b`，无调用、下标、运算）
        // 折算：别的形态（`ctx.findRenderObject()`、`label + "…"`）一旦折算，
        // 局部会被登记成「按引用重求值」的别名，那**每一次使用**都要重跑——
        // 有调用的表达式（GlobalKey.currentContext、List.removeAt）重跑即语义
        // 不同，会把既有产物改坏。链式别名的收益只发生在字段路径上，收窄到它即可。
        final purePath = _fieldPath.hasMatch(v.initializer!.toSource());
        // 初始化器按通用表达式翻译：`const Text('x')` → `new Text({...})`
        // （组件包装类构造即产出元素，普通类产出实例，运行时统一归一化）。
        final init = rhsToJs(
          v.initializer!,
          purePath ? scope.forInitializer() : scope,
          classes,
        );
        if (init == null) {
          // 变量没声明 → 后面引用它的语句（含插值）会连带失效，必须出声。
          log.warning('[hot_patch_generator] '
              '${sourceAt(scope.sourcePath, v)}: 局部变量声明无法翻译，已在 JS '
              '产物中丢弃：${s.toSource()}');
          continue;
        }
        out.add('${ind}$keyword $name = $init;');
        scope.localVars.add(name);
        // 局部变量的静态类型（显式注解优先，其次按声明 / 构造推断）：
        // 供后续语句里的运算符重载分派（`total + item` → `total.__op$add(item)`）
        // 与判空归一（`final error = vm.error;` 必须保留 `String?` 的可空性）。
        // 先取**原始**类型（保留 `?`），拿不到再退回擦除后的推断类型。
        final declaredType = s.variables.type?.toSource();
        final inferred = declaredType ??
            _rawExprType(v.initializer!, scope, classes) ??
            _staticTypeOf(v.initializer!, scope, classes);
        if (inferred != null) scope.localTypes[name] = inferred;
        renderer?.registerLocal(name, type: inferred);
        // 该局部只是「字段 / getter 的别名」（`final list = _list;` →
        // `this._list`）：登记进 widget 层，懒加载 builder 抽成实例方法后引用它
        // 时才能落到 `this._list`，而不是未定义的自由变量（`ReferenceError`）。
        //
        // 同时记进 [FieldScope.declAliases]，供**后续声明的初始化器**折算——
        // 链式别名靠这一步闭合：`final spots = feed.spots;` 里的 `feed` 先折成
        // `this._feed`，`spots` 于是也成了字段别名。缺这一步，二级别名会以裸名
        // 进产物（`spots[index]`），被抽进 builder 方法后就是
        // `ReferenceError: Can't find variable: spots`。
        //
        // 仅限 **纯字段路径**（见 [_fieldPath]）与 final / const：别名语义是
        // 「按引用重求值」，带调用的初始化器（`this._items.removeAt(0)`）一旦
        // 登记成别名，builder / 事件闭包里的每次引用都会重跑该调用；可重新赋值
        // 的变量用它则会让后续声明拿到旧表达式（`list = other;` 之后按旧值折算）。
        if (purePath && init.startsWith('this.')) {
          renderer?.registerLocalAlias(name, init);
          if (s.variables.isFinal || s.variables.isConst) {
            scope.declAliases[name] = init;
          }
        }
      }
    } else if (s is PatternVariableDeclarationStatement) {
      // 解构声明 `final [a, b] = list;` / `final User(:name) = user;`
      // （`var x = 1` 这类普通声明仍是 VariableDeclarationStatement）。
      final js = _patternDeclarationJs(s, scope, classes, renderer, depth);
      if (js == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: pattern 变量声明无法翻译，已在 JS '
            '产物中丢弃：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is FunctionDeclarationStatement) {
      // 方法体内的局部函数 `void f(...) {...}` / `int f(...) => ...`
      final js = _localFunctionJs(s, scope, classes, renderer, depth);
      if (js == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: 局部函数无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is ReturnStatement) {
      // `return "22";` 是 ReturnStatement（不是 ExpressionStatement），
      // 需单独翻译为 `return <expr>;`，否则 async 方法体被整体丢弃。
      final e = s.expression;
      if (e == null) {
        out.add('${ind}return;');
        continue;
      }
      String? v;
      if (renderer != null && returnsWidget && renderer.ctorJsClassFile(e) != null) {
        v = _widgetExprToJs(renderer, e, depth);
      }
      v ??= rhsToJs(e, scope, classes);
      if (v != null) {
        out.add('${ind}return $v;');
      } else {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: return 表达式无法翻译，已在 JS '
            '产物中丢弃：${s.toSource()}');
      }
    } else if (s is YieldStatement) {
      // 生成器产出：`yield e;` / `yield* e;`（委托）与 JS 同形，一比一发射。
      // 产物所在的函数必须是 `function*` / `*method` / `async function*`
      // （见 [closureToJs] 与 dart2js 的方法渲染），否则 JS 侧是语法错误。
      final v = rhsToJs(s.expression, scope, classes);
      if (v == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: yield 表达式无法翻译，已在 JS '
            '产物中丢弃：${s.toSource()}');
      } else {
        out.add('${ind}yield${s.star != null ? '*' : ''} $v;');
      }
    } else if (s is IfStatement) {
      if (s.caseClause != null) {
        // `if (x case P)` 的判据是模式匹配，不是条件表达式。统一交给
        // [_ifCaseStatementJs]（与 pattern 变量声明共用 [_compilePattern]）。
        final js = _ifCaseStatementJs(
            s, scope, classes, renderer, depth, returnsWidget);
        if (js == null) {
          log.warning('[hot_patch_generator] '
              '${sourceAt(scope.sourcePath, s)}: if-case 模式匹配无法翻译，已在 JS '
              '产物中丢弃：${s.toSource()}');
        } else {
          out.add(js);
        }
        continue;
      }
      final condJs = exprToJs(s.expression, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: if 条件无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
        continue;
      }
      final thenStmts =
          s.thenStatement is Block ? (s.thenStatement as Block).statements : [s.thenStatement];
      var js = '$ind' 'if ($condJs) {\n'
          '${translateStmtList(thenStmts, scope, classes, renderer, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind}';
      final els = s.elseStatement;
      if (els != null) {
        final elseStmts = els is Block ? els.statements : [els];
        js += ' else {\n'
            '${translateStmtList(elseStmts, scope, classes, renderer, depth: depth + 1, returnsWidget: returnsWidget)}\n'
            '$ind}';
      }
      out.add(js);
    } else if (s is ForStatement) {
      final js = _forStatementJs(s, scope, classes, renderer, depth, returnsWidget);
      if (js == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: for 语句无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is WhileStatement) {
      final condJs = exprToJs(s.condition, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: while 条件无法翻译，已在 JS 产物'
            '中丢弃：${s.toSource()}');
        continue;
      }
      out.add('$ind' 'while ($condJs) {\n'
          '${translateStmtList(_bodyStmts(s.body), scope, classes, renderer, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind}');
    } else if (s is DoStatement) {
      final condJs = exprToJs(s.condition, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: do-while 条件无法翻译，已在 JS '
            '产物中丢弃：${s.toSource()}');
        continue;
      }
      out.add('$ind' 'do {\n'
          '${translateStmtList(_bodyStmts(s.body), scope, classes, renderer, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind} while ($condJs);');
    } else if (s is SwitchStatement) {
      final js = _switchStatementJs(s, scope, classes, renderer, depth, returnsWidget);
      if (js == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: switch 语句无法翻译（仅支持常量 '
            'case），已在 JS 产物中丢弃：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is LabeledStatement) {
      // `outer: for (…) { … break outer; }`：JS 原生支持标签语句与带标签的
      // break / continue，一比一发射（标签加在被标记语句的首行前）。
      final prefix = [for (final l in s.labels) '${l.label.name}: '].join();
      final inner = translateStmtList([s.statement], scope, classes, renderer,
          depth: depth, returnsWidget: returnsWidget);
      if (inner.trim().isEmpty) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: label 语句无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
      } else {
        out.add(inner.replaceFirst('$ind', '$ind$prefix'));
      }
    } else if (s is BreakStatement) {
      final label = s.label?.name;
      out.add('${ind}break${label == null ? '' : ' $label'};');
    } else if (s is ContinueStatement) {
      final label = s.label?.name;
      out.add('${ind}continue${label == null ? '' : ' $label'};');
    } else if (s is AssertStatement) {
      // Dart `assert(condition, [message])` → JS 原样调用 `assert(...)`；
      // 函数本体由运行时【1c】节注入（debug 门控 + 失败抛 Error），
      // 生成器不改写语义，保持与 Dart 源码一比一。
      final condJs = exprToJs(s.condition, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: assert 条件无法翻译，已在 JS 产物'
            '中跳过：${s.toSource()}');
        continue;
      }
      String? msgJs;
      final message = s.message;
      if (message != null) {
        msgJs = rhsToJs(message, scope, classes);
        if (msgJs == null) {
          log.warning('[hot_patch_generator] '
              '${sourceAt(scope.sourcePath, message)}: assert 消息无法翻译，已在 JS 产物'
              '中跳过：${s.toSource()}');
          continue;
        }
      }
      out.add('$ind' 'assert($condJs${msgJs == null ? '' : ', $msgJs'});');
    } else if (s is TryStatement) {
      final js =
          _tryStatementJs(s, scope, classes, renderer, depth, returnsWidget);
      if (js == null) {
        log.warning('[hot_patch_generator] '
            '${sourceAt(scope.sourcePath, s)}: try 语句无法翻译，已在 JS 产物中'
            '跳过：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is EmptyStatement) {
      // 空语句没有语义，跳过不需要告警。
    } else if (s is Block) {
      // 裸块语句：作用域语义在 JS 侧由 `{}` 保留，逐条递归即可。
      out.add('$ind{\n'
          '${translateStmtList(s.statements, scope, classes, renderer, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind}');
    } else {
      // 兜底：任何未覆盖的语句都必须出声，禁止静默丢代码。
      // 典型：try/catch、throw、assert、局部函数、pattern 声明、label 等。
      log.warning('[hot_patch_generator] 不支持的语句类型 ${s.runtimeType}，'
          '已在 JS 产物中跳过：${s.toSource()}');
    }
  }
  return out.join('\n');
}

/// 语句体 → 语句列表（Block 或单条语句统一成列表，供 translateStmtList 递归）。
List<Statement> _bodyStmts(Statement s) => s is Block ? s.statements : [s];

/// 级联 section 的访问链 → 以 `_t`（已求值一次的级联 target）为根的 JS 引用。
///
/// analyzer 对级联内的相对访问（`..x` / `..[i]` / `..a.b`）用**无 target** 的
/// `PropertyAccess` / `IndexExpression` 表示，故 `target == null` 即级联 target
/// 本身，换成 `_t`；其余层逐层展开，`..a.b` 得到 `_t.a.b`、`..[i] = v` 得到
/// `_t[i] = v`。无法识别的形态返回 null（调用方整条级联告警，不静默）。
String? _cascadeRefJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is PropertyAccess) {
    final target = e.target;
    final base = target == null ? '_t' : _cascadeRefJs(target, scope, classes);
    return base == null ? null : '$base.${e.propertyName.name}';
  }
  if (e is IndexExpression) {
    final target = e.target;
    final index = e.index;
    if (index == null) return null;
    final base = target == null ? '_t' : _cascadeRefJs(target, scope, classes);
    final idx = exprToJs(index, scope, classes);
    if (base == null || idx == null) return null;
    return '$base[$idx]';
  }
  return null;
}

/// 局部函数声明 `void f(...) {...}` / `int f(...) => ...` → `var f = <闭包>;`
///
/// 与闭包共用 [closureToJs]：函数体与闭包 / 方法体走同一条语句翻译路径，箭头
/// 函数也保留 `this`（Dart 局部函数同样捕获外层 `this`）。名称先登记进作用域，
/// 递归调用与后续语句的裸调用按同名局部标识符解析（见 `_methodCallJs`）。
///
/// 不支持：生成器 —— JS 函数没有等价签名，出现时返回 null（调用方出声告警）。
/// 局部函数须先声明后调用（Dart 同样如此：局部声明不提升，前向引用是编译错误）。
/// 可选 / 具名形参与默认值由 [closureToJs] 统一处理；泛型局部函数的类型形参
/// 也在此登记（`T` 读尾参对象的 `typeArguments`）。
String? _localFunctionJs(
  FunctionDeclarationStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  ExprRenderer? renderer,
  int depth,
) {
  final decl = s.functionDeclaration;
  final fn = decl.functionExpression;
  final name = decl.name.lexeme;
  scope.localVars.add(name);
  // 泛型局部函数：登记类型参数名，裸调用（`f<int>()`）据此把类型实参写成
  // **参数名键**（`{"T": "int"}`），与函数体读取 `T` 的口径一致；不登记会退化
  // 成位置序号键，定义侧读 `["T"]` 就是 undefined。
  final tps = fn.typeParameters?.typeParameters ?? const <TypeParameter>[];
  if (tps.isNotEmpty) {
    scope.localTypeParams[name] = [for (final tp in tps) tp.name.lexeme];
  }
  renderer?.registerLocal(name);
  final js = closureToJs(fn, scope, classes, renderer);
  if (js == null) return null;
  return '${'  ' * depth}const $name = $js;';
}

// ---------------------------------------------------------------------------
// 模式匹配（`if (x case P)` / pattern 变量声明）
//
// **一条实现**：[_compilePattern] 把任意模式编译成「顺序检查 + 绑定赋值」，
// 两个语法入口（if-case / 解构声明）只是外层骨架不同。Dart 的匹配语义按短路
// 顺序落成 `if (!(cond)) return false;`，因此 `&&`、嵌套对象 / 列表模式天然
// 获得「前面不匹配就不读后面的字段」的行为；`||` 的两个分支各自独立求值。
// 无法翻译的模式一律返回 null，由调用方出声告警（禁止静默丢弃）。
// ---------------------------------------------------------------------------

/// 模式编译暂存：绑定变量名 + 顺序执行的检查 / 赋值语句 + 临时变量序号。
///
/// 外层固定持有一个匹配值 `__v0`；子模式的临时值按遍历顺序编号（`__v1`…），
/// 同一份源码始终产出同一串名字。
class _PatternPlan {
  final List<String> names = [];
  final List<String> lines = [];
  int _seq = 0;
  String temp() => '__v${++_seq}';
}

/// `if (x case P when g)` → 接收值只求值一次、绑定只在 then 分支可见。
///
/// ```js
/// {
///   const __v0 = <expr>;
///   let a, b;
///   const __ok = (() => {
///     <检查 / 绑定>
///     return (<guard>);
///   })();
///   if (__ok) { ... } else { ... }
/// }
/// ```
String? _ifCaseStatementJs(
  IfStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  ExprRenderer? renderer,
  int depth,
  bool returnsWidget,
) {
  final matched = exprToJs(s.expression, scope, classes);
  if (matched == null) return null;
  final guarded = s.caseClause!.guardedPattern;
  final plan = _PatternPlan();
  // 模式绑定只在命中分支可见：翻译完 then / else 后把注入的局部名还原，
  // 避免方法后续语句里同名的字段被当成「已出块的局部变量」。
  final localVarsBefore = {...scope.localVars};
  if (!_compilePatternWithGuard(
      guarded.pattern, guarded.whenClause?.expression, plan, scope, classes)) {
    scope.localVars
      ..clear()
      ..addAll(localVarsBefore);
    return null;
  }
  if (guarded.whenClause == null) plan.lines.add('return true;');
  for (final n in plan.names) {
    renderer?.registerLocal(n);
  }
  final ind = '  ' * depth;
  final inner = '  ' * (depth + 2);
  final b = StringBuffer()
    ..writeln('$ind{')
    ..writeln('${ind}  const __v0 = $matched;');
  if (plan.names.isNotEmpty) {
    b.writeln('${ind}  let ${plan.names.toSet().join(', ')};');
  }
  b.writeln('${ind}  const __ok = (() => {');
  for (final l in plan.lines) {
    b.writeln('$inner$l');
  }
  b.writeln('${ind}  })();');
  b.writeln('${ind}  if (__ok) {');
  b.writeln(translateStmtList(_bodyStmts(s.thenStatement), scope, classes,
      renderer,
      depth: depth + 2, returnsWidget: returnsWidget));
  b.writeln('$ind  }');
  final els = s.elseStatement;
  if (els != null) {
    b.writeln('${ind}  else {');
    b.writeln(translateStmtList(_bodyStmts(els), scope, classes, renderer,
        depth: depth + 2, returnsWidget: returnsWidget));
    b.writeln('$ind  }');
  }
  b.writeln('$ind}');
  scope.localVars
    ..clear()
    ..addAll(localVarsBefore);
  return b.toString().trimRight();
}

/// 解构声明 `final [a, b] = list;` / `final User(:name) = user;`
///
/// 绑定必须留在**当前作用域**（后续语句要引用），故不包块、用 `var`（JS 允许
/// 在同一作用域内重复 `var`，不会与另一处解构撞名）。Dart 里解构不匹配会抛错，
/// 这里同样抛错，绝不带着 undefined 的绑定继续执行。
String? _patternDeclarationJs(
  PatternVariableDeclarationStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  ExprRenderer? renderer,
  int depth,
) {
  final init = rhsToJs(s.declaration.expression, scope, classes);
  if (init == null) return null;
  final plan = _PatternPlan();
  if (!_compilePatternWithGuard(
      s.declaration.pattern, null, plan, scope, classes)) {
    return null;
  }
  for (final n in plan.names) {
    scope.localVars.add(n);
    renderer?.registerLocal(n);
  }
  plan.lines.add('return true;');
  final ind = '  ' * depth;
  final b = StringBuffer()
    ..writeln('$ind' 'var __v0 = $init;');
  if (plan.names.isNotEmpty) {
    b.writeln('$ind' 'var ${plan.names.toSet().join(', ')};');
  }
  b.writeln('${ind}if (!(() => {');
  for (final l in plan.lines) {
    b.writeln('${ind}  $l');
  }
  b.writeln('${ind}})()) {');
  b.writeln('${ind}  throw new Error('
      '${jsString('pattern 变量声明未匹配：${s.toSource()}')});');
  b.writeln('$ind}');
  return b.toString().trimRight();
}

/// 模式 + 可选 `when` 守卫的统一入口（if-case 与解构声明共用）。
bool _compilePatternWithGuard(
  DartPattern pattern,
  Expression? guard,
  _PatternPlan plan,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (!_compilePattern(pattern, '__v0', plan, scope, classes)) return false;
  // 绑定名先登记：guard 与 then 分支里的引用都按局部变量解析。
  scope.localVars.addAll(plan.names);
  if (guard != null) {
    final g = exprToJs(guard, scope, classes);
    if (g == null) return false;
    plan.lines.add('return ($g);');
  }
  return true;
}

/// 把模式 [p] 编译进 [plan]（[value] 已是 JS 表达式）。
bool _compilePattern(
  DartPattern p,
  String value,
  _PatternPlan plan,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final known = classes.keys.toSet();
  if (p is WildcardPattern) return true;
  if (p is ParenthesizedPattern) {
    return _compilePattern(p.pattern, value, plan, scope, classes);
  }
  // 常量模式：字面量 / 枚举成员 / 顶层常量 → 严格相等（Dart `==` 在 JS 侧的
  // 基本值与枚举成员上就是 `===`）。
  if (p is ConstantPattern) {
    final v = exprToJs(p.expression, scope, classes);
    if (v == null) return false;
    plan.lines.add('if (!($value === $v)) return false;');
    return true;
  }
  // 声明变量模式：`var x` / `final x` / `int x` → 绑定（带类型注解时先做类型检查）。
  if (p is DeclaredVariablePattern) {
    if (p.type != null) {
      final test = typeTestJs(p.type!.toSource(), value, knownClasses: known);
      if (test == null) return false;
      plan.lines.add('if (!($test)) return false;');
    }
    final name = p.name.lexeme;
    plan.names.add(name);
    plan.lines.add('$name = $value;');
    return true;
  }
  // 关系模式：`case > 0` / `case <= n`。
  if (p is RelationalPattern) {
    final rhs = exprToJs(p.operand, scope, classes);
    if (rhs == null) return false;
    plan.lines.add('if (!($value ${p.operator.lexeme} $rhs)) return false;');
    return true;
  }
  // 空检查模式：`case var x?` → 非空后再匹配子模式。
  if (p is NullCheckPattern) {
    final t = plan.temp();
    plan.lines.add('const $t = $value;');
    plan.lines.add('if ($t == null) return false;');
    return _compilePattern(p.pattern, t, plan, scope, classes);
  }
  // 逻辑与：顺序执行即短路（前一步失败直接 return false）。
  if (p is LogicalAndPattern) {
    if (!_compilePattern(p.leftOperand, value, plan, scope, classes)) {
      return false;
    }
    return _compilePattern(p.rightOperand, value, plan, scope, classes);
  }
  // 逻辑或：两个分支各自完整求值，成功者写出绑定（Dart 要求两侧绑定同名变量）。
  if (p is LogicalOrPattern) {
    final left = _PatternPlan();
    final right = _PatternPlan();
    if (!_compilePattern(p.leftOperand, value, left, scope, classes)) {
      return false;
    }
    if (!_compilePattern(p.rightOperand, value, right, scope, classes)) {
      return false;
    }
    plan.names.addAll({...left.names, ...right.names});
    final t = plan.temp();
    plan.lines.add('const $t = (() => { ${left.lines.join(' ')} '
        'return true; })() || (() => { ${right.lines.join(' ')} '
        'return true; })();');
    plan.lines.add('if (!$t) return false;');
    return true;
  }
  // 对象模式：`User(name: final n)` / `User(:n)` → instanceof + 逐字段取值。
  if (p is ObjectPattern) {
    final test = typeTestJs(p.type.toSource(), value, knownClasses: known);
    if (test == null) return false;
    plan.lines.add('if (!($test)) return false;');
    for (final f in p.fields) {
      final getter = f.effectiveName;
      if (getter == null) return false;
      final t = plan.temp();
      plan.lines.add('const $t = $value.$getter;');
      if (!_compilePattern(f.pattern, t, plan, scope, classes)) return false;
    }
    return true;
  }
  // 列表模式：`[a, b]` 定长；`[a, ...rest]` 至少 a 个，rest 为剩余切片。
  if (p is ListPattern) {
    final els = p.elements;
    var restIndex = -1;
    for (var i = 0; i < els.length; i++) {
      if (els[i] is RestPatternElement) {
        // Dart 的 rest 只允许一处，且只翻译末位形态（其余出声丢弃）。
        if (restIndex >= 0 || i != els.length - 1) return false;
        restIndex = i;
      }
    }
    final fixed = restIndex >= 0 ? restIndex : els.length;
    plan.lines.add(restIndex >= 0
        ? 'if (!(Array.isArray($value) && $value.length >= $fixed)) '
            'return false;'
        : 'if (!(Array.isArray($value) && $value.length === $fixed)) '
            'return false;');
    for (var i = 0; i < fixed; i++) {
      final el = els[i];
      if (el is! DartPattern) return false;
      final t = plan.temp();
      plan.lines.add('const $t = $value[$i];');
      if (!_compilePattern(el, t, plan, scope, classes)) return false;
    }
    if (restIndex >= 0) {
      final rest = els[restIndex] as RestPatternElement;
      final sub = rest.pattern;
      if (sub != null) {
        final t = plan.temp();
        plan.lines.add('const $t = $value.slice($fixed);');
        if (!_compilePattern(sub, t, plan, scope, classes)) return false;
      }
    }
    return true;
  }
  // 记录模式：`case (a, b)` / `case (x: a)` / `case (1, 'a')`。
  //
  // record 的 JS 表示是**普通对象**（`_recordLiteralJs`：位置字段 `"$1"`…`"$N"`、
  // 命名字段原名），故解构即逐字段取值再递归匹配；JS 侧无法区分 record 与普通
  // 对象，只做 `typeof === "object"` 的浅检查（Dart 的 record 类型检查依赖静态
  // 类型，运行期本就没有额外信息）。
  if (p is RecordPattern) {
    if (p.fields.isEmpty) {
      plan.lines.add('if ($value == null || typeof $value !== "object") '
          'return false;');
      return true;
    }
    var positional = 0;
    for (final f in p.fields) {
      final fieldName = f.name;
      final name = fieldName?.name?.lexeme;
      final key = name ?? '\$${++positional}';
      plan.lines.add('if ($value == null || typeof $value !== "object") '
          'return false;');
      final t = plan.temp();
      plan.lines.add('const $t = $value[${jsString(key)}];');
      if (!_compilePattern(f.pattern, t, plan, scope, classes)) return false;
    }
    return true;
  }
  // 类型转换 / 其它模式：JS 侧无表示或未覆盖，出声丢弃。
  return false;
}

/// for 语句 → JS（三段式与 for-in）：
///   - `for (var i = 0; i < n; i++)` → 一比一（循环变量登记进 localVars）；
///   - `for (var x in list)` → `for (var x of list)`（Dart 可迭代 → JS 数组）。
/// 不可翻译返回 null（调用方出声告警）。
String? _forStatementJs(
  ForStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  ExprRenderer? renderer,
  int depth,
  bool returnsWidget,
) {
  final parts = s.forLoopParts;
  String? header;
  if (parts is ForEachPartsWithDeclaration) {
    // for-in 声明式：`for (var x in list)` → `for (var x of list)`。
    final name = parts.loopVariable.name.lexeme;
    scope.localVars.add(name);
    final it = exprToJs(parts.iterable, scope, classes);
    if (it == null) return null;
    header = 'for (let $name of $it)';
  } else if (parts is ForEachPartsWithIdentifier) {
    // for-in 复用已有变量：`for (x in list)` → `for (x of list)`。
    final it = exprToJs(parts.iterable, scope, classes);
    if (it == null) return null;
    header = 'for (${parts.identifier.name} of $it)';
  } else if (parts is ForEachPartsWithPattern) {
    // `for (final [a, b] in pairs)` / `for (final User(:name) in users)`：
    // per-item 模式匹配，复用解构声明的同一条 _compilePattern。绑定只在本轮
    // 循环体内可见；不匹配按 Dart 语义抛错（不是静默跳过）。
    final it = exprToJs(parts.iterable, scope, classes);
    if (it == null) return null;
    final plan = _PatternPlan();
    final before = {...scope.localVars};
    if (!_compilePattern(parts.pattern, '__v', plan, scope, classes)) {
      scope.localVars
        ..clear()
        ..addAll(before);
      return null;
    }
    plan.lines.add('return true;');
    scope.localVars.addAll(plan.names);
    final ind = '  ' * depth;
    final indIn = '  ' * (depth + 1);
    final pre = StringBuffer();
    if (plan.names.isNotEmpty) {
      pre.writeln('${indIn}let ${plan.names.toSet().join(', ')};');
    }
    pre.writeln('${indIn}if (!(() => {');
    for (final l in plan.lines) {
      pre.writeln('$indIn  $l');
    }
    pre.writeln('$indIn  })()) {');
    pre.writeln('$indIn    throw new Error('
        '${jsString('pattern for 未匹配：${parts.toSource()}')});');
    pre.writeln('$indIn}');
    final bodyJs = translateStmtList(_bodyStmts(s.body), scope, classes, renderer,
        depth: depth + 1, returnsWidget: returnsWidget);
    scope.localVars
      ..clear()
      ..addAll(before);
    final awaitKw = s.awaitKeyword != null ? 'await ' : '';
    return '$ind' 'for $awaitKw(const __v of $it) {\n$pre$bodyJs\n$ind}';
  } else if (parts is ForParts) {
    // 三段式：`for (var i = 0; i < n; i++)` → 一比一。
    final inits = <String>[];
    if (parts is ForPartsWithDeclarations) {
      final keyword =
          parts.variables.isFinal || parts.variables.isConst ? 'const' : 'let';
      for (final v in parts.variables.variables) {
        final name = v.name.lexeme;
        scope.localVars.add(name);
        if (v.initializer == null) {
          inits.add('let $name = null');
          continue;
        }
        final rhs = rhsToJs(v.initializer!, scope, classes);
        if (rhs == null) return null;
        inits.add('$keyword $name = $rhs');
      }
    } else if (parts is ForPartsWithExpression) {
      final init = parts.initialization;
      if (init != null) {
        final t = exprToJs(init, scope, classes);
        if (t == null) return null;
        inits.add(t);
      }
    } else {
      return null; // ForPartsWithPattern：Dart 3 模式 for 头
    }
    String? condJs;
    if (parts.condition != null) {
      condJs = exprToJs(parts.condition!, scope, classes);
      if (condJs == null) return null;
    }
    final upds = <String>[];
    for (final u in parts.updaters) {
      final t = exprToJs(u, scope, classes);
      if (t == null) return null;
      upds.add(t);
    }
    header = 'for (${inits.join(', ')}; ${condJs ?? ''}; ${upds.join(', ')})';
  } else {
    return null;
  }
  // `await for (final x in stream)`：Dart 的异步迭代 → JS `for await (... of ...)`，
  // 依赖被迭代对象的 `[Symbol.asyncIterator]`（Stream 能力模块提供）。
  if (s.awaitKeyword != null) {
    header = header.replaceFirst('for (', 'for await (');
  }
  final ind = '  ' * depth;
  final bodyJs = translateStmtList(_bodyStmts(s.body), scope, classes, renderer,
      depth: depth + 1, returnsWidget: returnsWidget);
  return '$ind$header {\n$bodyJs\n$ind}';
}

/// `try { ... } catch (e) { ... } finally { ... }` → JS 同构。
///
/// 当前支持范围（基础功能）：
///   - 无 `on` 类型的 `catch (e)` / `catch (e, s)`：完整翻译；`s` 绑定
///     `e.stack`（JS 没有独立的 StackTrace 对象）；
///   - `finally`：完整翻译；
///   - 带 `on Type` 或多个 catch 子句：按 catch-all 近似，并输出构建期告警
///     （不做类型过滤，避免没有类型解析时误判）。
///
/// 返回 null 表示结构非法（既无 catch 也无 finally），由调用方告警。
String? _tryStatementJs(
  TryStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  ExprRenderer? renderer,
  int depth,
  bool returnsWidget,
) {
  final ind = '  ' * depth;
  final catches = s.catchClauses;
  final finallyBlock = s.finallyBlock;
  if (catches.isEmpty && finallyBlock == null) return null;

  final bodyJs = translateStmtList(
    s.body.statements,
    scope,
    classes,
    renderer,
    depth: depth + 1,
    returnsWidget: returnsWidget,
  );

  var catchPart = '';
  if (catches.isNotEmpty) {
    // Dart 支持多个 catch 子句 + `on Type` 过滤；JS 只有一个 catch 参数，
    // 故用「统一捕获名 `__e` + if/else 链」表达，顺序与 Dart 一致：
    //   try { … } catch (__e) {
    //     if (__e instanceof FormatException) { … }
    //     else if (…) { … }
    //     else { … }            // 无类型的 catch（catch-all）
    //     else { throw __e; }    // 未命中任何子句：原样重抛
    //   }
    // 类型判别走 typeTestJs（项目类 instanceof / SDK 错误类由运行时注入）。
    const exName = '__e';
    final known = classes.keys.toSet();
    final lines = <String>[' catch ($exName) {'];
    var first = true;
    var closed = false; // 已出现 catch-all（或类型不可判别）→ 后续子句不可达
    for (final clause in catches) {
      if (closed) {
        log.warning('[hot_patch_generator] try 的 catch 子句位于 catch-all '
            '之后（不可达），已跳过：${clause.toSource()}');
        continue;
      }
      final type = clause.exceptionType;
      var isCatchAll = type == null;
      var cond = 'true';
      if (type != null) {
        final test =
            typeTestJs(type.toSource(), exName, knownClasses: known);
        if (test == null) {
          log.warning('[hot_patch_generator] catch 的 on 类型 '
              '${type.toSource()} 在 JS 侧无法判别，已按 catch-all 翻译：'
              '${clause.toSource()}');
          isCatchAll = true;
        } else {
          cond = test;
        }
      }
      if (isCatchAll) closed = true;
      final name = clause.exceptionParameter?.name.lexeme;
      final stackName = clause.stackTraceParameter?.name.lexeme;
      final branchScope = (name == null && stackName == null)
          ? scope
          : scope.withParams([
              if (name != null) name,
              if (stackName != null) stackName,
            ]);
      var body = translateStmtList(
        clause.body.statements,
        branchScope,
        classes,
        renderer,
        depth: depth + 2,
        returnsWidget: returnsWidget,
      );
      if (stackName != null && stackName != exName) {
        body = '${ind}    const $stackName = $exName && $exName.stack;\n$body';
      }
      if (name != null && name != exName) {
        body = '${ind}    const $name = $exName;\n$body';
      }
      final head = isCatchAll && first
          ? null // 首个子句就是 catch-all：直接执行 body，无需 if/else 包装
          : (isCatchAll
              ? '${ind}  else {'
              : '${ind}  ${first ? 'if' : 'else if'} ($cond) {');
      if (head == null) {
        lines.add(body);
      } else {
        lines
          ..add(head)
          ..add(body)
          ..add('$ind  }');
      }
      first = false;
    }
    if (!closed) {
      lines
        ..add('${ind}  else {')
        ..add('${ind}    throw $exName;')
        ..add('$ind  }');
    }
    lines.add('$ind}');
    catchPart = lines.join('\n');
  }

  var finallyPart = '';
  if (finallyBlock != null) {
    final finBody = translateStmtList(
      finallyBlock.statements,
      scope,
      classes,
      renderer,
      depth: depth + 1,
      returnsWidget: returnsWidget,
    );
    finallyPart = ' finally {\n$finBody\n$ind}';
  }

  return '${ind}try {\n$bodyJs\n$ind}$catchPart$finallyPart';
}

/// switch 语句 → JS switch。仅支持常量 case（analyzer 把常量 case 也解析为
/// SwitchPatternCase(ConstantPattern)）与 default：
///   - Dart 无贯穿语义：非空 case 体若不以 return / break / continue / throw
///     收尾，自动补 `break;`（空 case 体是显式贯穿，JS 天然同形）；
///   - guard / 解构 / 关系 / 逻辑或等模式、带 label 的 case 暂不支持，
///     返回 null 整体丢弃（调用方出声告警），避免产出半翻译的 switch。
String? _switchStatementJs(
  SwitchStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  ExprRenderer? renderer,
  int depth,
  bool returnsWidget,
) {
  // 非常量模式 / 带 guard 的 case 无法用 JS `switch` 表达，走同一条模式 if 链；
  // 纯常量 switch 保持原有 JS switch 产物（老路径行为不变）。
  if (_switchStatementNeedsPatternPath(s)) {
    return _patternSwitchStatementJs(
        s, scope, classes, renderer, depth, returnsWidget);
  }
  final subj = exprToJs(s.expression, scope, classes);
  if (subj == null) return null;
  final ind = '  ' * depth;
  final caseInd = '  ' * (depth + 1);
  final lines = <String>['$ind' 'switch ($subj) {'];
  for (final member in s.members) {
    if (member.labels.isNotEmpty) return null; // 带标签的 break/continue 不支持
    String? label;
    if (member is SwitchDefault) {
      label = 'default:';
    } else if (member is SwitchPatternCase) {
      // Dart 3 解析形态：常量 case 也是 SwitchPatternCase(ConstantPattern)
      //（实测 analyzer 7 对 switch 语句不再产出旧 SwitchCase）。
      if (member.guardedPattern.whenClause != null) return null;
      final p = member.guardedPattern.pattern;
      if (p is WildcardPattern) {
        label = 'default:'; // `case _:` 等价 default
      } else if (p is ConstantPattern) {
        final v = exprToJs(p.expression, scope, classes);
        if (v == null) return null;
        label = 'case $v:';
      } else {
        return null; // 解构 / 关系 / 逻辑或等模式
      }
    } else if (member is SwitchCase) {
      // 旧解析形态兜底（常量 case 直接挂在 SwitchCase.expression 上）。
      final v = exprToJs(member.expression, scope, classes);
      if (v == null) return null;
      label = 'case $v:';
    } else {
      return null;
    }
    lines.add('$caseInd$label');
    for (final st in member.statements) {
      final js = translateStmtList([st], scope, classes, renderer,
          depth: depth + 2, returnsWidget: returnsWidget);
      if (js.isEmpty) return null; // 某条语句翻译失败 → 整个 switch 丢弃
      lines.add(js);
    }
    if (member.statements.isNotEmpty) {
      final last = member.statements.last;
      final terminated = last is ReturnStatement ||
          last is BreakStatement ||
          last is ContinueStatement ||
          (last is ExpressionStatement && last.expression is ThrowExpression);
      if (!terminated) lines.add('$caseInd' 'break;');
    }
  }
  lines.add('$ind}');
  return lines.join('\n');
}

/// switch 表达式（Dart 3）→ JS IIFE：
///   `switch (x) { 0 => '零', _ => '多' }` →
///   `(() => { switch (x) { case 0: return "零"; default: return "多"; } })()`
/// 仅支持常量模式与 `_`（guard / 解构 / 关系 / 逻辑或模式返回 null，调用方
/// 出声告警）。case 值走普通表达式翻译，不支持返回 widget 的 case（widget
/// 渲染路径只认 return 语句/表达式位置的构造调用）。
String? _switchExpressionJs(
  SwitchExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (_switchExpressionNeedsPatternPath(e)) {
    return _patternSwitchExpressionJs(e, scope, classes);
  }
  final subj = exprToJs(e.expression, scope, classes);
  if (subj == null) return null;
  final arms = <String>[];
  for (final c in e.cases) {
    if (c.guardedPattern.whenClause != null) return null;
    final p = c.guardedPattern.pattern;
    String? label;
    if (p is WildcardPattern) {
      label = 'default:';
    } else if (p is ConstantPattern) {
      final v = exprToJs(p.expression, scope, classes);
      if (v == null) return null;
      label = 'case $v:';
    } else {
      return null;
    }
    final v = rhsToJs(c.expression, scope, classes);
    if (v == null) return null;
    arms.add('    $label return $v;');
  }
  if (arms.isEmpty) return null;
  return '(() => { switch ($subj) {\n${arms.join('\n')}\n} })()';
}

/// switch 语句是否需要模式路径（带 guard / 非常量模式）。
bool _switchStatementNeedsPatternPath(SwitchStatement s) {
  for (final m in s.members) {
    if (m is SwitchPatternCase) {
      if (m.guardedPattern.whenClause != null) return true;
      final p = m.guardedPattern.pattern;
      if (p is! WildcardPattern && p is! ConstantPattern) return true;
    } else if (m is SwitchDefault || m is SwitchCase) {
      continue;
    } else {
      return true;
    }
  }
  return false;
}

bool _switchExpressionNeedsPatternPath(SwitchExpression e) {
  for (final c in e.cases) {
    if (c.guardedPattern.whenClause != null) return true;
    final p = c.guardedPattern.pattern;
    if (p is! WildcardPattern && p is! ConstantPattern) return true;
  }
  return false;
}

/// 模式 switch 语句 → **原生 JS `switch`**（`switch (true)` + case 条件 IIFE）。
///
/// JS 的 `case` 只能做常量比较，模式匹配 / `when` 守卫用条件表达：把每个 case
/// 的条件落成 `case (() => { <检查 + 绑定> })():`，仍保持原生 switch 的语义——
/// 条件按源码顺序求值、命中即进入对应 body、连续空 case 自然贯穿、
/// `default` 仅在无 case 命中时进入、body 里的 `break` / `continue` 原样有效。
///
/// ```js
/// {
///   const __v0 = <expr>;
///   let title;
///   switch (true) {
///     case (() => { …绑定…; return guard; })():
///       <body>
///       break;
///     default:
///       <body>
///   }
/// }
/// ```
String? _patternSwitchStatementJs(
  SwitchStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  ExprRenderer? renderer,
  int depth,
  bool returnsWidget,
) {
  final subj = exprToJs(s.expression, scope, classes);
  if (subj == null) return null;
  for (final m in s.members) {
    if (m.labels.isNotEmpty) return null;
  }
  final ind = '  ' * depth;
  final caseInd = '  ' * (depth + 1);
  final before = {...scope.localVars};
  // 先算每个成员的条件与绑定名（两遍）：绑定统一在外层 `let` 声明，case 条件
  // 的 IIFE 赋值、body 直接读取，因此第一遍只收集条件，第二遍翻译 body。
  final conds = <String?>[];
  final namesByMember = <List<String>>[];
  for (final member in s.members) {
    String? cond;
    var names = const <String>[];
    if (member is SwitchPatternCase) {
      final gp = member.guardedPattern;
      final p = _PatternPlan();
      final scopeBefore = {...scope.localVars};
      if (!_compilePatternWithGuard(
          gp.pattern, gp.whenClause?.expression, p, scope, classes)) {
        scope.localVars
          ..clear()
          ..addAll(scopeBefore);
        return null;
      }
      if (gp.whenClause == null) p.lines.add('return true;');
      scope.localVars
        ..clear()
        ..addAll(scopeBefore);
      cond = '(() => { ${p.lines.join(' ')} })()';
      names = p.names;
    } else if (member is SwitchCase) {
      final v = exprToJs(member.expression, scope, classes);
      if (v == null) return null;
      cond = '(() => { if (!(__v0 === $v)) return false; return true; })()';
    } else if (member is! SwitchDefault) {
      return null;
    }
    conds.add(cond);
    namesByMember.add(names);
  }
  final allNames = <String>{for (final n in namesByMember) ...n};
  final lines = <String>[
    '$ind{',
    '${ind}  const __v0 = $subj;',
    if (allNames.isNotEmpty) '${ind}  let ${allNames.join(', ')};',
    '${ind}  switch (true) {',
  ];
  for (var i = 0; i < s.members.length; i++) {
    final member = s.members[i];
    final cond = conds[i];
    lines.add('$caseInd${cond == null ? 'default:' : 'case $cond:'}');
    // 空 case 不产生语句：JS switch 会贯穿到下一个 case 的 body（与 Dart 多个
    // case 共享 body 的写法一致）。
    if (member.statements.isEmpty) continue;
    scope.localVars.addAll(namesByMember[i]);
    for (final st in member.statements) {
      final js = translateStmtList([st], scope, classes, renderer,
          depth: depth + 2, returnsWidget: returnsWidget);
      if (js.isEmpty) {
        scope.localVars
          ..clear()
          ..addAll(before);
        return null;
      }
      lines.add(js);
    }
    scope.localVars
      ..clear()
      ..addAll(before);
    final last = member.statements.last;
    final terminated = last is ReturnStatement ||
        last is BreakStatement ||
        last is ContinueStatement ||
        (last is ExpressionStatement && last.expression is ThrowExpression);
    if (!terminated) lines.add('$caseInd' 'break;');
  }
  lines.add('${ind}  }');
  lines.add('$ind}');
  return lines.join('\n');
}

/// 模式 switch 表达式 → IIFE 内的原生 `switch (true)`：
///
/// ```js
/// (() => {
///   const __v0 = <expr>;
///   let title;
///   switch (true) {
///     case (() => { …; return guard; })(): return <值>;
///     default: throw new Error("switch 表达式未匹配：…");
///   }
/// })()
/// ```
/// Dart 的 switch 表达式要求穷尽，`default` 抛错只作兜底（合法源码不会走到）。
String? _patternSwitchExpressionJs(
  SwitchExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final subj = exprToJs(e.expression, scope, classes);
  if (subj == null) return null;
  final conds = <String>[];
  final namesByArm = <List<String>>[];
  final values = <String>[];
  for (final c in e.cases) {
    final gp = c.guardedPattern;
    final p = _PatternPlan();
    final scopeBefore = {...scope.localVars};
    if (!_compilePatternWithGuard(
        gp.pattern, gp.whenClause?.expression, p, scope, classes)) {
      scope.localVars
        ..clear()
        ..addAll(scopeBefore);
      return null;
    }
    if (gp.whenClause == null) p.lines.add('return true;');
    scope.localVars.addAll(p.names);
    final v = rhsToJs(c.expression, scope, classes);
    scope.localVars
      ..clear()
      ..addAll(scopeBefore);
    if (v == null) return null;
    conds.add('(() => { ${p.lines.join(' ')} })()');
    namesByArm.add(p.names);
    values.add(v);
  }
  final allNames = <String>{for (final n in namesByArm) ...n};
  final b = StringBuffer('(() => {\n  const __v0 = $subj;\n');
  if (allNames.isNotEmpty) b.write('  let ${allNames.join(', ')};\n');
  b.write('  switch (true) {\n');
  for (var i = 0; i < e.cases.length; i++) {
    b.write('    case ${conds[i]}: return ${values[i]};\n');
  }
  b.write('    default: throw new Error('
      '${jsString('switch 表达式未匹配：${e.toSource()}')});\n');
  b.write('  }\n})()');
  return b.toString();
}

/// 一条表达式语句 → JS：`setState(...)` 展开为 `this.setState(() => {...})`，
/// 其余走 [exprStmtToJs]（赋值 / 自增 / `_model.inc()` 对象方法调用等）。
String? _bodyExprStmtJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is MethodInvocation &&
      e.methodName.name == 'setState' &&
      e.argumentList.arguments.length == 1) {
    final fn = e.argumentList.arguments.first;
    if (fn is FunctionExpression) return _setStateJs(fn, scope, classes);
    return null;
  }
  return exprStmtToJs(e, scope, classes);
}

/// `setState(() => _x++)` → `this.setState(() => { this._x += 1; });`
/// （回调体逐语句翻译，与 Dart 原封同构）。
///
/// 回调**必须是箭头函数**（与 [closureToJs] 的口径一致）：`this` 词法绑定到
/// 定义该回调的组件方法，也就是组件实例，正是 Dart 闭包捕获 `this` 的语义。
/// 若产出 `function(){}`，回调里的 `this` 就取决于调用方是否 `.call(this)`——
/// 运行时 `setState` 恰好会 `.call(this)` 兜住，但这是一层**隐式约定**：任何
/// 不走该入口的调用路径（被抽成实例方法后由宿主按别的形式调用等）都会让回调
/// 里的 `this._x` 变成 undefined，表现为「状态静默不更新」。
String _setStateJs(
  FunctionExpression fn,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final body = fn.body;
  String inner = '';
  if (body is ExpressionFunctionBody) {
    inner = exprStmtToJs(body.expression, scope, classes) ?? '';
  } else if (body is BlockFunctionBody) {
    inner = translateStmtList(body.block.statements, scope, classes, null);
  }
  // 回调体与其它方法体同一口径：多行可读，缩进由写出前的统一重排
  // （`canonicalizeJsIndent`）按括号嵌套决定。这里**不再把换行折成单行**：
  // 那会让同一份 AST 在 `setState` 里和别处产出不同形态，绕过统一格式化。
  return inner.isEmpty
      ? 'this.setState(() => {});'
      : 'this.setState(() => {\n$inner\n});';
}

/// `@HostInjected` 方法的 JS 方法体：Dart 实现留在宿主，这里只把实参打包成
/// 宿主通道载荷（`_app_host_.invoke(通道, ...)`）。方法签名、类结构与其它成员
/// 照常翻译，调用点与 Dart 一比一（不再整体改写为 `_app_host_.invoke`）。
///
/// 载荷形态与调用点的通用约定一致（见 [methodCallExprJs]：位置实参在前、具名
/// 实参合并成**尾参对象**），因此直接从 `arguments` 重建：
///   - 纯位置：`arguments` 原样——调用点传几个就是几个，可选位置参数缺省时不会
///     补 `undefined`，宿主侧 `Function.apply` 照常走 Dart 默认值；
///   - 纯具名：调用点把具名实参压成**第一个实参**，整个对象就是具名实参表；
///   - 混合：前 [ClassMethod.positionalParamCount] 个实参是位置实参，尾参对象
///     的键是具名实参（与 [hostArgsJs] 的 `@args` + 具名键同一形态）。
String hostMethodBodyJs(ClassMethod m, {int depth = 2}) {
  final ind = '  ' * depth;
  final channel = jsString(m.hostChannel!);
  if (!m.hasNamedParams) {
    return '$ind'
        'return _app_host_.invoke($channel, '
        'Array.prototype.slice.call(arguments));';
  }
  final positionalCount = m.positionalParamCount;
  if (positionalCount == 0) {
    return '$ind'
        'return _app_host_.invoke($channel, '
        'arguments.length ? arguments[0] : {});';
  }
  return '$ind'
      'const __positional = '
      'Array.prototype.slice.call(arguments, 0, $positionalCount);\n'
      '$ind'
      'const __named = arguments.length > $positionalCount '
      '? arguments[$positionalCount] : {};\n'
      '$ind'
      'return _app_host_.invoke($channel, Object.assign('
      '{ ${jsString(hostPositionalKey)}: __positional }, __named));';
}

/// 翻译一个类的方法体 → JS。**组件与普通类共用这一条**：字段表 = 类自身实例
/// 字段，返回 widget 的表达式走 widget 层渲染（与 build 无差别）。
///
/// [ClassMethod.nativeChannel] 非空（如 SnackBar → `nativeToast`）时整体译为
/// 宿主通道调用，不再走普通语句翻译。
String translateClassMethodBody(
  ClassInfo info,
  ClassMethod m,
  Map<String, ClassInfo> classes, {
  Set<String> hostFunctions = const {},
  ExprRenderer? renderer,
  Set<String> globalConsts = const {},
  int depth = 2,
  Map<String, Map<String, String>> extensionOperators = const {},
  Map<String, ExtensionScope> extensionNames = const {},
}) {
  final ind = '  ' * depth;
  final channel = m.nativeChannel;
  if (channel != null) {
    return '$ind'
        '_app_host_.invoke(${jsString(channel)}, '
        '{ message: ${m.nativeMessage ?? '""'} });';
  }
  // 抽象成员（无方法体）→ 抛错兜底：具体子类未覆盖而被调用时立即暴露，
  // 而不是静默返回 undefined 继续执行。非抽象类的无体方法（如宿主 external）
  // 不受影响，仍走原路径。
  if (info.isAbstract && (m.body == null || m.body is EmptyFunctionBody)) {
    return '$ind'
        'throw new Error("Unimplemented: ${info.name}.${m.name}");';
  }
  // 静态成员（Dart 的 static 与实例成员同一名字空间，调用点看不出差别）：
  // 裸引用落成 `<类名>.<name>`；static 方法体里实例成员不参与解析（Dart 禁）。
  final staticFieldNames = {for (final f in info.staticFields) f.name};
  final staticMethodNames = {
    for (final sm in info.methods)
      if (sm.isStatic) sm.name,
  };
  final instanceMethods = {
    ...objectMethodNamesOf(info, classes),
    if (sdkBaseName(info) != null) 'notifyListeners',
  };
  // getter 视图与 instanceMethods 同源：值位置要区分「读值」与「方法 tear-off」。
  final instanceGetters = m.isStatic
      ? const <String>{}
      : objectGetterNamesOf(info, classes);
  // 方法泛型的类型实参与具名实参共用**同一个尾参对象**（调用点合并下发）：
  // 有具名形参时是 `__o`，否则保持既有的 `__ta`。
  final tailParam = tailParamNameOf(m) ?? '__ta';
  final scope = FieldScope(
    // 字段与方法都取**继承链视图**：子类方法里 `this.name` 指向父类字段、
    // 裸调用父类方法同样要解析为 `this.foo()`。
    instanceFields: m.isStatic
        ? const {}
        : {for (final f in objectFieldsOf(info, classes)) f.name},
    params: m.params.toSet(),
    // 形参 / 字段的声明类型：供运算符重载的调用点判定（JS 无运算符重载）。
    paramTypes: m.paramTypes,
    fieldTypes: m.isStatic
        ? const {}
        : {for (final f in objectFieldsOf(info, classes)) f.name: f.typeName},
    methods: m.isStatic ? const {} : instanceMethods,
    getterNames: instanceGetters,
    className: info.name,
    staticFields: staticFieldNames,
    staticMethods: staticMethodNames,
    // 类型参数 → 运行时类型名：
    //   - 类泛型：实例上由构造保存的 `typeArguments`（`this.__ta["T"]`），
    //     静态方法在 Dart 里本就不能引用类类型参数，故不进表；
    //   - 方法泛型：调用点下发的尾参对象（`__ta.typeArguments["E"]`），方法定义侧
    //     已追加隐藏形参 `__ta`；未传时读 undefined（不抛错）。
    typeParams: {
      if (!m.isStatic)
        for (final tp in info.typeParams) tp: 'this.__ta[${jsString(tp)}]',
      for (final tp in m.typeParams)
        tp: '((($tailParam && $tailParam.typeArguments) || {})[${jsString(tp)}])',
    },
    hostFunctions: hostFunctions,
    globalConsts: globalConsts,
    // 原生继承（SDK 基类或项目类）→ `super.foo()` 在 JS 里合法，原样发射。
    // 判据与渲染层同一个（jsBaseClassOf）：基类在 JS 侧无实现时，类声明里不会
    // 写 extends，此时发射 super 调用是语法错误。
    // Widget 空基类（Component / StatelessWidget / StatefulWidget）上的生命周期
    // 与 build 都有同名空实现，故 SDK 侧的 `super.initState()` / `super.build()`
    // 可以直接落到基类，不需要在翻译层做特殊处理。
    hasJsBase: jsBaseClassOf(info, classes) != null,
    extensionOperators: extensionOperators,
    extensionNames: extensionNames,
  );
  // 形参前导：可选位置形参补默认值、具名形参从尾参对象 `__o` 解构。与闭包 /
  // 局部函数同一实现，避免三处默认值口径走样。
  final paramPlan =
      _functionParamPlan(m.parameters, (e) => rhsToJs(e, scope, classes));
  // 方法形参同步登记进 widget 层（方法体期间），使返回的 widget 树里
  // `Text(title)` 这类形参引用可解析；翻译结束即恢复，不污染同类其它方法。
  // 组件语境（构造走属性管线 / 静态类引用解析）由调用方在**整类方法翻译**上
  // 统一开启（见 analyze_dart_class），这里不再逐方法判断。
  String run() {
    final body = translateMethodBody(
      m.body,
      scope,
      classes,
      renderer: renderer,
      returnExpressionBody: !m.isVoid,
      returnsWidget: m.returnsWidget,
      depth: depth,
    );
    if (paramPlan.prologue.isEmpty) return body;
    final pro =
        paramPlan.prologue.map((l) => '$ind$l').join('\n');
    return '$pro\n$body';
  }
  if (renderer == null || m.params.isEmpty) return run();
  return renderer.withMethodParams(m.params, run);
}

/// 把一个 Widget 构造表达式（如 `Container(...)`）通过 [ExprRenderer]
/// （element2js 层的 ElementTranslateContext）翻译成 JS 构造调用字符串。
/// 失败返回 null（回退到普通表达式翻译），并出声告警（不静默丢代码）。
///
/// [depth]：该表达式所在语句的缩进深度，widget 树的子节点按此对齐缩进。
String? _widgetExprToJs(ExprRenderer? renderer, Expression e, int depth) {
  if (renderer == null) return null;
  try {
    // translate(Expression) → JSON Map / String；renderJs(json, depth) → JS
    return renderer.renderJs(renderer.translate(e), depth);
  } catch (err) {
    log.warning('[hot_patch_generator] widget 表达式无法翻译，已在 JS 产物中'
        '丢弃：${e.toSource()}（$err）');
    return null;
  }
}
