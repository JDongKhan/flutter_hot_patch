## 0.11.0

**破坏性变更：三方库 JS 不再由生成器生成。** provider 的 `patch/provider.js` 改为宿主维护的 `js/provider.js`，构建时拷贝到 `patch/packages/provider.js`；业务产物 import 路径随之变化，旧补丁包不兼容。

- **删除 provider 产物生成**：删除 `builders/runtime/js/provider_module_js.dart`、`logicWidgetSources` 里的 provider 三件套、`_packageModuleEpilogues`、`widgetPackages` 硬编码表；生成器不再认识任何具体三方库。
- **新增 `ui_third_party_js` builder**（`third_party_js_builder.dart`）：宿主工程 `js/**.js` → `patch/packages/**.js` 原样拷贝。文件名即 Dart 包名（`js/provider.js` ↔ `package:provider`）；输出清单按文件系统扫描静态推导（与 `ui_project_module` 同款），无需改宿主 `build.yaml` 的 `sources`。
- **三方类型归属改为源码事实**：`js_class_defs.dart` 的 `thirdPartyPackageOf` 用「类声明所在包（`CtorSignatures.declaringPackagesOf`）+ 该包是否有 `js/<package>.js`」判定，`packageModulePath` 对三方包返回 `patch/packages/<package>.js`；`element2js` 的 `jsClassFileOf` / `_registerWidgetImport` 与 `component_builder` 的前缀 / 副作用 import 同步走该规则，无库名 / 类型名白名单。
- **provider JS 迁到宿主**：新增 `example/js/provider.js`（`ChangeNotifierProvider` / `MultiProvider` / `Consumer` + `context.watch/read` 原型补丁），对 `flutter.js` 的相对 import 改为 `../flutter.js`；删除生成的 `example/patch/provider.js`。
- **缺失宿主 JS 模块时构建期报错**：`js_class_defs.dart` 新增 `missingHostJsPackageOf`（类声明所在包 ∈ pub 依赖、且该包没有 `js/<package>.js` 时返回包名；本项目包 / 本地依赖包 / 框架包 / `dart:` / 运行时已注入的类一律不算缺失）；`element2js` 的元素渲染（`_renderJsImpl`）与值渲染（`_renderValueImpl`）在 `jsClassFileOf` 为空时按类型 `log.severe`（构建失败）一次，指明应在工程根 `js/<package>.js` 提供该包 JS——此时产物必然在运行期失败，不属于「有风险但能跑」的 warning。`js/` 为空且源码没用到三方类型时构建照常完成、零三方产物。
- **日志级别归位**：`component_builder` 的「本文件产出哪些类」由 `print`（build_runner 显示为 W）改为 `log.info`；warning 保留给「有风险但仍能运行」，影响运行的一律 error。
- **`ui_third_party_js` 配置去具体包**：`build.yaml` 的占位 `build_extensions` 由写死 `patch/packages/provider.js` 改为空列表（输出清单只由 Builder 实例按宿主 `js/**.js` 扫描推导），新增任何三方库都不用改生成器配置。
- **构建期日志降噪（只改判定，产物不变）**：
  - `element2js` 的 `_SimpleIdentifierCollector` 只收**变量引用**：具名实参名 / 语句标签（`Label`）、成员名（`Icons.height` 的 `height`）、命名构造名、带接收者的方法名不再算「被 builder 捕获的局部变量」，修复 `sliver_detail.dart` 的误报。
  - `js_translator` 擦除泛型实参时，若接收者是 **JS 内建**（List/Array/Iterable/Set/Map/String/num/int/double），不再告警（`fold<int>` 这类本就无 JS 语义），自定义类 / 类型不可判定时才出声。
  - `_fieldTranslatable` 新增「类自身类型参数」（`Pair<K, V>` 的 `K`/`V`）与「源码简单枚举」两条放行判据（`CtorSignatures.isEnum` 按源码 `enum` 声明判定，增强枚举不算），修复 `generic_detail.dart` / `constructor_detail.dart` / `enum_detail.dart` 的误报。
- **构建期日志带源码定位**：新增 `shared/source_location.dart`（`registerSource` 在解析处登记 `LineInfo` + 原文；`sourceAt` 输出 `<文件>:<行>  |  <该行源码>`，定位到**声明本体**而非文档注释）。element2js / element_json / analyze_dart_class / extension_support / const_support / js_translator 的告警与报错统一改用该格式；渲染阶段通过 `registerNodeSource` 从元素中间态描述反查来源 AST 结点。
- **文档同步**：架构文档、使用手册、组件支持文档与 README 的产物布局 / 三方库接入指引改为 `js/` → `patch/packages/` 约定。

## 0.10.0

**破坏性变更：产物布局。** 本地依赖包不再一包一个模块，改为**按源文件同名镜像**；旧 `patch.zip` 与本版本产物不兼容，需与生成器同版本配套使用。

- **依赖包产物按原文件路径镜像**：`package:foo/src/a.dart` → `patch/packages/foo/src/a.js`（`paths.dart` 的 `productPath` / `packageSourceProductPath`）。加 `packages/` 前缀是为了与本项目 `patch/<lib 相对路径>.js` 隔离，避免项目 `lib/` 下同名目录撞名。框架包（`flutter` / `provider`）仍是 `patch/<pkg>.js` 单模块。
- **跨包 builder 改为按文件产出**（`project_module_builder.dart`）：输出清单由 `localTranslationPackageFiles()` 静态扫描本地包全部 `.dart` 文件推导，未引用的文件写空模块；每个文件只翻译本文件里被引用到的类 / mixin，并承载本文件的 `extension` 注册语句。
- **删除独立的 extensions 产物**：`ui_extensions` builder、`extensionModulePath`、`patch/extensions/<pkg>.js` 全部移除；扩展随声明文件产物 `registerExtension(...)` 发射，调用方 import 该文件即完成注册。AGENTS 与架构文档的产物布局同步更新。
- **barrel 生成 re-export**：只有 `export` 转发的包入口（如 `lib/foo.dart`）产出 `export { A } from './src/a.js';`，保证 `import 'package:foo/foo.dart' as p` 的 `p.A` 引用继续可用；`show` / `hide` 按声明名过滤。
- **record 模式**：`_compilePattern` 新增 `RecordPattern` 分支，位置字段按 record 字面量产物取 `["$1"…"$N"]`、命名字段取原名，逐字段递归匹配（常量 / 变量 / 嵌套模式全部复用同一套编译）；JS 侧 record 是普通对象，只做 `typeof === "object"` 浅检查。示例 `record_detail.dart` 增加 `_recordPatternText`（位置 + 命名 record）。
- **extension 显式调用与可空目标**：`_explicitExtensionReceiver`（`js_translator.dart`）识别 `E(x).m(...)` 的两种 AST 形态（已解析 `ExtensionOverride` / 未解析裸名 `MethodInvocation`），按 `extensionNamesInScope`（本文件 + import 图）确认可见具名扩展后改写为 `x.m(...)`；拦截点放在 `rhsToJs` / `exprToJs` 的构造翻译之前，避免 `E(x)` 被误当 `new E(...)`。`translateExtension` 对可空目标（`extendedType.question != null`，如 `String?`）构建期出声跳过。示例 `extension_detail.dart` 增加 `ShoutEx` 显式调用与 `NullableTag`（可空目标告警）。
- **修复 `flutterExportTypes` 误抽取**：运行时片段扫描跳过行首注释行，不再把注释示例里的 `export const StringLogExtension = ...` 当成 `flutter.js` 导出（否则产物会 import 不存在的名字）。
- **`Completer<T>`（运行时能力，翻译器零改动）**：`future_js.dart` 新增 `export class Completer`——`future` 是 `Future.__wrap` 包住的外置 resolve/reject Promise（`await` / `then` 与 Future 同一通道）；`complete` / `completeError` 只允许一次，重复完成抛 `StateError`；`isCompleted` 为 getter。产物按普通构造翻译（`new Completer({typeArguments: …})`），导出名由运行时片段自动抽取。example 新增 `async_detail.dart`（`AsyncDetail`）：`Future.delayed` + `Completer.complete` 与 `completeError` 两条路径。
- **Stream / StreamController / StreamSubscription（运行时能力模块）**：新增 `stream_js.dart`，随 `flutter.js` 发布 `export class Stream` / `StreamSubscription` / `StreamController`。`Stream` 实现推送（`listen`）+ 拉取（`[Symbol.asyncIterator]`）双形态：`async*` 流惰性启动（首次 listen / 迭代才跑生成器）；**事件异步投递（微任务）**——`add` 调用栈内不触发订阅回调、`await close()` 后读取才包含全部事件（与 Dart 事件队列时序一致）；**拉取式背压**——单订阅流 `pause()` 时上游 `async*` 生成器停在 `yield` 处（`_waitReady` 阻塞到 `resume()`），订阅全部取消时停止生成器并调用其 `return()`，广播流不传播 pause；单订阅流二次订阅抛 `StateError`，广播流每订阅者独立；单订阅 `pause` 缓冲、`resume` 补发，广播 `pause` 丢弃 data；错误不终止流（除 `cancelOnError`），`await for` 遇 error 抛错。终止操作 `toList` / `toSet` / `first` / `last` / `length` / `isEmpty` / `isNotEmpty` 返回 `Future.__wrap`；转换 `map` / `where` / `expand` / `take` / `skip` / `distinct` / `asyncMap` / `asBroadcastStream` / `pipe` 返回新 Stream（订阅时串行消费上游）；静态工厂 `value` / `empty` / `error` / `fromFuture` / `fromIterable` / `periodic`；`StreamController.broadcast` 返回广播控制器。
- **`async*` 与 `await for`**：`async*` 方法渲染为 `return Stream.fromAsyncGenerator((async function* () { … }).bind(this)())`（`.bind(this)` 保住方法体里的 `this`），生成器闭包 / 局部函数同口径包装（外层箭头保证默认值在调用时求值）；`_forStatementJs` 按 `ForStatement.awaitKeyword` 输出 `for await (... of ...)`（三段式 / for-in / pattern for 三种形态），并删除原先「await for 暂不支持」的拦截。example 新增 `stream_detail.dart`（`StreamDetail`）：listen、pause/resume、Controller、broadcast、await for、转换 / 终止。
- **修复泛型类型 + 命名构造被吞**：`valueCtorJs` 的 `InstanceCreationExpression` 分支改为从 `constructorName.name` 取构造名（此前只解析 `type.toSource()`，`StreamController<int>.broadcast()` 会落成无名 `new StreamController(...)`）。
- **泛型 extension 目标**：泛型扩展仍注册在擦除后的目标原型上（`extension E<T> on List<T>` → `Array.prototype`，Dart 的「仅此实例化可调」约束无法还原，记为接受差异）。新增 `_TypeParamValueUse`（`extension_support.dart`）：成员体里把类型参数按值使用（`T.toString()` / `T == int`）时构建期出声——接收者没有 `typeArguments` 元信息，读不到类型名；类型位置（返回类型 / 形参类型）不受影响。example 的 `generic_detail.dart` 新增 `ListTail<T> on List<T>`（`tailOrNull` / `tailText`）与 `TypeCodecLabel<T> on TypeCodec<T>`（`label`）。
- **`sync*` / `yield` / `yield*`**：`closureToJs` 对 `BlockFunctionBody + isGenerator` 产出 `function*`（局部函数 / 生成器闭包）；`dart2js` 方法渲染按 `isGenerator` 加 `*` 前缀（`async*` → `async *`，裸异步生成器）；`translateStmtList` 新增 `YieldStatement` 分支，按 `star` 发射 `yield` / `yield*`。运行时在共享 `%GeneratorPrototype%` 上补 `toList` / `toSet` / `map` / `where` / `expand` / `fold` / `any` / `every` / `take` / `skip` / `join` / `contains` / `indexOf` 与 `first` / `last` / `length` / `isEmpty` / `isNotEmpty`（先 `Array.from(this)` 再复用 Array 语义）。`__defineProtoMember` / `__defineProtoGetter` 新增 `overwrite` 参数（默认不变），生成器成员用它覆盖引擎自带的 Iterator Helpers，保证跨引擎一致；已知差异：JS 生成器一次性迭代、成员立即求值。example 新增 `generator_detail.dart`（`GeneratorDetail`）。

