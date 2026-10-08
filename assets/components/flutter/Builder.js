// GENERATED CODE - DO NOT EDIT
// widget 模块（package: flutter）：由 ui_component_generator 生成
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

class BuilderComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    return owner[name].call(owner);
  }
}
export function Builder(props, children) {
  return __h(BuilderComponent, props, children);
}
