# 去除 WidgetTranslator：统一翻译重构方案

## Context

**需求**（用户原话）：「核心需求是想去除 WidgetTranslator，统一翻译设计。这样就不需要开发者支持其他组件时还要实现 WidgetTranslator。只不过在转换时判断类型来处理，比如如果是枚举、常量。」以及「去除特殊处理吧，比如 TextButton 和 IconButton 统一叫 'Button' 这个不需要。该怎么翻就怎么翻译？有问题让运行时改。」

即：删掉「每种 widget 一个 `WidgetTranslator` 子类 + `WidgetTranslatorRegistry` 注册表」这套架构（`builtin_translators.dart` 135KB / 92 个类），生成器只保留**一条统一翻译路径**——任意 widget 构造 → `{type: 构造名, props: 逐具名实参按值形态翻译, children: 子结点}`，翻译时判断的是**值的类型/形态**（枚举、常量、样式构造、闭包、字面量、表达式），而不是 widget 类型。开发者接入新组件零实现；需要适配的地方挪到运行时侧。

**动机证据**：现有 92 个类里绝大多数是同一种样板（逐 `ctx.namedArg` → 转换 → `if (v != null) props[k] = v`）；`TextTranslator` 甚至已私有化了 `_numProp`/`_enumProp`，其余类各自手写。

**已验证的中间态风险（决定策略）**：把 50 个类改成「自动直通模板」后，产物已出现**静默丢键**——`"padding"` 87→15、`"margin"` 16→0、`"physics"` 5→2。根因：`edgeInsetsToJson`(style_translators.dart:387) 等转换函数内部只认**静态工厂形态**（`EdgeInsets.all(8)`），不认 `const EdgeInsets.all(8)` 的实例创建形态；`NeverScrollableScrollPhysics()` 这类 ScrollPhysics **子类构造**也没进表。所以必须先做全值形态分派表并以 HEAD 产物作 golden 基线，再分批删类。

## 目标架构

**删除**
- `widget2js.dart`：`WidgetTranslator`(L1194-1212)、`WidgetTranslatorRegistry`(L1220-1255)、`UnregisteredWidgetTranslator`(L1258-1348)——最后者**并入统一函数**（它本来就是「保留真实类型名 + 按值形态翻译实参」的实现，是统一函数的最佳蓝本）。
- `builtin_translators.dart`：`registerBuiltinTranslators`(L18-123) 与全部 92 个类。
- `auto_props_translator.dart`（本次中间态产物，作蓝本用后删除）。

**新增**
- `translator/widget_json.dart`：统一入口 `Map<String, dynamic> widgetToJson(WidgetNode node, WidgetTranslateContext ctx)`。
- `translator/value_forms.dart`：`Object? autoValue(Expression e, WidgetTranslateContext ctx)` + 构造/常量分派表 + 闭包抽取（把 `builtin_translators.dart` L793-923 的 `_extractBuilderMethod` / `_sliverBuilderDelegateProps` / `_builderFactoryProps` 及 `_ctorCall`(L769)、`_gridNumericProps`(L929) 平移过来）。
- `builders/ui_widget/widget_packages.dart`：`widgetPackageOf(type)`（类型→package 静态表）、`hasJsClass(type)`、`isDelegateForm(type)`——数据源就是 `js_widget_defs.dart` L25-53 已有的 `builderFormTypes` / `logicWidgetTypes` / `jsClassWidgetTypes`（**这些集合必须保留**：它是「哪些类型在 JS 侧有类、属于哪个 package」的登记，不是翻译策略）。

**保留不动**：`WidgetNode`(L32)、`WidgetTranslateContext`（仅去掉 `registry` 字段与 lookup 分支）、渲染层 `_renderCall`(L599-627) / `jsLiteral`(L1091-1118) / `_applyKeyProp`(L269-291)、`translateElement`(L296)、`SingletonResolver`、`js_widget_defs.dart` 的集合。

## 统一翻译函数的规则（全局唯一约定，非 per-widget）