## 0.9.0

**协议次版本：契约不变；语法翻译产物按 `Dart转JS语法翻译手册` v1.4 校准（mixin 产物形态变更，老路径语义不变）。**

- **局部变量声明改用 `let` / `const`**：`var` 与无修饰声明 → `let`，`final` / `const` → `const`，不再生成 `var`；无初始化器显式补 `= null`（Dart 只有 null，JS 裸 `let` 是 undefined）。`for` 初始化、局部函数（`const f = …`）、catch 绑定、参数默认值 prologue 同步（`js_translator.dart` 的 `translateStmtList` / `_localFunctionJs` / `_forStatementJs` / `_tryStatementJs` / `_functionParamPlan`）。
- **空值归一 `__nn`**（运行时 `G.__nn`，`undefined → null`，不抛错）：`exprToJs` 的 BinaryExpression 只在**操作数可能为空**时包（新增 `_mayBeNull`：字面量、构造、集合字面量、声明为非空类型的字段 / 形参 / 局部变量都不包；`String?` / `dynamic` / 类型不可判定才包）。判空保持 `== null`，其余相等用 `===` / `!==`；非判空相等**只要有一侧确定非空**（字面量 / 非空类型 / 构造等）就不包 `__nn`，仅两侧都可能为空时才归一。**局部变量类型推断保留原始可空性**（`final error = vm.error;` 记为 `String?`，后续 `error != null` 才会包 `__nn`），先取 `_rawExprType` 再退回擦除后的 `_staticTypeOf`。Map 读取只在**值位置**（初始化 / 赋值右侧 / 实参 / 返回 / 插值，`_mapReadValueJs`）包 `__nn`；for-in 迭代源不包（for-of 对 null / undefined 同样抛 TypeError）。
- **`!` 保持忽略**：`exprToJs` 的 PostfixExpression `!` 直接返回操作数（不生成非空断言；项目口径接受独立值位置与 Dart 的差异，访问位置仍由 JS 自然抛 TypeError）。
- **空安全自增 / 自减**：`a?[i]++` / `a?.x++` / 前缀 `++` 落成接收者单次求值的守卫 IIFE（值位置保留旧值 / 新值语义，语句位置空目标整句跳过）；普通下标 / 属性自增语句补 `+= 1` / `-= 1` 形态（此前会告警丢弃）。新增 `_nullAwareUpdateJs`。
- **运算符语义**：Dart `%` → `__mod(a, b)`（欧几里得取模，负数结果非负）；`identical(a, b)` → `Object.is(a, b)`。
- **类型判断**：`is int` → `Number.isInteger`、`is Set` → `instanceof Set`、`is dynamic` → `true`、`is Object?` → `__nn(v) != null`、`is Never` → `false`（不可达分支）；`Map` 判定排除 `Set` 实例（`typeTestJs`，`js_value.dart`）。
- **Array 内建同名补齐**（`runtime_js.dart`【1c】）：`addAll` / `contains` / `fillRange` / `sublist` / `firstWhere` / `expand` / `fold` / `any` / `take` / `skip` / `asMap` / `elementAt`；`remove` 改为「`===` + 元素自带 `__op$eq`」；`insert` 越界抛 RangeError。
- **构建期成员映射表（只对可判定为 `List` 的接收者）**：`sort → _sort`（默认 Dart Comparable 比较器）、`join → _join`（默认空串；null / undefined 元素按 `"null"` 输出）、`indexOf → _indexOf`（元素 `==` 走 `__op$eq`，start 为负按 0 / 超长返回 -1）、`length 写 → _setLength(n)`（截断 / 补 null；`_listLengthWriteJs` 覆盖 `x.length` 的 PropertyAccess / PrefixedIdentifier 两种目标）。运行时挂 `Array.prototype._sort` / `_join` / `_indexOf` / `_setLength`；自定义类 / Map / 其它接收者同名成员一律原样，绝不按方法名全局替换。`_staticTypeOf` 补 `ListLiteral` / `SetOrMapLiteral` 与成员链（`bucket.nums` / `oldWidget.list`）的字段声明类型解析。
- **翻译范围收敛（常量 ↔ 类固定点）**：`componentTranslationScope` 不再把「可达文件里的所有顶层常量」都先按依赖标记类；改为先由根类算出 `neededConsts`，再只传播**已确认写入产物**的常量所引用的类，并迭代到不再增长。可达但无人引用的常量（如 `appLogZoneSpecification`）不会再把它引用的类 / 整个文件拖进 patch 产物（`app_log_console.dart` 不再产出）；extension 仍按「文件可达即产出」传播其方法体依赖（`Estrange` 等正常产出）。
- **数组语法 demo**：新增 `example/lib/components/grammar/array_detail.dart`（`ArrayDetail`）并接入「基础语法 · 列表」入口，覆盖 `sort` / `join` / `indexOf` / `fold` / `any` / `expand` / `take` / `skip` / `asMap` / `length` 写等；不再往 `syntax_detail.dart` 堆用例。
- **枚举 `byName` 与产物格式化**：`_enumJs` 给项目枚举常量对象挂 `byName(name)`（线性查找 `name`，找不到抛错）；翻译层把 Dart 标准库 `<E>.values.byName('x')`（EnumByName 扩展）改写为 `<E>.byName('x')`，仅当前缀不是本作用域的值时生效。枚举产物从单行改为多行（`__mk` / 各常量 / `return` 对象分行），可读性与普通类一致。示例 `syntax_detail.dart` 增加 `TaskLevel.values.byName('high')`。
- **函数值 toString 差异记录**：tear-off 落成 `recv.m.bind(recv)`，函数对象本身的字符串表示与 Dart VM 的 `Closure: …` 不同（JS 为 `function m() { [native code] }`），属引擎表示差异，不伪造；手册第 07 章已加说明。
- **默认构造（无名构造）初始化列表 / 构造体**：新增 `_translateUnnamedCtor`（`analyze_dart_class.dart`），把 `A(args) : x = …, y = … { … }` 的形参局部绑定、初始化列表（`this.x = …` / `assert(…)`）与构造体按「形参 → 字段默认值 → 初始化列表 → 构造体」顺序写入 `constructor(args)`（`dart2js.dart` 的类声明渲染）。`super(...)` / `this.other(...)` 与命名构造同口径告警跳过；空构造（widget 的 `const A({super.key})`）不生成形参绑定，既有产物形态不变。示例 `syntax_detail.dart` 增加 `Stamp`（非 `this.x` 形参 + 初始化列表 + 构造体）。
- **抽象类**：`abstract class` 不再被类表 / 翻译范围过滤，照常产出普通 JS class（`ClassInfo.isAbstract`）；无方法体的抽象成员由 `translateClassMethodBody` 生成 `throw new Error("Unimplemented: Class.member")` 兜底，具体子类经原生 `extends` 覆盖。抽象类只会作为模型根类产出（`component_builder` 的根类收集），可被同文件内联或跨文件 `<abstract>.js` import。
- **extension 运算符**：extension 成员里的 `operator` 与类运算符共用 `operatorJsName` 映射（`__op$add` / `__op$neg` / `__op$mod` …），成员随 `registerExtension` 装到目标原型；调用点新增可见运算符表 `extensionOperatorsInScope`（目标类型 → 运算符 → JS 成员名，同目标同运算符多声明视为歧义不登记），在类自身运算符判定之后按接收者静态类型改写为 `receiver.__op$xxx(args)`（含一元与 `%`）。核心类型不登记（已有实例运算符，extension 不会命中）。示例 `grammar_details.dart` 增加 `Vector` / `VectorOps` / `_extensionOperatorText`。手册第 11 章同步为实际注册方案，并补 `operator` 行。
- **mixin 按原文件独立类 + application 类链实现（产物形态变更）**：`mixin` 声明不再线性化进目标类，而是按**原文件路径**产出独立 `export class`（`translateMixin`；ComponentBuilder / ProjectModuleBuilder 同步产出，scope 把 mixin 名纳入 neededClasses）。`class C extends B with M1, M2` 在消费者产物里生成 application 类链（`_C_B_M1` → `_C_B_M1_M2`），最终 `C` 继承最后一层：不带 `super` 的成员留给 mixin 类，由运行时 `__mixinHard`（`getOwnPropertyNames` + 描述符复制，目标已有同名自有成员不覆盖）应用到 application 原型；带 `super` 的方法在 application 层重新发射并用原生 JS `super` 指向上一层；mixin 字段由 application 类构造函数按 `with` 顺序初始化；`__mixinHard` 调用统一放在本模块全部类声明之后（避免 TDZ）。`mixin class` 同时按普通类产出，`with` 时走同一套链。**删除旧实现**：`classInfoOf` 的 mixin 线性化合并、`_m$Mixin$name` 改名、`ClassMethod.superMap` / `mixinOrigin` 与对应翻译分支。示例 `grammar_details.dart` 增加 `CounterM` / `MultiTagged`（多个 `with` + 字段）与 `SuperM` / `SuperTagged`（mixin super）。
- **Map：字面量改原生 JS Map + Map.prototype 补齐成员**。`{k: v}` → `new Map([[k, v], …])`（空 Map / 字段默认 → `new Map()`；`Map.from/of` → `new Map(other)`）；`m[k]` / `m[k] = v` 仅在接收者类型可判定为 Map 时改写为 `__idx` / `__idxSet`（原生 Map → `get`/`set`，宿主回包的普通对象 → 下标；表达式赋值、语句赋值、级联三处同口径）；**List 与类型不可判定的下标保持原生 `a[i]`，不包任何辅助**。运行时在 `Map.prototype` 上：补同名 `length`（`this.size`）/ `remove`（返回被删值）/ `containsKey` / `containsValue`（`===` + `__op$eq`）/ `putIfAbsent` / `update`（`ifAbsent` 尾参对象）/ `addAll` / `removeWhere` / `isEmpty` / `isNotEmpty`；`keys` / `values` / `entries` 与 JS 同名方法语义不同 → 挂 `_keys` / `_values` / `_entries` getter（`entries` 物化为 `{ key, value }`），生成器按 Map 接收者改写；`forEach` 保持同名、不覆盖原生，只在调用点交换回调参数（`((__v, __k) => cb(__k, __v))`）；`clear` 原生同名同义不动。宿主桥：`Map.prototype.toJSON` 让 Map 按普通对象序列化；宿主回包保持普通对象（由 `__idx` / `__idxSet` 兼容两种承载）。`Array.asMap()` 返回原生 Map。新增示例 `example/lib/components/grammar/map_detail.dart`（`MapDetail`，入口「基础语法 · 映射」）。
- **可调用对象 `call(...)` → `invoke(...)`**：`classInfoOf` 把项目类**非 static 实例方法 `call`** 改名为 `invoke`，并记 `ClassInfo.isCallable`；调用侧在接收者静态类型可判定为可调用类（含 `extends` 链）时，把 `obj(...)` / 字段 `cb(...)` / 显式 `obj.call(...)` / 类内裸调用 `call(...)` 一律改写为 `.invoke(...)`；类型不可判定保持原样，不按名字猜测。**函数类型的 `call` 另行处理**：`Function` / `T Function(...)` 接收者的 `fn.call(a, b)` 改写为直接调用 `fn(a, b)`（JS `Function.prototype.call` 首参是 thisArg，语义不同），可空 `fn?.call(...)` → `fn?.(...)`。示例 `syntax_detail.dart` 增加 `Adder`（`add(1)` 与 `add.call(2)` 均落 `add.invoke(...)`）与 `_functionCallText`（`fn.call(3)` → `fn(3)`）。
- **record 字面量**：新增 `_recordLiteralJs`（`js_translator`，`rhsToJs` / `exprToJs` 共用）：位置字段生成 `{"$1": a, "$2": b}`、命名字段用原名；混合记录 `(a, x: 1)` 同一对象承载，`r.$1` / `r.x` 原样属性访问（`$1` 是合法 JS 标识符），无需按类型改写，也不动字面量以外形态。**作为返回值无独立分支**：箭头体 `=> (…)`、`return (…)`、局部函数、闭包统一由 `rhsToJs` 承接。已知差异：Dart record 的 `==` 是结构相等，JS 对象仍是同一性（手册注明，不伪造）。示例 `syntax_detail.dart` 增加 `_recordText`（positional / named / mixed）与 `_pairValue` / `_namedPairValue`（箭头体 / 语句体返回值 + 局部函数 / 闭包返回 record）。
- **手册强化约束（v1.3）**：新增「实现者硬约束」——禁止自造产物形态 / 命名（包装函数、额外类、`__proto__` 原型注入、按成员名造的 `__xxx` 原语），成员翻译只允许「同名 / 语义冲突 `_` + 映射表 / 缺同名走 `__defineProtoMember`·`__defineProtoGetter` 表」三种写法，载体形态以手册「JS 对应」列为准，改前先查手册、改后回写；并修正 Map 相关的过时描述（`const Map` 不冻结、`asMap` 返回原生 Map、`is Map` 兼容两种承载、Map 纳入构建期映射表）。
- **手册同步**：`dart2js-syntax-reference/Dart转JS语法翻译手册.html` 升 v1.4，逐行更新「现状 / 是否通过」；mixin 章节改为唯一方案（原文件独立类 + application 链 + `__mixinHard` + application 层原生 super），删除旧的「成员复制 / `$super` 包装」示例与红线。
- 断言语义：`dart analyze` 无错误；`example` 全量产物 `node --check` 通过（ESM）。

