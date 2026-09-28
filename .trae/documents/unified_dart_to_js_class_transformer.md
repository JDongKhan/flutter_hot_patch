# 统一「Dart 类 → JS 类」转换处理器 + End-to-End 支持

## Context（为什么做）

flutter 热更新项目（`/Users/jd/Documents/Developer/flutter_hot`），生成器 `ui_component_generator` 把 `@UIComponent` 组件静态翻译成 JS 产物。当前有一个错误的架构倾向：**按类「用途」分流处理**——value object（User，`_collectModels` 扫 `User(...)` 构造）走一个路径、静态单例（PanelColors，`_isSingletonClass`）走另一个路径、挂在 State 字段的对象（`CounterModel _model`）完全不转（被当「不可翻译对象字段」跳过）。

用户明确纠偏：**User、静态单例、CounterModel 是同一类问题**。不做 Dart 类→JS 类时不要关心类是用来干啥的，只按「如何声明 + 如何被 State 字段/构建/方法引用」处理。故在 `ui_component_generator` 下封装**统一「Dart 类 → JS 类」处理器**，并端到端让 `lib/components/listenable_demo.dart` 可生成不崩的 JS、`_model` 持久、CounterModel 方法体非空、ListenableBuilder 子树被翻译、notifyListeners 触发局部重建。

物理前提已确认：运行时 `HotPatchWidgetState._boot` 对同一 JS 实例（`__instances[key]`）创建一次、`rebuild()` 反复调其 `build()`，故 State 字段 `_model` 跨 build 天然持久。generator 只是从不翻译它。

## 现状根因（已核实）

1. `listenable_demo.component.js` L5 bad import：`importResolver`/`_resolveImportProduct` 的 `package:` 分支只跳过 `package:flutter/`，把 SDK 未注册类 `ListenableBuilder` 兜底成跨文件组件，误 import 不存在的 `../ui_component.component.js`。
2. `_inc()/_reset()` 空方法体：`_collectModels` 只扫方法体/build 的 `InstanceCreationExpression`，不扫**字段初始化器** `CounterModel _model = CounterModel()`；`_model` 字段非 basic 非 model 被 skip；`_translateStateExpr` 对 `_model.inc()`（对象方法调用）返回 null 被丢。
3. `ListenableBuilder` 子树丢失：走 Component 兜底只输出 `{"component":"ListenableBuilder"}`，builder 回调 `Text('n = ${_model.n}')` 整体丢。

## 核心文件

- `packages/ui_component_generator/lib/class_translator.dart`（**新增**，统一处理器）
- `packages/ui_component_generator/lib/builder.dart`（类发现 / 字段 / 方法 / 产物组装接入）
- `packages/ui_component_generator/lib/widget_translator.dart`（`FieldScope` 抽象、LB 计数/收集）
- `packages/ui_component_generator/lib/builtin_translators.dart`（`ListenableBuilderTranslator`）
- `packages/hot_patch/lib/src/services/js_runtime_manager.dart`（注入 `NotifierBase`）
- `packages/hot_patch/lib/src/widgets/widget_renderer.dart` / `builtin_renderers.dart`（`registerLb` 透传 + `_JsListenableBuilder`）
- `packages/hot_patch/lib/src/hot_patch_widget.dart`（`registerLb/rebuildLb` + `lbNotify` 内部服务）

## 分步实施

