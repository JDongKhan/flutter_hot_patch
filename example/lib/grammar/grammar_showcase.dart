import 'package:flutter/material.dart';

import '../components/widget_showcase.dart';

/// 基础语法导航列表页（普通页面，无 @PatchEntry 注解）：
/// 与「常用组件 · 列表」同级，点击条目进入对应详情页（原生 vs JS 热更）。
///
/// 每个语法家族一个源文件（`<语法>_detail.dart`），产物路径由 build_runner
/// 镜像源文件生成，入口映射见 [WidgetDetailPage] 的 `_jsEntries`。
class GrammarShowcase extends StatelessWidget {
  const GrammarShowcase({super.key});

  static const List<_Entry> _entries = [
    _Entry('Mixin · State 扩展', 'State 混入跨包 StateLogMixin：点击时打印状态日志', 'MixinDetail'),
    _Entry('Extension · String 扩展', 'String 扩展跨包 logText 与运算符、显式调用', 'ExtensionDetail'),
    _Entry('extends · 类继承', 'Greeting 基类与 FancyGreeting 子类：super 调用与多态', 'InheritanceDetail'),
    _Entry('基础 api', 'DateTime / RegExp / StringBuffer：dart:core 值类的一比一 JS 镜像', 'BasicApiDetail'),
    _Entry('枚举 · enum', 'values / name / index / byName / toString 与 switch 分支', 'EnumDetail'),
    _Entry('命名构造 · factory', 'this.x 形参 / 初始化列表 / factory 委托 / 默认构造', 'ConstructorDetail'),
    _Entry('空安全', 'a?.m() / a?[i] / 空安全赋值 / 多层空安全链', 'NullSafetyDetail'),
    _Entry('模式匹配', 'if-case / 解构 / 关系 / 列表 / switch 表达式与语句', 'PatternDetail'),
    _Entry('record', '位置 / 命名 / 混合字面量与 record 模式解构', 'RecordDetail'),
    _Entry('运算符重载 · setter', '自定义 + / 一元 - / ==，setter 与 hashCode 契约', 'OperatorDetail'),
    _Entry('可调用对象 · call', 'call → invoke、Function.call、函数值立即调用', 'CallableDetail'),
    _Entry('函数 · 形参 · tear-off', '局部函数、可选/具名形参、方法与对象 tear-off', 'FunctionDetail'),
    _Entry('表达式', '位运算/移位、赋值表达式、级联、throw 表达式', 'ExpressionDetail'),
    _Entry('语句', '多 catch + on 过滤、rethrow、label 与 break', 'StatementDetail'),
    _Entry('集合字面量', 'if / for 元素、... 展开、三段式 for 元素', 'CollectionDetail'),
    _Entry('异步 · Completer', 'async / await、Future.delayed、Completer 的 complete / completeError', 'AsyncDetail'),
    _Entry('生成器 · sync*', 'sync* / yield / yield*：方法、局部函数、闭包与 Iterable 成员', 'GeneratorDetail'),
    _Entry('Stream · 异步流', 'async* / listen / await for / StreamController / broadcast', 'StreamDetail'),
    _Entry('泛型 · 类 / 方法泛型', 'GenericBox<T> / Pair<K,V> 与 context.watch<T>()：typeArguments 元信息', 'GenericDetail'),
    _Entry('import 别名 · as', '同名类与包模块类靠前缀区分：base.User / p.ChangeNotifierProvider', 'AliasDetail'),
    _Entry('数组 · List 语义', 'sort / join / indexOf / fold / any / expand / take / skip / length 写等', 'ArrayDetail'),
    _Entry('映射 · Map 语义', 'length / keys / values / entries / forEach / remove / putIfAbsent / update / addAll 等', 'MapDetail'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final e in _entries)
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(e.title),
            subtitle: Text(e.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => WidgetDetailPage(component: e.component)),
            ),
          ),
      ],
    );
  }
}

class _Entry {
  final String title;
  final String subtitle;
  final String component;
  const _Entry(this.title, this.subtitle, this.component);
}