## 0.8.1

**协议次版本：契约不变，空安全产物形态改为 JS 原生可选链；旧的三元 / IIFE 展开同次删除，不保留兼容。**

- 空安全属性访问 / 下标 / 方法调用改为与 Dart 源码同形：`a?.b` → `a?.b`、`a?[i]` → `a?.[i]`、`a?.m(args)` → `a?.m(args)`（`shared/js_translator.dart` 里三处旧展开删除）。接收者只求值一次、null / undefined 时整链短路，实参 / 下标不求值——链式 `a?.b?.c` 不再逐层展开三元（旧写法在链上会重复求值接收者，且 `a?.b.c` 在 `a` 为 null 时丢短路、直接 TypeError）。
- 空安全赋值 `a?[i] = v` / `a?.b = v`（JS 可选链不能作赋值目标）落成接收者单次求值的守卫 `((__t) => { if (__t != null) __t[i] = v; })(a)`；普通下标 / 属性赋值 `a[i] = v` / `a.b = v` 同分支支持。目标链**任意一层**出现 `?.` / `?[` 都走同一守卫（`_obj?._scores?[1] = 1` 只让前缀变长，不嵌套守卫）；接收者为空时下标与右值均不执行。
- 引擎基线：产物开始依赖 ES2020 可选链（此前已使用 `??`，同一代引擎能力）；`docs/组件支持文档.md` §7.1 与 §6.14 同步更新（iOS 口径 15+）。
- **模式匹配**：`if (x case P when g)` 与 pattern 变量声明（`final [a, b] = list;` / `final User(:name) = user;`）接入同一条 `_compilePattern`：常量 / 声明变量（含类型检查）/ 关系 / 空检查 / 逻辑与·或 / 对象（逐字段）/ 列表（定长与末位 `...rest`）。接收值单次求值，绑定只注入命中分支（if-case 结束后还原作用域），解构不匹配抛 `Error`；记录模式仍构建期告警跳过。
- **switch 增强**：`switch` 语句与表达式支持 `when` guard 与任意模式（关系 / 对象 / 列表 / 逻辑 / 声明变量）。纯常量形态产出原生 JS `switch`；非常量形态同样使用**原生 `switch`**——主体写成 `switch (true)`，case 条件落成箭头 IIFE 并负责绑定（`case (() => { … })():`），保留原生 switch 的求值顺序、贯穿、`default` 与 `break` / `continue` 语义；switch 表达式在 IIFE 内用同一形态，`default` 抛错兜底。
- **局部函数**：方法体内的函数声明（表达式体 / 块体）复用 `closureToJs` 产出 `var f = (…) => …`（`this` 词法捕获、可递归、块体内可用 if-case 等全部语句能力）；名字登记进方法作用域，同名裸调用按局部标识符翻译（同时覆盖「局部变量里存函数再调用」）。可选位置 / 具名形参与默认值、泛型类型形参均已支持（与类方法 / 闭包共用同一签名实现）；生成器局部函数仍构建期告警跳过。
- **泛型局部函数**：`T f<T>(…)` 的类型实参由调用点尾参对象下发，定义侧追加尾参 `__ta`（已有具名形参时复用 `__o`），函数体里的 `T` 读 `typeArguments`；调用点按声明登记的类型参数名写参数名键（`f<int>()` → `{ typeArguments: {"T": "int"} }`），与定义侧一致（此前未登记会退化为位置序号键 `{"0": …}`，定义侧读到 `undefined`）。
- **label 语句**：`outer: for (…) { … break outer; }` / `continue outer;` 一比一发射为 JS 标签语句（多个标签按源码顺序排列）。
- **集合 if-case 元素**：`[if (v case P when g) a else b]` 支持，产物为 `...(() => { 匹配 + 绑定; return ok ? [a] : [b]; })()`（接收值单次求值、绑定只在该元素内可见）。
- **pattern for 头**：`for (final [a, b] in pairs)` / `for (final User(:name) in users)` 复用 `_compilePattern` 逐轮解构（绑定只在本轮循环体可见，不匹配抛错）。
- **集合元素 if / for / 展开**：`_listLiteralJs` 支持 `if (c) …` / `for (x in xs) …` / `...xs` / `...?xs`，产物为数组展开片段（`[1, ...(c ? [a] : []), ...xs, ...(xs).map((x) => [f(x)])]`）；三段式 `for (var i = 0; i < n; i++)` 元素落成 IIFE 内原生 for + `push` 后展开。
- **集合字面量可在任意表达式位置**：`exprToJs` 接入与 `rhsToJs` 相同的 `_listLiteralJs` / `_collectionLiteralJs`，因此 `for (final x in ['a', 'b'])` 的迭代源、三元分支、函数实参、`??` 右操作数等位置不再整条翻译失败（此前只会出现在赋值右侧）。
- **try/catch 多子句 + `on Type`**：JS 只有一个 catch 参数，产物改为统一捕获名 `__e` + `if/else` 链（`if (__e instanceof X)`，catch-all 落 `else`，未命中任何子句则 `throw __e`），支持 `catch (e)` / `on T` / `on T catch (e)` / `on T catch (e, s)`（栈参数取 `__e.stack` 并别名）；类型判别复用 `typeTestJs`，SDK 错误类（`FormatException` / `RangeError` / `StateError` …）随 `flutter.js` 自动 import。类型在 JS 侧无法判别时出声告警并按 catch-all 处理。
- **`hashCode` 补齐**：运行时在 `Number.prototype` / `String.prototype` 上补 `hashCode` getter（数字返回自身、字符串为 FNV-1a 32 位稳定散列；存在性守卫 + 不可枚举）。自定义 `operator ==` 的类组合字段 `hashCode` 时不再得到 undefined。仍不挂 `Object.prototype`（项目规则禁止），未自定义 `hashCode` 的普通对象仍为 undefined。
- **数值语义修正**：Dart `a ~/ b` 的取整方向改为 `Math.trunc`（向零截断，`-3 ~/ 2 == -1`；此前用 `Math.floor` 对负数会得到 -2）。int / double 仍一比一翻译为 JS `number`，`+ - * / %` 与比较沿用原生运算——不需要也不参与 `__op$` 运算符分派。
- **setter / 运算符重载**：`set x(v)` 发射为 JS 属性写访问器（`_applyProps` 之外新增 `set` 成员；赋值调用点本来就是 PropertyAccess）。运算符按 `__op$<后缀>` 成员发射，调用点在「操作数静态类型可判定」时改写为成员调用——类型来源为字段类型、形参类型、显式类型的局部变量与项目类构造推断；`==`/`!=` 按 Dart 语义先判空再分派 `__op$eq`，`[]`/`[]=` 与一元 `-` 同样覆盖。类型不可判定时保持 JS 原生运算；无 JS 等价成员的运算符声明（一元 `~`、位运算、移位等）仍构建期告警跳过。
- **位运算 / 移位 / 复合赋值**：二元 `&` / `|` / `^` / `<<` / `>>` / `>>>` 与一元 `~` 一比一发射为 JS 同名运算符（数值按运行时口径，位宽 32 位）；复合赋值 `a op= b` 中 JS 没有的 `~/=` 按语义展开为 `a = Math.trunc(a / b)`，目标为下标时把下标绑成临时参数（`a[f()] ~/= 2` 只求值一次），其余复合赋值（`&=~x` / `<<=` / `>>>=` / `??=` 等）原样发射。
- **`rethrow`**：catch 内原样重抛统一捕获名 `__e`（`throw __e;`，不重建 Error，异常对象与栈保持原样），嵌套 catch 与闭包内同样有效；此前该语句未覆盖，会被构建期告警并丢弃（catch 里吞掉异常继续执行）。
- **空安全级联**：`a?..b()..c()` 目标为 null / undefined 时整条级联短路（返回目标本身，后续 section 不执行），产物为带入口守卫的 IIFE（`((_t) => { if (_t == null) return _t; …; return _t; })(a)`）；非空级联产物形态不变。此前该语法产成无守卫的 `_t.b()`，目标为 null 时运行期 TypeError。
- **级联内赋值**：`x..a = v` / `x..[i] = v` / `x..a += v` 此前未覆盖，整条级联（含其所在声明 / 表达式）翻译失败并告警丢弃。现在 section 以已绑定一次的 `_t` 为根逐层展开（`..a.b = v` → `_t.a.b = v`，`..[i] = v` → `_t[i] = v`），赋值为 IIFE 内的一条语句，级联结果仍是 target 本身；空安全级联 `x?..[i] = v` 在目标为空时整条短路、赋值不执行；`~/=` 按同一口径展开为 `_t[i] = Math.trunc(_t[i] / v)`。级联内**读**访问（`..a.b` / `..[i]`）同步按相对链展开，不再丢掉中间层。
- **父类成员 `super.x`**：`super.x` 读取此前未覆盖（`exprToJs` 无 `SuperExpression` 分支），整条表达式告警丢弃。现在按源码事实区分：`x` 属于**继承链字段**（`FieldScope.instanceFields` 是含父类的字段视图）→ `this.x`（JS 字段落在实例属性上，`super.x` 只查父类原型、读不到）；父类 getter / 方法在原型上 → 原样 `super.x`（子类 override 时与 Dart 语义一致）；基类在 JS 侧无实现（类声明不写 `extends`）时出声告警，不发射非法 `super`。`super.x = v` 在语句与表达式位置都直接发射成员赋值（`super` 不是值、不能传入 IIFE），`~/=` 要读两次属性故告警不支持。
- **方法 tear-off（值位置）**：`final f = _handler;` / `items.map(_fmt)` 此前产出未绑定的 `this._handler`，运行时 `this` 为 undefined。现在按同源方法表的 getter 名区分：**getter** 仍是值读取（`this.x` / `super.x`），**实例方法** tear-off 落 `this.m.bind(this)`（Dart 的 tear-off 自带 `this`）；裸 static 方法落 `ClassName.m`（静态成员无 this 可绑）；`super.m` tear-off 落 `super.m.bind(this)`。组件数据作用域（文本插值 / 数据表达式）、事件作用域与构造初始化器共用同一规则（`FieldScope.getterNames` 由 `objectGetterNamesOf` 提供，继承链视图）。`obj.method` / `this._field.method` 同样覆盖：按接收者静态类型（局部变量 / 形参 / 字段声明类型，含无 `new` 的项目类构造推断）判定成员是方法还是 getter；方法且接收者为简单引用 → `recv.m.bind(recv)`，复杂表达式 → `((__o) => __o.m.bind(__o))(recv)`（接收者只求值一次）；空安全 `a?.m` → `a?.m.bind(a)`（a 为空时整链短路）；类型不可判定（SDK / 顶层常量 / 类名）时保持原样，不按名字猜。
- **函数值调用**：`(f)(args)` / `((x) => x)(v)`（AST `FunctionExpressionInvocation`）此前完全未覆盖，整条表达式告警丢弃。现在按普通调用约定翻译：位置实参在前、具名实参合并成尾参对象、闭包实参走 `closureToJs`；类型实参暂不支持（返回 null，由调用方出声）。同时修正**闭包作为运算符操作数**的括号：`a ?? (v) => v`、三目分支、一元前缀、`~/` 此前产出非法 JS（箭头函数优先级低于运算符），现在这些位置统一补括号。
- **函数形参签名统一**：位置形参（含可选位置）按原名进 JS 签名，可选位置缺省在函数体开头补默认值（无默认值即 `null`）；具名形参不占位置——调用点把具名实参合并成**尾参对象**，定义侧用 `__o` 接住并在函数体开头解构（缺省取默认值 / `null`）。类方法 / 静态方法 / 扩展方法 / 闭包 / 局部函数共用 `_functionParamPlan` 一处实现；方法泛型时类型实参与具名实参共用同一个尾参对象。此前具名形参被当成位置形参，具名调用会把整个对象赋给第一个形参。闭包本身也接入任意表达式位置（变量初始化器 / 实参 / 三元分支 / return），这些位置的闭包不再被整条丢弃。
- **赋值作为表达式**：`while ((x = f()) < n)` / `if ((v = f()) != null)` / 声明初始化器里的赋值此前未被 `exprToJs` 覆盖，整条翻译失败并告警丢弃。现在值语义为赋值结果：普通目标一比一发射（`(this._x += v)`）；下标 / 属性目标的接收者、下标、右值各求值一次；`~/=` 展开为「读 → 算 → 写」并返回写入值；空安全目标（`a?[i] = v` / `a?.b = v`）落成守卫 IIFE，目标为空时表达式值为 `null` 且右值与下标不求值；`operator []=` 目标的表达式值为右值。语句位置产物形态不变。
- **`throw` 作为表达式**：`a ?? throw e` / 三目分支 / 实参 / switch 表达式分支此前无法翻译（连带整条表达式告警丢弃）。现在落成「立即抛出的 IIFE」（`(() => { throw e; })()`）；箭头体 `() => throw e` 直接产出语句体 `{ throw e; }`，不额外包 IIFE。语句位置仍为原生 `throw e;`。
- **无静默补齐**：组件 props / 位置实参翻译失败时补构建期告警（输出源文件、`类型.参数名` 与源码表达式）。此前 `Text(style: Theme.of(context).textTheme.titleMedium)` 这类不可翻译值会被 `nonNull` 直接去掉且无任何日志；现在行为不变（仍丢弃该键），但一定会出声。
- 产物排版统一：删除 `_setStateJs` 里「回调体折成单行」的特判，`setState` 回调与其它方法体走同一套写出前缩进归一（`canonicalizeJsIndent`）。
- 示例：`BannerCarousel._stopAutoPlay` 删除「先取本地引用再判空」的旧绕行写法，恢复 `_timer?.cancel()`。

