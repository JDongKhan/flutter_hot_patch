import 'package:flutter/foundation.dart';

/// 宿主侧的一个渲染结点：JS 对象树被 flatten 后的单位。
///
/// [props] 是 JS 侧原样下发的 Map（含事件句柄 `{'__fn': id}`）；
/// [childIds] 指向子结点，宿主据此递归渲染 [_JsNode]。
class JsUiNode {
  JsUiNode({required this.type, required this.props});

  final String type;
  Map<String, dynamic> props;
  final List<String> childIds = [];

  /// 值为 element 的 props（如 ListTile.leading / ClipRRect.child）：
  /// prop 名 -> 子结点 id。宿主据此把对应 prop 渲染成 widget。
  final Map<String, String> propChildIds = {};
}

/// 结点仓库 + 补丁应用器。
///
/// **宿主侧唯一的"状态"**：只是一张 `id -> 结点` 表。JS 侧算好增量后
/// 通过 `jsuiCommit` 通道下发 patch，本类按 op 改写表并只重建受影响的结点
/// ——不重建整棵树，也不理解任何状态库语义。
class JsUiStore {
  /// 全部结点（id 由 JS 侧分配，仅在本页面内唯一）。
  final Map<String, JsUiNode> nodes = {};

  /// id -> 该结点 _JsNodeState 的重建回调（挂载时登记、卸载时注销）。
  final Map<String, VoidCallback> _rebuilders = {};

  /// 根结点发生变化时回调（首次 commit 时确定根 id）。
  void Function(String id)? onRoot;

  void bind(String id, VoidCallback rebuild) => _rebuilders[id] = rebuild;

  void unbind(String id, VoidCallback rebuild) {
    if (identical(_rebuilders[id], rebuild)) _rebuilders.remove(id);
  }

  /// 应用一批 patch op，然后只重建被触碰到的结点。
  void apply(List<dynamic> ops) {
    final touched = <String>{};
    for (final raw in ops) {
      if (raw is! Map) continue;
      switch (raw['op']) {
        case 'root':
          final id = raw['id'] as String?;
          if (id != null) onRoot?.call(id);
        case 'create':
          final id = raw['id'] as String?;
          if (id == null) break;
          nodes[id] = JsUiNode(type: '${raw['type']}', props: _props(raw['props']));
          touched.add(id);
        case 'insert':
          final parent = nodes[raw['parent']];
          final id = raw['id'] as String?;
          if (parent == null || id == null) break;
          if (!parent.childIds.contains(id)) {
            parent.childIds.insert(_index(raw['index'], parent.childIds.length), id);
          }
          touched.add(raw['parent'] as String);
        case 'move':
          final parent = nodes[raw['parent']];
          final id = raw['id'] as String?;
          if (parent == null || id == null) break;
          parent.childIds.remove(id);
          parent.childIds.insert(_index(raw['index'], parent.childIds.length), id);
          touched.add(raw['parent'] as String);
        case 'props':
          final node = nodes[raw['id']];
          if (node == null) break;
          node.props = _props(raw['props']);
          touched.add(raw['id'] as String);
        case 'propsChild':
          final parent = nodes[raw['parent']];
          final key = raw['key'] as String?;
          final childId = raw['childId'] as String?;
          if (parent == null || key == null || childId == null) break;
          parent.propChildIds[key] = childId;
          touched.add(raw['parent'] as String);
        case 'propsChildRemove':
          final parent = nodes[raw['parent']];
          final key = raw['key'] as String?;
          if (parent == null || key == null) break;
          parent.propChildIds.remove(key);
          touched.add(raw['parent'] as String);
        case 'remove':
          final id = raw['id'] as String?;
          if (id == null) break;
          _unlink(id);
          _removeSubtree(id);
          touched.remove(id);
      }
    }
    for (final id in touched) {
      _rebuilders[id]?.call();
    }
  }

  static int _index(Object? v, int length) {
    final i = v is num ? v.toInt() : 0;
    return i.clamp(0, length);
  }

  static Map<String, dynamic> _props(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

  void _unlink(String id) {
    for (final node in nodes.values) {
      node.childIds.remove(id);
      node.propChildIds.removeWhere((_, childId) => childId == id);
    }
  }

  void _removeSubtree(String id) {
    final node = nodes[id];
    for (final child in node?.childIds ?? const <String>[]) {
      _removeSubtree(child);
    }
    for (final child in node?.propChildIds.values ?? const <String>[]) {
      _removeSubtree(child);
    }
    nodes.remove(id);
  }
}