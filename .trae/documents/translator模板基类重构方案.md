# translator 模板基类重构方案

## Context

`packages/hot_patch_generator/lib/src/translator/builtin_translators.dart`（约 135KB、87 个 translator 类）里绝大多数 `toJson` 是同一种样板：逐个 `ctx.namedArg(node.args, name)` → 转换 → `if (v != null) props[k] = v`。`TextTranslator` 甚至已经写了私有的 `_numProp`/`_enumProp`（L206-222），但只服务它自己，其余各类各自手写同样逻辑。

用户主张（本次设计的准绳）：

1. **不要白名单**：模板不应要求子类声明「支持哪些属性」，而是「从 `node.args` 里找到几个就翻几个」——`js_widget_registry.dart` 的 renderer 都是逐具名键取值（`c.num_('width')` / `c.map('decoration')` / `on('onPressed')`），**多余的 props 键会被自动忽略**，所以生成器侧不需要限制键集。
2. **统一空值处理**：封装一个「去掉 map 中空值键」的方法即可，不必每类自己判空。
3. **迁移范围**：87 个 translator 先全部继承模板，再逐个回退真正需要独立实现的。
4. **构建期必需校验**：放弃（现有 `SafeArea`/`Opacity`/`ConstrainedBox`/`AspectRatio` 等「缺参数抛 `FormatException`」不再保留），交给运行时。
5. **style_translators 分两批**：本批只做 translator 模板；`textStyleToJson`/`boxDecorationToJson` 等的「按类型判断 + 直通」改造留作下一批。

## 已验证的关键前提（决定设计可行）

| 事实 | 位置 | 结论 |
| --- | --- | --- |
| 空 props 渲染成 `{}`、空 children 省略第三参 | `widget2js.dart` L613 / L620 | 模板恒带 `'props': props` + `'children': [...]` 不产生产物差异 |
| `jsLiteral` 按 `entries` 顺序输出；Dart `null` → 裸 `null` | `widget2js.dart` L1091-1118 | props 键顺序须复刻；**空值必须剔除**，否则产物出现 `null` 值 |
| `usesJsClass` 用 `props.containsKey('builder')` 判定结点形态 | `widget2js.dart` L157-161 | 「值为 null 的 builder 键」会让结点从 `__h(ListView,…)`（类引用）变成 `__h('ListView',…)` → 空值必须剔除而非保留 |
| 运行时逐键取值，多余键不读取 | `js_widget_registry.dart` L55-128 / L206-289 | 「不限制键集、多余键运行时忽略」成立 |
| 事件只认 `{'__fn': id}` 句柄，裸函数被静默丢弃 | `js_widget_registry.dart` L65-100 + `js_ui_widget.dart` L194-208 | **事件参数不能走默认直通**，必须走事件绑定 |
| `ctx.jsDataExpr(NullLiteral)` 返回字符串 `'null'` | `js_translator.dart`（`TextTranslator` L194-197 已在手工防） | 过滤时 `null` 与 `'null'` 都要剔除 |

## 设计

### 1. 空值过滤 helper

```dart
/// 去掉空值键（保序）：Dart null 与字符串 'null' 都算空。
Map<String, dynamic> nonNull(Map<String, Object?> raw) => {
      for (final e in raw.entries)
        if (e.value != null && e.value != 'null') e.key: e.value,
    };
```

它是「兜底闸门」：各转换分支本就应返回 null 表示「不可翻译」，模板最后统一过一次 `nonNull` 收口。**必须做**，否则触发上面两条产物差异。

### 2. 模板基类（新建 `lib/src/translator/auto_props_translator.dart`）

核心是「默认直通 + 按值形态分派」，不引入逐类属性白名单：