## 0.8.0

**破坏性：JS 侧新增原生 InheritedWidget 语义；provider 去掉宿主结点与宿主 context op（旧 `__provides` / `__registerScope` / `__scopeOfContext` 协议与 provider 宿主映射同次删除，不保留兼容）。需与 hot_patch 0.4.0 配套。**

- **InheritedWidget（纯 JS）**：`flutter.js` 新增 `export class InheritedWidget extends Component`（build 返回 `props.child`，`updateShouldNotify(oldWidget)` 与 Flutter 同义）。翻译层把 `InheritedWidget` 加入 SDK 基类表与组件判据，用户子类按常规组件翻译、零宿主注册。
- **运行时继承机制（Flutter 命名）**：结点用 `__inheritedElements`（类型名 → 提供者结点，对应 `Element._inheritedElements`）登记；`__getInheritedElement` / `__dependents` / `__dependencies` / `__notifyClients` 与 `InheritedElement` 的依赖与通知语义一致。`JsBuildContext` 新增 `getInheritedWidgetOfExactType` / `dependOnInheritedWidgetOfExactType`，类型实参沿用 `typeArguments` 元信息。
- **宿主包装类判据修正**：由「原型上是否有自己的 build」改为 Component 构造写入的 `__host`（相对 `Component.prototype.build` 是否重写），继承基类 build 的组件（InheritedWidget 子类）不再被误判为宿主包装类。
- **provider 纯 JS 化**：`ChangeNotifierProvider` 直接返回 child 并在自身结点登记类型键作用域；`Consumer` 直接返回 builder 子树；`context.watch/read` 不再向宿主发 op，取值与订阅全部在 JS 内闭环。
- **删除宿主侧 provider 映射**：`provider_bridge.dart` / `context_ops.dart` 与 `__registerScope` / `__publishScope` 宿主作用域发布机制整体移除；`ChangeNotifier` 宿主镜像保留给 ListenableBuilder 系列。
- **新增示例**：`InheritedCard`（祖先数据共享 + `updateShouldNotify` 精确重建依赖者）。

