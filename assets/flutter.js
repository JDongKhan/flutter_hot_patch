// GENERATED CODE - DO NOT EDIT
// package 模块（package: flutter）：由 ui_component_generator 生成
// 本包全部 widget 工厂集中于此文件；工厂返回 {type, props, children}

// 共享结点工厂：所有 package 模块与组件产物共用（本文件是它的唯一定义处）。
// 归一化 props/children，返回 {type, props, children} 元素描述，供运行时按
// type 映射 Flutter widget 或组件类。
export function __h(type, props, children) {
  return {
    type: type,
    props: props || {},
    children: children == null
        ? []
        : (Array.isArray(children) ? children : [children]),
  };
}


export function Align(props, children) {
  return __h('Align', props, children);
}

export function AppBar(props, children) {
  return __h('AppBar', props, children);
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

export function Button(props, children) {
  return __h('Button', props, children);
}

export function Card(props, children) {
  return __h('Card', props, children);
}

export function Center(props, children) {
  return __h('Center', props, children);
}

export function Checkbox(props, children) {
  return __h('Checkbox', props, children);
}

export function Chip(props, children) {
  return __h('Chip', props, children);
}

export function CircleAvatar(props, children) {
  return __h('CircleAvatar', props, children);
}

export function ClipRRect(props, children) {
  return __h('ClipRRect', props, children);
}

export function Column(props, children) {
  return __h('Column', props, children);
}

export function Container(props, children) {
  return __h('Container', props, children);
}

export function Divider(props, children) {
  return __h('Divider', props, children);
}

export function Expanded(props, children) {
  return __h('Expanded', props, children);
}

export function Flexible(props, children) {
  return __h('Flexible', props, children);
}

export function GestureDetector(props, children) {
  return __h('GestureDetector', props, children);
}

export function Icon(props, children) {
  return __h('Icon', props, children);
}

export function Image(props, children) {
  return __h('Image', props, children);
}

export function InkWell(props, children) {
  return __h('InkWell', props, children);
}

export function ListTile(props, children) {
  return __h('ListTile', props, children);
}

export function ListView(props, children) {
  return __h('ListView', props, children);
}

class ListenableBuilderComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  __owner() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  initState() {
    var owner = this.__owner();
    if (!owner) { return; }
    var l = owner[this.props.listenable];
    if (l && typeof l.addListener === 'function') {
      var self = this;
      this.__listenable = l;
      this.__listener = function () { self.setState(function () {}); };
      l.addListener(this.__listener);
    }
  }
  build() {
    var owner = this.__owner();
    if (!owner) { return null; }
    return owner[this.props.builder].call(owner);
  }
  dispose() {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
  }
}
export function ListenableBuilder(props, children) {
  return __h(ListenableBuilderComponent, props, children);
}

export function Padding(props, children) {
  return __h('Padding', props, children);
}

export function Positioned(props, children) {
  return __h('Positioned', props, children);
}

export function Row(props, children) {
  return __h('Row', props, children);
}

export function Scaffold(props, children) {
  return __h('Scaffold', props, children);
}

export function SingleChildScrollView(props, children) {
  return __h('SingleChildScrollView', props, children);
}

export function SizedBox(props, children) {
  return __h('SizedBox', props, children);
}

export function Slider(props, children) {
  return __h('Slider', props, children);
}

export function Stack(props, children) {
  return __h('Stack', props, children);
}

export function Switch(props, children) {
  return __h('Switch', props, children);
}

export function Text(props, children) {
  return __h('Text', props, children);
}

export function Wrap(props, children) {
  return __h('Wrap', props, children);
}
