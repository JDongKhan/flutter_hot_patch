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

class MultiProviderComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var provs = this.props.providers || [];
    var node = this.props.child;
    for (var i = provs.length - 1; i >= 0; i--) {
      node = __h(provs[i].type, provs[i].props, [node]);
    }
    return node;
  }
}
export function MultiProvider(props, children) {
  return __h(MultiProviderComponent, props, children);
}