## 0.7.0

**破坏性：泛型元信息由数组改为 Map（key = 声明侧类型参数名）；新增「类型参数在方法体里可用」的翻译规则（`T == String` / `as T`）。**

- `typeArguments` 形态改为 `{T: 'CounterVm', K: 'String', V: 'int'}`：key 取自类 / 方法的源码声明（`class Pair<K, V>` / `m<T>`），查不到声明时退化为位置序号键。多泛型不再依赖位置顺序，消费方按 key 或 `Object.values(...)[0]` 取。
- 实例保存元信息：泛型类构造把 `typeArguments` 存到内部字段 `__ta`（无参构造 / `__applyProps` 两条路径都覆盖）。
- 方法体里的类型参数：`T` → `this.__ta["T"]`；`T == String` / `!=` 进入「类型值比较」分支，另一侧类型名转字符串（`String` → `"String"`）；`as T` 擦除（类型断言在 JS 侧无运行时语义）。
- 消费方同步：`GlobalKey<T>` 与 provider 的 `watch/read`、作用域登记改取 Map 的第一个值（与 key 写法无关）。
- key 来源：构造按类声明，静态方法按方法声明；调用点定位不到接收者类型时按**方法名**查源码里的泛型方法声明（多个候选时优先 `extension`，仍歧义才退化为位置序号），因此 `context.watch<T>()` / `context.read<T>()` 都是 `{"T": …}`。
- 方法级泛型可用：泛型方法定义侧追加隐藏形参 `__ta` 接收调用尾参对象，方法体里的类型参数（如 `E.toString()`）译成 `((__ta && __ta.typeArguments) || {})["E"]`；`obj.getEType<String>()` 产出 `getEType({typeArguments: {"E": "String"}})`。

## 0.6.0

**只做加法：新增 `flutter.js` 的 `Future` 同名镜像；删除翻译层 `Future.delayed` → Promise 的特判（替换即删除，旧路径不存在）。**

- **翻译层回归一比一**：`await Future.delayed(const Duration(seconds: 1))` 不再被反向映射成 `new Promise(function(r){ setTimeout(r, 1000); })`。`await` 的内层表达式按普通表达式翻译，`Future.delayed` 与其它构造 / 静态调用同一条规则——`Future.delayed({duration: new Duration({seconds: 1})})`（`shared/js_translator.dart` 的 `_awaitInnerJs` / `delayedMsJs` 同次删除）。
- **新增 `export class Future`**（`builders/runtime/js/future_js.dart`，随 `flutter.js` 发布）：构造与 `delayed` / `value` / `error` / `sync` / `microtask` / `wait` / `any`，实例 `then` / `catchError` / `whenComplete`；内部持有一个原生 Promise，`await` / thenable 语义与 Dart 一致（`Future(...)` 异步启动、`Future.sync` 同步启动）。
- **import 自动可见**：`export class` 由导出名自动抽取，产物按实际出现的名字 `import { Future } from '../flutter.js'`，无需登记。
- **宿主通道不变**：`_app_host_.invoke` 仍返回原生 Promise，JS 侧可直接 `await`，与 `Future` 互操作（`then` 兼容 `await` 传入的裸回调与具名实参尾对象）。

## 0.5.0

**破坏性：泛型实参协议统一为 `typeArguments`，删除 `props.model` 与泛型方法的「位置参数」形态（不保留兼容）。**

- **一条规则**：源码里显式写的 `<T,...>` 一律产出 `typeArguments: ['T1', ...]`（按位置顺序、保留源码文本），作为元信息随**构造 props**（值构造与组件结点）或**调用尾参对象**（泛型方法，与具名实参合并）下发。类型实参不再占位置参数。
- **删除语义化键名**：组件结点的 `props.model`（只取第一个类型实参）删除；`Consumer` / `ChangeNotifierProvider` 与 provider 作用域登记改读 `props.typeArguments`。多类型实参（如 `Pair<K, V>`、`Consumer2<A, B>`）不再丢失。
- **删除 provider 专属特判**：`context.watch<T>()` / `context.read<T>()` 不再由翻译层按 `receiver == context` + 方法名特判，统一走泛型方法调用规则（`watch({typeArguments: ['T']})`）；provider.js 的 `watch/read` 改读尾参对象。
- **擦除边界**：泛型方法有位置实参且无具名实参时，尾对象会被目标当成位置实参（如原生 `Array.reduce<T>` 的 initialValue），故擦除元信息并输出构建期告警，与 dart2js 的擦除行为一致。
- **`firstTypeArgOf` 删除**：组件结点与值构造共用唯一解析 `typeArgsOf`。

## 0.4.0

**破坏性：宿主入口 `__jsui.mount` 更名为 `__jsui.mountRoot`（需与 hot_patch 0.3.4 配套；不保留旧别名）。**

- 内部函数一直是 `__mountRoot`（挂载整个页面根），与 reconciler 的 `__mount`（挂载单个结点）区分；此前对外 api 键写成 `mount`，日志与调用链里容易混淆。现统一为 `__jsui.mountRoot(...)`，宿主 `JsUiWidget` 挂载点同步更新。

## 0.3.9

**InputDecoration / BottomNavigationBarItem / DropdownMenuItem 改为值类，删除「数据载体类型表」（协议只做加法：props 里新增 `{type, props, children, element: true}` 元素描述形态，老产物行为不变；需与 hot_patch 0.3.3 配套）。**

- **值对象不再当宿主元素**：这三类不再生成 `extends Component` 的宿主包装类，改为 `flutter.js` 值类区的普通类（构造镜像 Dart 字段 + `toJSON`）——构造即值，留在父级 props，不再进 reconciler 树。
- **新增通用元素描述通道**：运行时新增 `__descriptorOf`（`__element` 元素 → `{type, props, children, element: true}`，数组 / delegate 列表递归，JS 组件、builder 槽与回调值明确告警并丢弃）；值类 `toJSON` 复用它；宿主 renderer 直接读字段 JSON，再用 `c.element(...)` 就地还原成 Flutter widget（无 patch/diff）。
- **删除类型表**：`_dataCarrierTypes` 与 `registerJsDataCarrierType` / `isJsDataCarrierType` 一并删除，生成器 `host_types.dart` 不再扫描数据载体；`hostWrapperTypes` 只剩宿主 widget。三项独立宿主 renderer（`BottomNavigationBarItem` / `DropdownMenuItem`）与 `_JsBottomNavItem` 同步删除。

## 0.3.8

**JS 运行时整理（纯内部重构：`patch/runtime.js` 与 `patch/flutter.js` 同步重出即可，宿主通道与补丁协议字段不变）。**

