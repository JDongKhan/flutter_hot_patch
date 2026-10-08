// GENERATED CODE - DO NOT EDIT
// widget 模块（package: provider）：由 ui_component_generator 生成
// 工厂函数返回 {type, props, children}，供组件产物按需 import

// 节点工厂：归一化 props/children，形状与生成器 JSON 字面量树一致。
function __h(type, props, children) {
  return {
    type: type,
    props: props || {},
    children: children == null
        ? []
        : (Array.isArray(children) ? children : [children]),
  };
}

class ChangeNotifierProviderComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  initState() {
    var p = this.props;
    var vm = null, owns = false;
    if (p.create !== undefined && p.create !== null) {
      if (typeof p.create === 'function') { vm = new p.create(); }
      else { vm = p.create; }
      owns = true;
    } else if (p.value !== undefined && p.value !== null) {
      vm = p.value;
    }
    this.__value = vm;
    this.__ownsValue = owns;
    this.__provides = {};
    this.__provides[p.model] = this;
    this.__subs = [];
    if (vm && typeof vm.addListener === 'function') {
      var self = this;
      this.__listener = function () { self.__notify(); };
      vm.addListener(this.__listener);
    }
  }
  build() {
    // child 两种传入方式：直接使用时是 `props.child`（命名参数翻译成 prop）；
    // 被 MultiProvider 包裹时由 `__h(type, props, [node])` 放进 children。
    if (this.props.child != null) { return this.props.child; }
    return this.children.length ? this.children[0] : null;
  }
  dispose() {
    if (this.__ownsValue && this.__value &&
        typeof this.__value.dispose === 'function') {
      this.__value.dispose();
    }
  }
}
export function ChangeNotifierProvider(props, children) {
  return __h(ChangeNotifierProviderComponent, props, children);
}