### 1. 统一处理器 `class_translator.dart`（纯新增，不动老逻辑）
- `DartClassInfo`：`name`、`sourceFile`、`isStaticOnly`、`extendsType`、`instanceFields`(name/type/hasInit/initExpr)、`staticFields`、`methods`(含 getter)、`ctorParams`。`classInfoOf(decl, sourceFile)` 提取。
- `FieldScope` 抽象 `Identifier → JS 引用`：把现有 builder 的 `propByField`/`extraVars` 归一。现有 `_translateExprStatement/_translateStateExpr/_rhsJs/_modelCtorJs` 改为以 `FieldScope` 为参数复用（字段→`this.x`，形参/静态→原样）。这样模型方法（字段表=模型自身字段）与组件动作（字段表=State 字段）共用同一翻译器。
- 三种 JS 渲染（按 `isStaticOnly` 分流产物形态，不按用途）：`renderExportClass`（value object/状态对象）、`renderInlineClass`（同文件）、`renderStaticConst`（纯 static → `const X={...}`）。
- 补缺失翻译规则：
  - 裸方法调用 `MethodInvocation(target==null)` 且 method ∈ MethodScope → `this.<m>(args);`（模型的 `notifyListeners()`）。
  - 对象方法调用 `MethodInvocation(target==模型字段)` → `this.<field>.<m>(args);`（组件的 `_model.inc()`）。
  - getter 成员保留（模型类 `int get n=>_n` → `get n(){return this._n;}`，区别于 State 的 `_skipMethod`）。
  - `extends ChangeNotifier` → 产出 `class CounterModel extends NotifierBase {...}`，不翻译基类。
  - 用 MethodScope 显式白名单收紧裸调用规则，避免把 bench 等裸调用误翻成 `this.xxx()`。

### 2. 运行时注入 `NotifierBase`（js_runtime_manager.dart）
- 在模块初始化块（`if (typeof __modules...)` 处）追加全局 JS 基类：
  ```js
  function NotifierBase(){ this._listeners=[]; }
  NotifierBase.prototype.addListener=function(f){this._listeners.push(f);};
  NotifierBase.prototype.removeListener=function(f){var i=this._listeners.indexOf(f);if(i>=0)this._listeners.splice(i,1);};
  NotifierBase.prototype.notifyListeners=function(){this._listeners.slice().forEach(function(f){f();});};
  ```

### 3. 类发现统一（builder.dart，替换 `_collectModels` + 单例两路）
- 设 `_ClassIndex`：解析「同文件非 private 非 @UIComponent 非 widget 类」+「import 文件里类」→ 全部 `DartClassInfo`，得 `Map<类名, DartClassInfo>`。
- 发现（用户已选 State 为主 + 构造兜底，并集）：
  - 第一来源：State/嵌套组件**实例字段**声明类型命中 index（`User?` 去 `?`）→ 进模型/单例集。
  - 第二来源：方法体+build 树 `InstanceCreationExpression` 构造名命中 index → 进模型集（保 hello 的 `User(...)` 链路）。
- 删 `_collectModels/_isModelType/_modelJsClass/_isSingletonClass/_findSingletonClasses/_buildSingletonResolver`，改由 `_ClassIndex` 派生。
- 字段收集联动：`_isBasicType` → 基础初始值；`index.containsKey(type)` → `isStaticOnly ? 'null' : 'new $T({})'`；有初始化器 `CounterModel()` → `this._model = new CounterModel({})`；`User? _user` 无初始化 → `this._user = null`；其余（Controller/Widget/Key）跳过。字段一律进 JS 实例属性 → 跨 build 持久。

### 4. ListenableBuilder 翻译（生成器侧）
- `builtin_translators.dart` 新增 `ListenableBuilderTranslator` 并 register：
  - `toJson`：从 `ctx` 取自增 `id`；`builder` 是 `FunctionExpression`，取其返回表达式 `Text('n = ${_model.n}')` 用 `ctx.translate(...)` 翻成子树 JSON 进 `children`；`listenable`（`_model`）引用存 `ctx.lbSpecs`。
  - 覆写 `renderJs`：输出 `{ "type":"ListenableBuilder", "props":{"id":N}, "children": this._lbBuilderN()["children"] }`，子树由生成的 `_lbBuilderN()` 方法产出（唯一事实源，build 不重复内联）。
- `_Component` 增 `lbSpecs`；`_translateBuildTree` 返回 `(tree, deps, lbSpecs)`；`_renderJs` 对带 LB 组件追加生成：
  ```js
  _wireListenables(){ if(this.__lbWired)return; this.__lbWired=true; var self=this;
    (function(subM,id){ if(subM&&typeof subM.addListener==='function'){
      subM.addListener(function(){ sendMessage("lbNotify", JSON.stringify({ key:self._key, id:id,
        tree: JSON.stringify(self["_lbBuilder"+id]()) })); });
    }; })(this._model, 0); }
  _lbBuilder0(){ return { "type":"Text", "props":{ "data":"n = "+this._model.n } }; }
  ```
  `build()` 首行前置 `this._wireListenables();`。