- **内部符号统一 `__` 前缀**：`emitOp` / `commitOps` / `mount` / `patch` / `unmount` / `registerHandle` / `handleOp` / `markDirty` / `pullComponent` / `scopeOf` / `nodeIdOf` / `keySig` / `objectToken` 等只在框架内使用的函数与状态表（`roots` / `handles` / `hostNodes` …）全部改名，开发者可据此一眼分辨「框架内部」与「对外契约」。
- **日志统一走宿主通道**：删除 runtime.js / flutter.js 中全部 `console.*`，内部诊断改走 `__logText`（warn / error 级别，经 `_app_host_.invoke('log')` 进 `HotPatchLog`）；缓存追踪切面改用 `debugPrint`，release 下零跨桥。
- **合并重复设计**：新增 `__openRoot` / `__closeRoot` 统一「页面根 / 弹层独立根」的建树与卸载事务，`mountRoot` / `disposeRoot` / `Panel.mount` / `Panel.closed` 收敛为薄封装；新增 `__withBuilding` / `__callLifecycle` 收敛 6 处构建锚点与卸载生命周期样板；`ListenableBuilder` / `ValueListenableBuilder` / `AnimatedBuilder` / `TweenAnimationBuilder` 共用 `__ListenableSubscriber`；逻辑组件的 props 摘除统一走 `Component.__propsExcept`。
- **`Component` 内聚**：`__splitHost` 从模块级函数收进 `Component` 静态成员；空无参构造从宿主包装类与逻辑组件中删除（继承默认构造即等价）。
- **删除无用/兼容逻辑**：移除 `newRoot`、`releaseHandleFromHost`、`__isBuilderFn`、`__jsui.fn` / `__jsui.reg`（宿主未使用）、`keySig` 的 `__handle` 兜底，以及 flutter.js 模块级 `G.__str` / `G.objectToken` 单点交接（并入 `G.__core`）。
- **纯内部命名澄清**：`G.__scopeOf`（接收 BuildContext 代理）改名 `G.__scopeOfContext`，与核心 `__scopeOf(instance, type)` 区分；`JsBuildContext` 改回 ES class 写法。
- **翻译层不再判断「是不是回调」**：具名实参一律按**值的形态**字面翻译——闭包 → JS 箭头函数、`Colors.white` → `Colors.white`、方法 tear-off → 绑定 this 的闭包。`autoValue` 删除了「非 builder 闭包内联 body / 下发类引用」的旧分支（它把 `onPressed: () => _a.requestFocus()` 变成**立即调用**、把 `create: (_) => CounterVm()` 变成裸类名）；provider 的 `create` 现在就是普通工厂闭包，provider.js 改为调用 `p.create()`。
- **宿主边界统一生成句柄**：`mini-react` 新增 `__hostProps`，在宿主元素 props 下发前按 `typeof` 把**函数值**换成 `{__fn:id}`（信封只含 id，保证可 JSON 序列化）；句柄缓存在**宿主结点**上、按 prop 名索引——重建复用同一 id 只更新实现（props 不抖动）、兄弟 / 列表项各自独立（天然不串味）、结点卸载随结点释放。回调执行时用 `__core.anchor` 还原产出该元素的组件，`this.context` 与构造期句柄归属语义不变。
- **宿主类型携带函数形参名单**：生成器只为**有回调**的宿主包装类产出 `static __fnProps = [...]`（源码构造签名并集，含类型不可得的形参）；**未声明 = `undefined` = 本类型无回调**（零循环、不拷贝），签名查不到时声明为 `null`。运行时只查名单里的键，`null` / `Component.host` 的字符串类型回退全量扫描——避免为了找回调遍历大 props，同时不会漏掉动态 / 未标注的回调。
- **方法 tear-off 生成精确形参**：`onPressed: _insert` 之前一律产出 `(...__a) => this._insert(...__a)`；现按源码方法声明的位置形参个数生成 `() => this._insert()` / `(__a0) => this._onChanged(__a0)` / `(__a0, __a1) => this._onSelect(__a0, __a1)`，去掉无意义的 rest / spread（含具名形参的方法仍按 `...__a` 原样转发）。闭包字面量本来就按声明形参翻译，不受影响。
- **删除 `__bindFn`**：翻译层不再发射 `this.__bindFn(位点号, [捕获值], …)`，运行时的 `__bindFn` / `__captureKey` / `__boundFn` / 编译期位点号 / `__eventCaptures` / `eventHandle` 一并移除；逻辑组件（LayoutBuilder / SliverPersistentHeader / Draggable / DragTarget）直接下发普通函数，由宿主边界统一折算。
- **构造签名只用于「成员引用怎么渲染」**：`element_json` 仅判断具名形参是否声明为函数类型——函数位置上的 `a.b` 是方法 tear-off（包绑定闭包），普通值位置上是成员读取（原样引用，如 `Colors.white`）；不看属性名、不用 `on*` 约定。`CtorSignatures` 补齐 `super.x` 形参类型（`TextButton` / `ElevatedButton` 的 `required super.onPressed` 沿 `extends` 链取父类字段声明），修复这类构造里回调被当成普通值的问题。
- **JS 侧组件回调**（社区 / 订单列表 `this.onTap` / `this.onOpen is not a function`）：JS 组件 props 不再经过任何句柄化，回调**就是函数**；`functionJs` 在通用闭包翻译失败时回退事件闭包翻译但仍产出普通函数，绝不降级成句柄。


## 0.3.7

**`@HostInjected` 调用点回归一比一：类照常产出 JS，只有被标注方法的**方法体**换成通道调用（产物形态变化，需配套本版本生成器；通道协议与宿主注册不变）。**

- **删除调用点的通道改写**：`AccountCenter.getUserName(a)` / `Network.post(url: u, params: p)` 不再整体替换为 `_app_host_.invoke(...)`，产物保持 `类名.方法(...)`（`AppRouter.pop()` / `Network.post({...})`），事件表达式同理（`static` receiver 落成 `类名.方法(...)` 而非 `this.类名.方法(...)`）。
- **宿主注入类照常翻译**：类表 / 翻译范围 / 跨文件产物不再排除 `@HostInjected` 类；类在产物里只保留「类 + 被标注的 static 方法」，字段、其它方法、基类、依赖与 import 一概不产出（它们只服务宿主实现）。
- **方法体改为通道调用**：新增 `hostMethodBodyJs`，按方法形参结构从 `arguments` 重建载荷——纯位置 → `Array.prototype.slice.call(arguments)`（可选参数缺省不补 `undefined`，宿主默认值照旧生效）；纯具名 → 首个实参对象；混合 → 前 N 个实参 + 尾参对象展开（`{"@args": …}`）。
- **依赖扫描跳过方法体**：`dependenciesOf` 不再遍历 `@HostInjected` 方法的方法体，只有宿主实现里用到的类型不会被连带翻译（`new SearchPage(...)` 等页面依赖链在宿主方法体处断掉）。
- **顶层函数仍是唯一例外**：顶层函数没有可承载的 JS 类，调用点继续翻译为 `_app_host_.invoke(...)`（`buildHostFunctions` 只收集顶层函数名）。
- **删除旧通道表**：`ClassInfo.hostMethods` / `FieldScope.hostMethods` / `ElementTranslateContext.hostMethods` / `buildHostMethods` / `classHasHostInjectedMethod` 全部移除。
- **构建告警降噪（不改产物行为）**：带常量参数的 SDK 枚举（`KeyboardLockMode` / `CheckedState` / `Tristate` 等）不再在索引阶段逐条告警，改为**产物真的引用其成员时**才出声（`sdkUnsupportedEnums` + 翻译层一次性告警）；空事件闭包 `() {}` 视为合法空操作，不再误报「事件闭包块体为空」；字段类型判定先擦除 import 前缀（`ui.Image` → `Image`），不再误报「无法从本地源码解析」。

## 0.3.6

**日志调用回归一比一：`print` / `debugPrint` 原样翻译为同名全局函数（产物调用形态变化，需配套本版本 `runtime.js`；日志通道协议不变）。**

- **删除翻译层的日志特殊分支**：不再把 `print` → `console.log`、`debugPrint` → `console.debug`，改为按通用「运行时全局函数」分支一比一产出 `print(...)` / `debugPrint(...)`（含 `wrapWidth` 具名实参的统一信封）。
- **运行时【1】新增日志全局**：`G.print`（`info` 级）、`G.debugPrint`（`debug` 级），统一经 `_app_host_.invoke('log', …)` 进 `HotPatchLog`；release 下 `__log` 直接返回，零跨桥。
- **删除运行时对 `console` 的整套封装**（`G.console` 合并覆盖与级别映射、`__silentLog`）：运行时内部诊断改用引擎自带的 `console`（flutter_js 桥到本地打印）。
- **字符串插值不再借日志分支包 `__str`**：插值统一按 `+` 拼接；`__str` 只保留给值类（`StringBuffer` 等）使用。

## 0.3.5

**Canvas 能力新增文字与图片记录（只做加法：新增值类与 op，既有语法产物不变；使用 `TextPainter` / `drawImage*` 需 `hot_patch` ≥ 0.3.2）。**

- **`TextPainter`**（`canvas_js.dart`，插在 `Canvas` 与 `CustomPainter` 之间）：构造实参按原名保存；`layout(minWidth, maxWidth)` 兼容位置与尾参对象两种形态，`Infinity` 序列化为 null（宿主按 Dart 默认值 `minWidth 0` / `maxWidth infinity`）；`paint(canvas, offset)` 记录 `['drawText', span, offset, opts]`。`width` / `height` / `size` 需要同步测量，JS 侧访问即抛错（不返回假值）。
- **`Canvas.drawImage` / `Canvas.drawImageRect`**：由抛错桩改为记录（`image` 是宿主返回值里的图片句柄 `{__handle, width, height}`，null 时抛错）；`drawImageNine` / `drawAtlas` / `drawVertices` / `drawPoints` / `drawParagraph` 等仍抛错。
- **旋转由矩阵承接**：文字 / 图片的旋转沿用既有 `save` / `translate` / `rotate` 产物形态，不新增协议分支。
- **dart:core 值类补齐**（`dart_core_js.dart`，紧随基础值类之后）：新增 `DateTime` / `Match` / `RegExp` / `StringBuffer`，以及小写静态命名空间 `int` / `double` / `num`（`parse` / `tryParse` / `infinity` 等）。构造仍按唯一规则产出 `new X({...})`、静态调用 `int.parse(...)` 原样下发；翻译层只新增「小写导出名 → 命名空间」的通用解析分支（`runtime_global_types` 从 `export const <小写名> = {` 自动抽取），不维护类型白名单。

## 0.3.4

**新增 CustomPaint / CustomPainter 绘制支持（只做加法：新协议键与句柄 kind 均为新增，老产物行为不变，仍可与 `hot_patch` 0.3.0 搭配；使用 CustomPaint 需 `hot_patch` ≥ 0.3.1）。**