| 情形 | 处理 |
| --- | --- |
| `type` | **构造名原样**（不再把 4 种按钮归一成 `'Button'`） |
| 具名 `child:` | `children[0]`（运行时统一用 `c.child()` 读） |
| 具名 `children:`/`slivers:`/`tabs:`/`items:` | 展开进 `children` |
| 其余具名实参 | 进 `props[参数名]`；值为元素描述时运行时用 `propChild(名字)` 通用读取 |
| 位置实参 | `props['$pos']`（JS 数组），运行时按位取 |
| 事件（`on*`） | `props[参数名]`（**不再改名 `'event'`**），值走 `ctx.eventHandle`；`onPressed: null` 仍是「键缺省 = 禁用」 |
| `key:` | 仍由 `_applyKeyProp` 统一注入 `props.key` / `json.key` |
| 结点形态 | `usesJsClass` 判据保留，数据源换成 `hasJsClass(type)` / `isDelegateForm(type)` / `props.containsKey('builder')` |

## `autoValue` 值形态分派（顺序即优先级）

1. `NullLiteral` → 丢键；
2. 字面量 → `jsDataExpr`；
3. **构造 / 静态工厂**（`ctx.ctorOf` 归一，必须**同时覆盖** `const X(...)` 的 `InstanceCreationExpression` 与 `X.y(...)` 的 `MethodInvocation`）→ 样式转换表：`textStyleToJson`(20) / `buttonStyleToJson`(84) / `edgeInsetsToJson`(387) / `borderRadiusToJson`(520) / `boxDecorationToJson`(583) / `borderToJson`(624) / `borderSideToJson`(346) / `boxShadowToJson`(677) / `gradientToJson`(717) / `decorationImageToJson`(769) / `boxConstraintsToJson`(794) / `shapeToJson`(831) / `textScalerToJson`(369) / `imageSourceToJson`(962) / `scrollPhysicsToJson`(943)（含 `NeverScrollableScrollPhysics` 等子类构造）/ `textInputTypeToJson`(927)；
4. **常量引用**（`Owner.name`）→ 颜色 / 图标 / 枚举表（现有表基础上补 `ScrollPhysics.*`、`EdgeInsets.zero`、`BorderRadius.zero`、`SystemUiOverlayStyle`、`InputDecoration`、`BoxConstraints.*` 等）；
5. **闭包 / tear-off** → 先 `ctx.translate(闭包体)`：得到元素 → 抽 `$prefix$idx` 组件方法 + `builder`/`separatorBuilder`/`itemCount`/`childCount` 键；得到纯值（`create: (_) => MyModel()`）→ 取 `functionInner` 的值内联；
6. `ListLiteral` → 逐项 `translateElement`（元素列表）或数据列表；
7. 元素构造 → `ctx.translate`；
8. 兜底 `jsDataExpr`，失败**出声**并丢弃（不允许静默）。

`renderJs` 侧简化为：`hasJsClass(type)` → `__h(Class, …)` 并记 package；否则 `__h("type", …)`。

## 运行时适配清单（`packages/hot_patch/lib/src/js_ui/js_widget_registry.dart`）

- 删 `Button`(L477-488)，拆成 4 个 renderer（`ElevatedButton` / `TextButton` / `FilledButton` / `OutlinedButton`），各自读 `c.on('onPressed')` + `c.childOrEmpty`（文案由子结点 Text 提供）。
- `InkWell`(L493) / `GestureDetector`(L506)：`c.on('event')` → `c.on('onTap')`。
- `Switch`(L515) / `Checkbox`(L526) / `Slider`(L540) / `Radio`(L698) / `DropdownButton`(L717) / `BottomNavigationBar`(L678)：事件键改真实参数名。
- `ClipRRect`(L329) / `ClipOval`(L334) / `Material`(L340) / `Transform`(L350) / `FloatingActionButton`(L660) / `Scaffold`(L549)：`propChild('child')` → `c.child()`。
- `Chip.label`(L426) / `ListTile.title·subtitle`(L445) / `BottomNavigationBarItem.label`(L690) / `DropdownMenuItem`(L725)：由「字符串」改「元素结点」。
- 位置实参：`Text` / `Image` 等按 `props['$pos']` 取。
- `capabilities/` 下 `text_editing_controller_bridge.dart`(L49-74)、`tab_bridge.dart`(L110-160)、`scroll_controller_bridge.dart`(L111-130) 按新键名核对。

