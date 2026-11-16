// 三方库 JS（宿主维护）：waterfall_flow
//
// 生成器不生成该模块 —— `waterfall_flow` 来自三方包，不是运行时内建能力：
// JS 类由本工程维护在 `js/waterfall_flow.js`，构建时由 `ui_third_party_js`
// 原样拷贝到 `patch/packages/waterfall_flow.js`。文件名即 Dart 包名
// （`js/waterfall_flow.js` ↔ `package:waterfall_flow`），业务产物按
// `import { WaterfallFlow, ... } from '<...>/packages/waterfall_flow.js'` 取用；
// 它**不会**进 `flutter.js`（框架产物只承载内建宿主组件）。
//
// 布局 / 渲染 / 滚动全在宿主包内，宿主桥接见
// `example/lib/custom/waterfall_flow/waterfall_flow_bridge.dart`。
//
// 属性透传：props 由 Component 原样下发，除函数形参外不需要在类里逐个声明；
// 本组件没有函数形参（`__fnProps` 为空）。
import { Component } from '../flutter.js';

// ===== 布局 delegate（值对象）=====
//
// Dart 侧是 const 构造，翻译层按统一规则原样发射
// `new SliverWaterfallFlowDelegateWithMaxCrossAxisExtent({...})`；跨桥时按普通
// 对象序列化成 `{maxCrossAxisExtent, mainAxisSpacing, ...}`。
// `kind` 是**宿主还原真实 delegate** 的类型标记（与 gradient / 句柄信封的
// `kind` 同一口径）：值对象本身没有方法，跨桥只剩字段，宿主必须能判别是哪一种 delegate。
export class SliverWaterfallFlowDelegateWithFixedCrossAxisCount {
  constructor(props) {
    props = props || {};
    this.kind = 'fixedCrossAxisCount';
    this.crossAxisCount = props.crossAxisCount;
    this.mainAxisSpacing = props.mainAxisSpacing;
    this.crossAxisSpacing = props.crossAxisSpacing;
    this.closeToTrailing = props.closeToTrailing;
  }
}

export class SliverWaterfallFlowDelegateWithMaxCrossAxisExtent {
  constructor(props) {
    props = props || {};
    this.kind = 'maxCrossAxisExtent';
    this.maxCrossAxisExtent = props.maxCrossAxisExtent;
    this.mainAxisSpacing = props.mainAxisSpacing;
    this.crossAxisSpacing = props.crossAxisSpacing;
    this.closeToTrailing = props.closeToTrailing;
  }
}

// ===== 瀑布流容器 =====
//
// 对应 Dart 的 `WaterfallFlow(children: [...], gridDelegate: ...)`：
// 与 GridView / ListView 一样是「普通构造 + children 列表」形态，
// 宿主按同名 widget 渲染。
export class WaterfallFlow extends Component {
  static __fnProps = [];
}