- **值类（`patch/flutter.js`）**：新增 `Rect` / `RRect` / `Path` / `Paint` / `Canvas` / `CustomPainter`（`builders/runtime/js/canvas_js.dart`，插在 Dart 值类之后、异常之前）。`Canvas` 是**录制型**：每次调用压入一条 `[方法名, …实参]`，`toJSON()` 产出 `{v:1, ops:[…]}`；`Rect → [l,t,r,b]`、`RRect → 12 项`、`Path → {ops}`、`Paint → 非空属性`。
- **`CustomPainter` 是值类 + 句柄**（kind `canvasPainter`，`sync:false`）：宿主不创建真实对象，只用 `__jsui.call(id, 'call', {method:'__record', args:[size]})` 同步取回录制结果。宿主侧重放与还原见 `hot_patch` 的 `capabilities/canvas/`。
- **`Gradient.createShader(rect)`**：下发 `{__gradient, rect}`，供 `Paint.shader` 跨桥还原。
- **SDK 基类表**新增 `CustomPainter`：`class X extends CustomPainter` 产物为 `extends CustomPainter` + `constructor(args){ super(args); }`。
- **私有依赖分类改为源码事实**：`component_builder` 不再用 `_` 前缀推断「是不是组件」，改为 `isWidgetClassDecl`（`extends StatefulWidget/StatelessWidget/State` 或 `@PatchEntry`）。私有非 widget 类（如 `_XxxPainter extends CustomPainter`、`_XxxDelegate`）按普通类翻译并保留 `extends`，修复私有 painter 丢失基类能力的问题。
- **不支持项出声**：`drawImage*` / `drawParagraph` / `drawPicture` / `drawShadow` / `drawPoints` / `drawColor` / `toImage*` / `getTransform` 等在 JS 侧直接抛错；未知绘制指令、Paint 属性、Path 指令由宿主 `HotPatchLog.error`。

## 0.3.3

**产物按归属拆分（协议不变：补丁通道 / patch ops / 句柄信封一致，可与 `hot_patch` 0.3.0 搭配）。**

- `runtime.js` 只留语言层 + mini-react 核心 + 通用缝（作用域查找 / BuildContext 代理 / 独立根挂载 / 宿主桥），不再含任何库或 Flutter SDK 的 API 面。
- provider 的自有登记（`registerScope('ChangeNotifierProvider')` + `JsBuildContext.prototype.watch/read`）移进它的**包模块** `patch/provider.js`（生成器 `provider_module_js.dart`，由 `widget_module_builder` 的 `_packageModuleEpilogues` 追加）；`context.watch/read` 的对齐结论不变。
- `showDialog` 系列（dialog / adaptive / general / cupertino / sheet / cupertinoSheet）连同面板独立根机制（`openPanel` / `panelMount` / `panelClosed` / `panelPop` / `panelOf`）与 `Navigator` 移到 `patch/flutter.js`（`dialogs_js.dart` / `navigator_js.dart`），从 `export function` 导出：产物按名 import 后裸调用，与 Dart 一比一。`__jsui.panelMount` / `panelClosed` 由该模块求值时安装（宿主调用点已有存在性守卫）。
- `G.__core` 交接面补齐：作用域机制、结点归属、独立根 mount/unmount/commit，以及 `building` / `activeRoot` 的访问器（闭包 var 必须实时读写）。
- **命名构造改为 1:1 发射**：翻译层不再往 `props` 写 `factory`，而是把构造名作为结点中间态（`ctor`）只用于发射 `X.b({...})`（`SizedBox.shrink(...)` / `Image.network(...)` / `ListView.separated(...)` / `ChangeNotifierProvider.value(...)`）。JS 没有 Dart 的命名构造，故 `flutter.js` 的包装类与逻辑组件对每个源码构造名生成**同名静态方法**，由静态方法把构造名写进 `props.factory`——宿主仍只按 `props.factory` 选原生工厂，协议不变。
- 宿主补齐此前「静态方法写了 `factory` 但 renderer 没消费」的构造：`SizedBox.shrink/expand/square/fromSize`、`Positioned.fill/directional`、`Transform.rotate/scale/flip`、`Card.filled/outlined`、`Visibility.maintain`、`SliverVisibility.maintain`、`Text.rich`、`IconButton.filled/filledTonal/outlined`、`FloatingActionButton.extended/large/small`、`ElevatedButton/TextButton/OutlinedButton/FilledButton.icon/tonal/tonalIcon`、`Dialog.fullscreen`、`AlertDialog.adaptive`、`TabBar.secondary`、`SliverAppBar.large/medium`、`SliverGrid.count/extent`、`SliverFixedExtentList.builder`。
- **删除生成器里的静态工厂硬编码表**（原 `_wrapperStaticFactories = {'styleFrom': 'ButtonStyle'}`）：它不按类型生效，会给每个包装类（含 `@PatchIgnore` 的 `_LabeledDivider`）都生成 `static styleFrom`。改为源码事实驱动——`CtorSignatures.staticMethodsOf(type)` 返回**返回类型是镜像值类**的静态方法（`ElevatedButton.styleFrom` → `static styleFrom(props) { return new ButtonStyle(props); }`），并排除形参含 `BuildContext`（`X.of(context)` / `Divider.createBorderSide(context, …)`）与私有方法。
- 逻辑组件的命名构造静态方法改为**类体内的 `static`**（`ChangeNotifierProvider` 的 `static value(props)`），不再生成类外赋值 `X.name = function…`；`_LabeledDivider` 一类包装类不会再出现无主的静态转发。
- `TextStyle` / `ButtonStyle` 去掉 `__pos` / `factory` 过滤：二者构造参数全为具名参、无命名构造，产物不可能下发这些协议键，直接按原名拷贝。
- 结点判定去掉结构猜测（原 `_isNodeMap` 按「`type` 是带引号字符串 + 键集合白名单」猜）：结点 Map 由 `elementToJson` 统一打内部标记 `__node`，渲染层只认标记，props 里 `Foo(type: …)` 这类普通容器不再可能被误判。

## 0.3.2

**删除 `runtime.js` 里的无效设计与恒真探测（行为不变）。**

- 删除 `G.__posArgs` 全局导出：该函数只被运行时内部的值类（Color / Duration / Key / 异常）使用，产物与 Dart 侧都不引用它。
- 删除 13 处 `typeof console !== 'undefined' &&` 与 13 处 `if (console.error/warn)` 真值守卫：`console` 在【1】无条件定义，release 下五个方法都是空函数；守卫恒真，等于白读一层。
- `__log` 去掉 `_app_host_` 存在性探测：它在 IIFE 收尾赋值，console 只可能被之后的页面代码调用。
- `capKey` 去掉 `WeakMap` 降级分支：QuickJS 必有 `WeakMap`。
- `requestFlush` 的三重探测收敛为「有宿主桥 / 无宿主桥（纯 JS 单测）」两条。
- 修正 `hot_patch` 侧 `js_leak_snapshot.dart` 的过时说明（原写「release 下 JS 产物不含 leakSnapshot」，实际产物对 debug/release 是同一份，靠调用点门控）。
- **保留**并确认为扩展契约、非死代码：`__jsui.h / fn / reg / Component`（外部能力库的入口，见 `js_ui_library.dart` 的说明）、`sendMessage` 存在性判断（纯 JS 环境兜底）、`Array/String/Number.prototype` 的「已存在则跳过」守卫（同一 JS 上下文重复求值 runtime 时的保护）。

## 0.3.1

**`runtime.js` 性能与可维护性修复（产物协议不变，可与 `hot_patch` 0.3.0 搭配）。**

- **release 下 console 完全静默**：`debug` / `info` / `log` / `warn` / `error` 在 `!kDebugMode` 时全部替换成同一个空函数，**一次都不跨桥**（原实现除 `debug` 外仍会走 `_app_host_.invoke`，每次日志都要格式化 + JSON 编码 + 桥消息 + Promise）。
- **keyed diff 从 O(n²) 降到 O(n)**：`patchChildren` / `patchSlotList` 的匹配逻辑抽成唯一的 `keyedMatcher`（一次建索引 + 无 key 游标 + `__id` 定位），去掉了逐项线性扫 `remaining`、`splice` 搬移与 `indexOf` 判移动，也消除了两份重复实现。
- **`eq` 降分配**：每层从两次 `Object.keys` 降为一次（另一侧用 `for-in` 计数），数组先比长度短路。
- **修 `capKey` 的类型撞车**：原始捕获值改为 `typeof + ':' + String(v)`——数字 `1` 与字符串 `'1'`、`null` / `undefined` / `''` 不再生成同一 key（否则不同捕获值的事件闭包会互相覆盖）。
- **修 `keySig` 的兜底撞车**：认不出的 key 对象改用引用身份 token，不再 `String(k)`（后者会把所有对象压成 `[object Object]`，导致不同 key 复用同一结点）。
- **生命周期异常不再静默**：`deactivate` / `dispose` 抛错时记 `console.error`（release 下即空操作）。
- **文档与注释去重**：删掉各片段内残留的旧分区标题（与产物头部的【n】编号冲突、且 `1b` / `1c` / `10.x` 混排），分区改为严格顺序 1..25；`runtime.js` 顶部同时注明 console 的 release 语义。

## 0.3.0

**新增动画支持；JS 运行时改由生成器产出（运行时需同步升级到 `hot_patch` 0.3.0）。**