- importResolver 护栏：`_resolveImportProduct` 的 `package:` 分支追加跳过 `package:ui_component/` 与 `package:ui_component_generator/`；更稳的语义修复为「解析文件里无同名 export class 的名字返回 null（走 native 注入）」。

### 5. 运行时局部重建（hot_patch 侧）
- `widget_renderer.dart`：`WidgetRenderContext` 加可选 `registerLb(int id, void Function(Object?) cb)?` 并透传。
- `builtin_renderers.dart`：注册 `ListenableBuilderRenderer(type:'ListenableBuilder')`，返回自管理 `_JsListenableBuilder` StatefulWidget——init 取子树 `_tree`、`ctx.registerLb(props['id'], (t)=>setState(()=>_tree=t))`；dispose 注销；build 用本地 `ListenableBuilder(listenable: 本地 _notifier, builder:(_,__)=>ctx.render(_tree))`。
- `hot_patch_widget.dart`：持 `Map<int, void Function(Object?)> _lbSetters`；`registerLb`/`rebuildLb(id, tree)`（String→jsonDecode→Map）；build 构造 `WidgetRenderContext` 传 `registerLb`；`_internalServices` 加 `_LbNotifyService`（channel='lbNotify'，handle 读 id/tree → `state?.rebuildLb`）。
- `builtin_services.dart`：实现 `_LbNotifyService extends InstanceNativeService`，handle 调 `state?.rebuildLb(id, tree)`。

### 6. 端到端验证入口（可选）
- `lib/main.dart` 加 `_DemoEntry('ListenableDemo · 局部重建', HotPatchWidget(jsAsset:'assets/components/components/listenable_demo.component.js', component:'ListenableDemo'))`，点按 `+1`/`Reset` 看局部 `n = N` 变化。

## 预期产物要点

**listenable_demo.component.js**：
- 顶部**无** `import { ListenableBuilder } from '../ui_component.component.js';`。
- inline `class CounterModel extends NotifierBase`，`constructor(args){ super(); this._n=0; }`、`get n(){return this._n;}`、`inc(){ this._n+=1; this.notifyListeners(); }`、`reset(){...}` 非空。
- `ListenableDemo`: `constructor(){ this._model = new CounterModel({}); }`、`_inc(){ this._model.inc(); }`、`_reset(){ this._model.reset(); }`。
- `_lbBuilder0(){... data:"n = "+this._model.n }`、`_wireListenables(){...}`、`build(){ this._wireListenables(); return {... "children": this._lbBuilder0()["children"] ...}; }`。

**hello_component.component.js** 不回归：User `import ../model/user.model.js` + `new User({name:"Alice",age:18})`、PanelColors inline `const` 保持。

## 风险点

- **最险**：`children: this._lbBuilder0()["children"]` 是 JS 对象字面量里的表达式求值，需确认 `build()` 的 `JSON.stringify` 能正确序列化。若不行，退路是 `_lbBuilder0()` 后置、build 中子树重复内联一次。
- `NotifierBase` 的 `addListener` 必须在订阅闭包前定义；当前 demo `_model` 构造即建，无碍；模型被替换场景的重订阅留后续。
- 裸调用规则用 MethodScope 白名单收紧，防误翻。
- importResolver 护栏只对「解析文件无同名 export class」返回 null，谨慎合并，防覆盖真实跨文件组件。

## 验证

1. `dart run build_runner build` 每次改后跑，确认无报错/无 FormatException。
2. `dart analyze`（库根 packages/ 各包）通过。
3. 人工检查 `assets/components/components/listenable_demo.component.js` 满足「预期产物要点」；检查 `assets/components/components/hello_component.component.js` 无 User/PanelColors 回归。
4. iOS 实跑（用户自验）：`ListenableDemo` 点 `+1`/`Reset` 局部更新 `n = N`。