```dart
abstract class AutoPropsTranslator extends WidgetTranslator {
  const AutoPropsTranslator();

  /// 少数需要按【参数名】识别的语义（事件、子结点、element prop）。
  /// 未列出的参数一律走 [_autoValue] 按值形态判断。
  Map<String, ArgHandler> get namedHandlers => const {};

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final children = <Object?>[];
    for (final a in node.args.whereType<NamedExpression>()) {
      final name = a.name.label.name;
      // 1) 参数名语义表（事件 on* / child / children / appBar / title…）
      // 2) 其余 → _autoValue(a.expression)
      // 结果进 props 或 children；空值丢弃
    }
    return {'type': ctx.jsString(type), 'props': nonNull(props), 'children': children};
  }

  /// 按【值形态】分派——这是「从不限制到能翻就翻」的关键：
  ///   构造/静态工厂（EdgeInsets.all / BoxDecoration / TextStyle / BorderRadius.circular /
  ///     LinearGradient / BoxConstraints）→ 对应 xxxToJson（按构造名查表）
  ///   常量引用（Colors.red / TextOverflow.ellipsis / MainAxisAlignment.center / FontWeight.bold）
  ///     → 颜色或枚举转换（按 owner 名查表）
  ///   字面量（字符串/数字/布尔）→ jsLiteral
  ///   闭包 / 方法引用（builder 回调）→ 保持现有闭包抽取（此类留在覆写里）
  ///   其余 → ctx.jsDataExpr 直通（表达式）
  Object? _autoValue(Expression? e);
}
```

要点：

- **不限制键集**：所有具名实参都会尝试翻译，翻不出来的丢弃（`_autoValue` 返回 null → 过滤掉）。对应你说的「不识别运行时会自动抛弃」。
- **`namedHandlers` 只列必须按名识别的少数语义**：事件（`on*` 前缀 + 方法引用/闭包值）、子结点（`child`/`children`/`slivers`/`tabs`）、element prop（`appBar`/`body`/`leading`/`trailing`/`title`/`icon`…）。这些**不能**靠值形态推断（`title: Text(...)` 与 `title: 'hello'` 分属结点/字符串两种语义）。
- **样式/枚举按值形态分派**（正是你说的「颜色等比较特殊的判断一下类型」）：`Colors.red`、`EdgeInsets.all(8)`、`BoxDecoration(...)`、`TextOverflow.ellipsis` 都能从 AST 形态识别，无需逐类声明。分派表复用已有函数：`colorToJson` / `edgeInsetsToJson` / `alignmentToJson` / `boxDecorationToJson` / `boxConstraintsToJson` / `textStyleToJson` / `enumName`（`style_translators.dart`、`js_translator.dart`）。
- **覆写钩子**：`jsonTypes` / `packageName` / `namedHandlers` / `_autoValue` 的兜底分支；真正特殊的（闭包 builder、连续性语义如 provider）仍写完整 `toJson`。
- 不再有必需校验（用户决定），`child` 缺失就是 children 为空。

### 3. 迁移策略（全部先继承再回退）

| 批次 | 内容 |
| --- | --- |
| P0 | 落 `nonNull` + `AutoPropsTranslator`，不挂任何子类 → 先证明基建本身零影响 |
| P1 | 87 个 translator 全部改为继承模板（多数只留 `String get type => 'X';`，`_ButtonTranslator` 保留 `jsonTypes` 覆写） |
| P2 | 构建 → 产出产物 → 审计「行为回归」清单 |
| P3 | 逐个回退：把 `namedHandlers` 覆盖不到的类恢复成手写 `toJson`，直到关键行为与改造前一致 |

高危回退候选（预计必须保留手写或大段覆写）：`Text`(164)、`_ButtonTranslator` 及 4 个按钮(227-313)、`ListView`(894)、`ReorderableListView`(948)、`GridView`(984)、`SliverList`(1273)、`SliverGrid`(1314)、`SliverFixedExtentList`(1475)、`SliverFillViewport`(1505)、`NotificationListener`(1655)、`InkWell`(1901)、`GestureDetector`(1938)、`Switch`(1969)、`Checkbox`(2000)、`Slider`(2028)、`ListenableBuilder`(2072)、`ValueListenableBuilder`(2132)、`Builder`(2192)、`ChangeNotifierProvider`(2275)、`Consumer`(2390)、`MultiProvider`(2451)、`TextField`(2800)、`IconButton`(2863)、`FloatingActionButton`(2893)、`BottomNavigationBar`(2926)、`Radio`(2981)、`DropdownButton`(3008)、`TabBar`(3103)、`PageView`(3216)、`EasyRefresh`(3315)、`Positioned`(747)（`.fill` 分支补四边 `'0'`，键集与普通分支不同）。

已确认的陷阱（P2/P3 审计重点）：