- **新增 `ui_runtime` builder**：把 JS 运行时（mini-react / 句柄表 / 各能力片段）拼成**一个** `patch/runtime.js`（分区注释 `// ===== 【n】标题 =====`），运行时包不再内嵌任何 JS——JS 修复只需重出产物，无需发版。产物头部的版本号取内容哈希（FNV-1a），哈希变化即触发运行时原地重建。
- **宿主类型清单自动抽取**：删除手工维护的 `builtinWidgetTypes` / `jsDataCarrierTypes`，改为构建期扫描 `hot_patch/lib/src/js_ui/**` 的 `r.register('X', …)` 与 `_dataCarrierTypes`——新增宿主组件只改运行时注册一行，生成器零登记、两端不再需要人工同步。
- **清单新增 `protocol`**：`patchProtocolVersion = '1.0'` 写入 `patch/manifest.json`；主版本变化表示产物与宿主 Dart 的契约（`__h` / `element` / `__delegate` / 句柄信封 / 颜色序列化）有破坏性改动，次版本只做加法。
- **修复 `PackageSources` 的 `rootUri` 解析基准**：改为相对 `package_config.json` 自身（pub 规范）。此前在工作区里会多退一级，导致依赖包与项目自身的构造签名、类索引全部定位不到。
- **登记动画组件类型**：宿主类型清单追加 `AnimatedContainer` / `AnimatedOpacity` / `AnimatedPadding` / `AnimatedAlign` / `AnimatedScale` / `AnimatedRotation` / `AnimatedSlide` / `AnimatedSize` / `AnimatedSwitcher` / `AnimatedCrossFade` / `AnimatedDefaultTextStyle` / `AnimatedPositioned` / `FadeTransition` / `ScaleTransition` / `RotationTransition` / `SizeTransition`（现由运行时注册自动派生）。
- **`AnimatedBuilder` 作为逻辑组件**（`logicWidgetTypes`）：`builder` 闭包抽成组件方法，产物只下发方法名，逐帧重建只发生在该子树。
- **动画值 / 控制器的翻译**：`Duration` 归入命名实参的 JS 运行时代理（`new Duration({milliseconds: n})`）；`AnimationController` / `CurvedAnimation` 同样按 JS 同名代理类构造；`Tween` / `CurvedAnimation` 作为值对象只在 JS 侧推导 `value`。
- **枚举成员名口径**：`Curves.easeOut` / `CrossFadeState.showFirst` 继续按成员名字符串下发（与既有枚举翻译一致），运行时按名字还原真实对象。

## 0.2.3

**统一 widget 构造协议：宿主包装类 + 翻译统一 `new`（运行时需同步升级到 `hot_patch` 0.2.2）。**

- **宿主包装类**：`patch/flutter.js` 为 `builtinWidgetTypes` 中的宿主 widget（`Text` / `Column` / `Scaffold` …）与数据载体（`InputDecoration`）生成同名包装类——`class Text { constructor(props) { return __h('Text', props); } }`。宿主元素 type 仍是类型名字符串，reconciler 从不 `new` 这些包装类。
- **翻译统一发射 `new Type(props)`**：宿主包装类、自定义组件、逻辑组件、builder 代理一律 `new`；只有无 JS 类的类型（无产物自定义组件 / 原生注入）保留 `__h('Type', props)` 兜底。
- **组件类构造即实例**：删除构造函数内部 token / 双模分支，组件类首行保留 `this.props = args`，字段初始化照常写在构造里；实例随元素下发（`__asElement` 的 `inst`），由运行时 mount 复用，不再二次构造。
- **局部值翻译去掉 widget 白名单**：`widgetValueJs` 只排除已知模型类（classTable 的 `!isComponent`）与值对象 / 结构化样式，其余类构造一律按元素翻译；`widgetClassNames` 字段删除。
- **字段 / 依赖判定不再依赖 `builtinWidgetTypes`**：能解析到的类直接放行；解析不到的类型按宿主 Widget 值处理并输出构建期告警。该表现在只用于生成宿主包装类与决定 import 类名。
- **产物兼容边界**：旧产物在新运行时可用；新产物需要 `hot_patch` 0.2.2 的 `__asElement` 与宿主包装类，按整包更新补丁。

## 0.2.2

**builder 形态与事件目标的判定统一为产物协议；产物仅局部变化。**

- **`usesJsClass` 只认 `factory`**：只有 `builder` / `separated` 命名构造才走 JS 代理类，删除「props 里出现 `builder` / `*Builder` 键」的猜测。顺带修正 `GridView.count` / `.extent` 等普通工厂被误判为代理形态的问题。
- **`builderFormTypes` 校正**：补入 `PageView`（`.builder` 与 ListView 同机制）；移除没有 `.builder` / `.separated` 构造的 `SliverFixedExtentList` / `SliverFillViewport`（它们仍走 delegate 宿主节点）。
- **代理类精简**：命名构造代理只读 `itemBuilder` / `separatorBuilder` / `itemCount`；delegate 形态不再经过代理类。
- **事件目标判定不再依赖内建类型表**：按「有 JS 产物 / 逻辑组件 → 可调用闭包；builder 代理与宿主 → 事件句柄」判定，自定义组件无需维护清单。
- **共享与清理**：`isClassName` 收敛为一处；删除未使用的 `WidgetNode.factory`、`listArg`、`propOf`、`propExpr`、`borderRadiusExpr` 等。

## 0.2.1

- **所有 Dart 实参按原名进 props**（含 `child` / `children` / `slivers` / `tabs`），生成代码不再向 `__h` 传第三参；元素工厂 `__h` 按元素 `type` 拆分：宿主字符串类型把标准结构键抽成 `element.children` 并从 props 剥离，JS 组件类保留全部 props 供 `__applyProps`（修复自定义组件 `child` / `children` 构造参数拿不到值的问题）。`delegate:` 仍归一为 `props.children` 或 `builder` / `childCount`。
- 删除位置实参的下标键兜底：不再生成 `props['$pos']`；未在 `widgetPositionalArgNames` 登记形参名的类型遇到位置实参时，构建期告警并丢弃，避免出现没有语义的下标约定。
- 清理过时文档与提示语：翻译失败提示中的 `@UIProp` 残留改为「组件状态字段（@PatchEntry 组件的实例字段）」；`build.yaml` 里对已删除 translator 注册表的引用改为 `registeredWidgetPackages()`。

## 0.2.0

**翻译内核重构：去掉 per-widget 的 `WidgetTranslator`，改为统一翻译；产物协议随之变更（运行时需同步升级到 `hot_patch` 0.2.0）。**

- **统一翻译入口**：`widget_json.dart` 按**通用参数名**（`child` / `children` / `slivers` / `tabs` / `on*` / `delegate`）+ `value_forms.dart` 按**值的形态**（字面量 / 构造 / 静态工厂 / 常量引用 / 列表 / 闭包）分派；内建、自定义、三方组件同一套规则，**接入新组件零实现**。删除 `WidgetTranslator` / `WidgetTranslatorRegistry` / `UnregisteredWidgetTranslator` 与 `builtin_translators.dart`。
- **位置实参按 Flutter 声明的形参名下发**：`Text('hi')` → `{data: 'hi'}`、`Icon(Icons.star)` → `{icon: 'star'}`、`Image.network(url)` → `{src: url}`；未登记的类型退回 `$pos` 下标数组（登记表见 `js_widget_defs.dart` 的 `widgetPositionalArgNames`）。
- **命名构造 / 静态工厂名进产物**：`{factory: 'builder' | 'separated' | 'network' | 'value', ...}`——同类型不同工厂**同 `type`、不同 `factory`**，运行时据此挑选原生 / JS 工厂（不再靠「有没有某个键」猜形态）。
- **枚举引用 → 成员名字符串**：`Axis.horizontal` → `"horizontal"`、`BottomNavigationBarType.fixed` → `"fixed"`（JS 侧没有枚举，裸标识符会让整个组件挂载失败）。
- **`on*` 回调按目标类型分流**：宿主 widget 下发事件句柄 `{__fn:id}`；组件（自定义 / 私有 / `@PatchEntry` 子组件）下发**可调用闭包**（子组件直接 `this.onXxx(...)` 调用，不再报 `is not a function`）。
- **事件统一为构建期箭头闭包**：所有事件（方法引用 / 字段回调 / 箭头闭包 / 块体闭包）统一产出 `this.__bindFn(位点号, [捕获值], (...a) => …)`；闭包天然捕获 build 局部变量 / 循环变量，与 Dart 闭包同语义。删除 `this.__bind("表达式")` 字符串求值路径（`new Function` 丢失构建期作用域，`onPressed: () => model.inc()` 会静默失效）。位点号为编译期稳定编号，捕获值按「对象引用身份 / 原始值」比较，重建后句柄 id 稳定、循环项互不串味（同时修复方法形参未进 key 的碰撞缺陷）。**不再**为特定写法做 `context.read("T")` 之类的按名改写。
- **颜色编译期算值**：`Color(...)` / `Colors.*` / `Colors.*.shade*`（含 `*Accent` 的 100/200/400/700）→ `#RRGGBB` / `#AARRGGBB`；产物里不再出现 `@Colors…` 标记（色板数据取自 Flutter SDK 的 Material 色板，运行时无需色板分支）。
- **结构化值不再变成结点**：`gridDelegate`（`SliverGridDelegateWith*`）等转为 JSON 值下发，避免运行时读不到参数（GridView / SliverGrid 退化成单列）。
- **修复 `MultiProvider` 子结点丢失**：生成产物把 `child:` 放进元素 children，而 JS 模板只读 `props.child`，导致 providers 包住 `undefined`、整段子树静默消失（卡片只剩空壳）；模板现在同时读取 `children[0]`。
- **`ReorderableListView.builder` 支持**：登记进 `builderFormTypes`，`itemBuilder` / `itemCount` 与 ListView.builder 同一套「闭包抽方法 + 代理类展开子树」机制，宿主还原原生命名构造；`scrollController` 参数按 Flutter 形参名原样下发。

## 0.1.1

- 补充 `repository` 字段，修复 pana 仓库校验失败导致的 pub.dev 页面无 GitHub 地址。
- `description` 改为英文，满足 pub.dev 对英文描述的要求（中文描述会被 pana 扣分）。
- README 提供中英双语，顶部可切换。

## 0.1.0

- 首个版本。
- 把带 `@PatchEntry` 注解的 Flutter widget 静态翻译为与 Dart 源文件同名的 JS 模块
  （`analyzer` 静态解析，不执行任何 Dart 代码）。
- 产物按文件内容分流：组件产物 / 普通类与静态单例产物；都不含则不产出。
- package 级 widget 工厂模块：**一个 package 一个文件**（`patch/flutter.js`、
  `patch/provider.js`），共享结点工厂 `__h` 全局只定义一次。
- 事件绑定在构建期注入，归属与 Dart tear-off 语义一致。
- 内置 widget 策略注册表；新增 / 自定义 widget 只需实现 `WidgetTranslator` 并注册，核心代码零改动。
- package 级模块与 patch 清单都挂在包根伪资产 `$package$` 下，使用方无需种子文件或额外配置。