## 迁移批次（每批可验证）

| 批 | 内容 |
| --- | --- |
| 批 0 | 回退定基线：`git checkout -- packages/hot_patch_generator/lib/src/translator/builtin_translators.dart example/patch`；保留 `auto_props_translator.dart` 作蓝本。HEAD 的 `example/patch` 即 golden 基线。 |
| 批 1 | 新增 `value_forms.dart` + **全值分派表**（先不接入）。针对 `const EdgeInsets.all(8)` / `EdgeInsets.all(8)` / `NeverScrollableScrollPhysics()` / `EdgeInsets.zero` 等形态写校验。 |
| 批 2 | 新增 `widget_json.dart` 统一入口；`_translateExpr` 切到它；删 `lookup`/`fallback` 分支与 `renderJs` 的 `lookupJson`；删继承 `AutoPropsTranslator` 的 50 个类（它们已被批 0 回退，此步直接删原类）。 |
| 批 3 | 删余下类 + `WidgetTranslator` / `Registry` / `Unregistered` / `registerBuiltinTranslators`；`widget_module_builder.dart` 的 `registeredWidgetPackages()`(L16-28) 换数据源（`widget_packages.dart`）。 |
| 批 4 | 运行时适配（上一节清单），与生成器同批提交，保证两侧一致可运行。 |
| 批 5 | 重跑产物 + golden 键集对比 + `dart analyze` + 人工验收。 |
| 批 6 | 文档更新（三个包 README、`docs/使用手册.md`、`docs/项目架构文档.md`、根 README——现在描述的「实现并注册 WidgetTranslator」扩展机制要改写为统一翻译说明）+ 发布新版本（`hot_patch_generator` / `hot_patch`，annotations 视需要）。 |

## 验证

1. **键集 golden 对比**（临时脚本，放 `/tmp`）：对每个产物文件统计关键 props 键出现次数，要求**新产物不少于基线**（允许增加、不允许减少），重点盯 `padding` / `margin` / `physics` / `alignment` / `decoration` / `style` / `color` / `event` / `child` / `label`。
2. **结构不变量**：无值为裸 `null` 的键；`__h(Class,…)` / `__h("Type",…)` 形态与基线一致；事件句柄数量不退；`builder`/`itemCount`/`separatorBuilder` 抽取仍在（`widget_details.js` 的 `_listViewBuilder0/1`、`_gridViewBuilder0`）；`provider.js` 的 `model`/`create`/`notifier` 接线仍在。
3. `dart analyze` 两个包 0 error；`cd example && dart run build_runner build --delete-conflicting-outputs` 成功。
4. **人工验收**（由你执行）：`bash start_patch_server.sh` + `cd example && flutter run`，逐页验证四类按钮、InkWell 点击、Switch/Checkbox/Slider 双向、TextField 受控、ListView.builder/.separated、GridView、SliverList delegate、provider 局部刷新、Chip/ListTile 文案、key 复用重排。

## 风险与处置

| 风险 | 处置 |
| --- | --- |
| 值分派表不全 → **静默丢键**（已发生） | 全表覆盖 + 兜底出声 + 键集 golden 门禁；批 1 先单独校验 |
| child/children 约定漏改 renderer → 空白/断言 | 按运行时清单逐条改，两侧同批提交 |
| 事件键改名使旧产物失效 | manifest hash 自然换新；`registerNativeComponent` 按原参数名读 props，不受影响 |
| provider 闭包语义在统一路径退化 | 「元素 vs 纯值」闭包分支 + `provider.js` 逻辑微调 |
| builder 键判据失效使 sliver 代理由宿主结点降级 | 抽取失败出声 + 产物形态校验 |
| 位置实参协议变更（`props['$pos']`） | `Text`/`Image` 等 renderer 必须同步改，纳入批 4 |
