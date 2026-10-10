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

export function AspectRatio(props, children) {
  return __h('AspectRatio', props, children);
}

export function BottomNavigationBar(props, children) {
  return __h('BottomNavigationBar', props, children);
}

export function BottomNavigationBarItem(props, children) {
  return __h('BottomNavigationBarItem', props, children);
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

export function CircularProgressIndicator(props, children) {
  return __h('CircularProgressIndicator', props, children);
}

export function ClipRRect(props, children) {
  return __h('ClipRRect', props, children);
}

export function Column(props, children) {
  return __h('Column', props, children);
}

export function ConstrainedBox(props, children) {
  return __h('ConstrainedBox', props, children);
}

export function Container(props, children) {
  return __h('Container', props, children);
}

export function CustomScrollView(props, children) {
  return __h('CustomScrollView', props, children);
}

export function DecoratedBox(props, children) {
  return __h('DecoratedBox', props, children);
}

export function Divider(props, children) {
  return __h('Divider', props, children);
}

export function DropdownButton(props, children) {
  return __h('DropdownButton', props, children);
}

export function DropdownMenuItem(props, children) {
  return __h('DropdownMenuItem', props, children);
}

export function Expanded(props, children) {
  return __h('Expanded', props, children);
}

export function Flexible(props, children) {
  return __h('Flexible', props, children);
}

export function FloatingActionButton(props, children) {
  return __h('FloatingActionButton', props, children);
}

export function FractionallySizedBox(props, children) {
  return __h('FractionallySizedBox', props, children);
}

export function GestureDetector(props, children) {
  return __h('GestureDetector', props, children);
}

export function Icon(props, children) {
  return __h('Icon', props, children);
}

export function IconButton(props, children) {
  return __h('IconButton', props, children);
}

export function Image(props, children) {
  return __h('Image', props, children);
}

export function InkWell(props, children) {
  return __h('InkWell', props, children);
}

export function LinearProgressIndicator(props, children) {
  return __h('LinearProgressIndicator', props, children);
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

export function NotificationListener(props, children) {
  return __h('NotificationListener', props, children);
}

export function Opacity(props, children) {
  return __h('Opacity', props, children);
}

export function Padding(props, children) {
  return __h('Padding', props, children);
}

export function Positioned(props, children) {
  return __h('Positioned', props, children);
}

export function Radio(props, children) {
  return __h('Radio', props, children);
}

export function Row(props, children) {
  return __h('Row', props, children);
}

export function SafeArea(props, children) {
  return __h('SafeArea', props, children);
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

export function SliverAppBar(props, children) {
  return __h('SliverAppBar', props, children);
}

export function SliverFillRemaining(props, children) {
  return __h('SliverFillRemaining', props, children);
}

export function SliverGrid(props, children) {
  return __h('SliverGrid', props, children);
}

export function SliverList(props, children) {
  return __h('SliverList', props, children);
}

export function SliverPadding(props, children) {
  return __h('SliverPadding', props, children);
}

export function SliverToBoxAdapter(props, children) {
  return __h('SliverToBoxAdapter', props, children);
}

export function Spacer(props, children) {
  return __h('Spacer', props, children);
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

export function TextField(props, children) {
  return __h('TextField', props, children);
}

export function Wrap(props, children) {
  return __h('Wrap', props, children);
}