1. `flex`（`_FlexTranslator` L668-669）只认 `IntegerLiteral`，用通用数字转换会让 `flex: 2.0` 从「丢弃」变「保留」。
2. `IndexedStack`(L240 运行时) 的 `index` 是**状态字段表达式**（`this._index`），必须走表达式直通，不能被当字面量。
3. `Positioned` 两分支键集不同 → 必须回退手写。
4. 同语义多入口：`Chip.backgroundColor` 用 `translateColor`、`ClipRRect.borderRadius` 用 `ctx.borderRadiusExpr`、`Container.decoration` 用 `boxDecorationToJson` —— 按值形态分派后要逐类核对运行时侧的期望格式。
5. 枚举产出格式（`"ellipsis"` vs `"TextOverflow.ellipsis"`）须与运行时 `xxxFromJson` 对齐。
6. 子结点参数名逐类不同：`children` / `slivers` / `tabs`；`child` vs `sliver`；是否允许位置实参（`Container`/`DecoratedBox`/`CircleAvatar` 取 `nonNamedArg`，`SizedBox`/`Material` 不取）。

## 关键文件

- 新建：`packages/hot_patch_generator/lib/src/translator/auto_props_translator.dart`（模板基类 + `nonNull`）
- 主要改动：`packages/hot_patch_generator/lib/src/translator/builtin_translators.dart`（87 个类逐个改继承 / 回退）
- 复用不改：`widget2js.dart`（`WidgetTranslateContext` 的 `namedArg`/`jsDataExpr`/`translate`/`translateElement`）、`js_translator.dart`（`numLiteralJs`/`boolLiteralJs`/`enumName`）、`style_translators.dart`（各 `xxxToJson`）
- 验证涉及：`example/`（`example/patch/**.js` 产物）、`example/lib/components/widget_details.dart`（补覆盖缺口的临时样例）

## 验证

1. **基线冻结**：`git status --porcelain example/patch` 应为空（产物已被跟踪）。
2. **重生成**：`cd example && dart run build_runner build --delete-conflicting-outputs`。
3. **产物不变量校验**（临时脚本，放 `/tmp`，不进仓库）——比「逐字节相同」更贴合本次「允许多余键」的目标：
   - 改造前每个结点的 props 键集合必须是改造后的**子集**（不允许少键，少了就是语义丢失）；
   - 产物中不得出现值为裸 `null` 的 props 键；
   - `usesJsClass` 相关类型（ListView/GridView/SliverList/SliverGrid/SliverFixedExtentList/SliverFillViewport）的结点形态（`__h(ListView,…)` vs `__h('ListView',…)`）与改造前一致；
   - 事件键的值形态仍是句柄（含 `__fn`）而非裸函数。
4. **静态检查**：`dart analyze`（生成器包）无新增告警。
5. **人工验收**（由你执行）：`bash start_patch_server.sh` + `cd example && flutter run`，对比页逐个验证渲染、样式与点击交互。
6. **覆盖缺口**：`IndexedStack` / `SliverOffstage` / `SliverVisibility` / `SliverIgnorePointer` 在 example 中零出现 —— 临时在 `widget_details.dart` 加样例、验证后回退。

## 风险与回退

| 风险 | 表现 | 处置 |
| --- | --- | --- |
| 事件失效 | 点击无反应（句柄变裸函数） | 事件统一走 `namedHandlers` 的 `on*` 分支；审计产物事件键形态 |
| 子结点丢失 | 子组件不渲染 | `child`/`children`/element prop 必须在 `namedHandlers` 覆盖；审计 children 项数 |
| 结点形态变化 | builder 键为 null → 类引用变字符串 | `nonNull` 强制生效；审计 `__h(` 首参形态 |
| 样式语义错 | 颜色/间距/装饰渲染异常 | 按值形态分派后逐类核对运行时 `xxxFromJson` 期望格式 |
| 中间态回归 | P1 后若干页面异常 | P1 后立即做 P2 审计与 P3 回退，不留长期回归；每批单独提交，可整批回退 |

## 本次不做

- `style_translators.dart` 的「类型判断 + 直通」改造（`textStyleToJson` / `boxDecorationToJson` / `shapeToJson` 等）——下一批单独进行，届时可复用本批的 `nonNull` 与值形态分派器。
