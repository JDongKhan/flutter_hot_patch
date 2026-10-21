import 'package:flutter/foundation.dart';

import '../utils/hot_patch_log.dart';

/// 宿主侧的一个渲染结点：JS 对象树被 flatten 后的单位。
///
/// [props] 是 JS 侧原样下发的 Map（含事件句柄 `{'__fn': id}`）；
/// [childIds] 指向子结点，宿主据此递归渲染 [_JsNode]。
class JsUiNode {
  JsUiNode({required this.type, required this.props});

  final String type;
  Map<String, dynamic> props;
  final List<String> childIds = [];

  /// 值为 element 的 props（如 ListTile.leading / Scaffold.body）：
  /// prop 名 -> 子结点 id。宿主据此把对应 prop 渲染成 widget。
  final Map<String, String> propChildIds = {};

  /// 值为 element 数组的 props（如 AppBar.actions / ListView.children）：
  /// prop 名 -> 子结点 id 列表。
  final Map<String, List<String>> propChildLists = {};

  /// delegate 等非 Widget 的 slot 描述（如 SliverChildBuilderDelegate 的
  /// `{__delegate:'builder', builder, childCount}`）：prop 名 -> 原始值。
  final Map<String, dynamic> propData = {};
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

  /// remove 的父结点定位自适应策略：结点少时全表扫一次是微秒级、零额外内存；
  /// 结点多（大列表高频增删）时每次 remove 都 O(N) 不可接受。阈值
  /// [_parentIndexThreshold]：达到后一次性建 `childId → parentId` 反向索引，
  /// 并由各 mutation op 同步维护（remove 降为 O(子树规模)）；回落到阈值以下
  /// 丢弃索引回到扫描模式——索引只服务 remove，其余 op 本来 O(1)，不为它们
  /// 常驻一张表。
  static const int _parentIndexThreshold = 2000;

  /// childId → parentId（childIds 与 propChildIds 合一；树不变式保证单父）。
  /// null = 扫描模式（结点 < 阈值）。
  Map<String, String>? _parents;

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
            _parents?[id] = raw['parent'] as String;
          }
          touched.add(raw['parent'] as String);
        case 'move':
          // 同一父结点内换位，父子关系不变，索引无需更新。
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
          // 覆盖同 key 旧子时，旧子的反向索引一并摘除（它不再是本结点的子）。
          final replaced = parent.propChildIds[key];
          if (replaced != null && replaced != childId) {
            _parents?.remove(replaced);
          }
          parent.propChildIds[key] = childId;
          _parents?[childId] = raw['parent'] as String;
          touched.add(raw['parent'] as String);
        case 'propsChildRemove':
          final parent = nodes[raw['parent']];
          final key = raw['key'] as String?;
          if (parent == null || key == null) break;
          final removed = parent.propChildIds.remove(key);
          if (removed != null) _parents?.remove(removed);
          touched.add(raw['parent'] as String);
        case 'propsChildren':
          final parent = nodes[raw['parent']];
          final key = raw['key'] as String?;
          if (parent == null || key == null) break;
          final ids = <String>[
            for (final id in (raw['childIds'] as List? ?? const [])) '$id',
          ];
          for (final old in parent.propChildLists[key] ?? const <String>[]) {
            _parents?.remove(old);
          }
          parent.propChildLists[key] = ids;
          for (final id in ids) {
            _parents?[id] = raw['parent'] as String;
          }
          touched.add(raw['parent'] as String);
        case 'propsData':
          final parent = nodes[raw['parent']];
          final key = raw['key'] as String?;
          if (parent == null || key == null) break;
          parent.propData[key] = raw['value'];
          touched.add(raw['parent'] as String);
        case 'propsDataRemove':
          final parent = nodes[raw['parent']];
          final key = raw['key'] as String?;
          if (parent == null || key == null) break;
          parent.propData.remove(key);
          touched.add(raw['parent'] as String);
        case 'remove':
          final id = raw['id'] as String?;
          if (id == null) break;
          // 先记下父结点：`_JsNodeState.build` 只按 `node.childIds` 渲染，
          // 摘除子结点后父结点必须重建，否则宿主侧会继续渲染已被删除的子树
          // （表现为：筛选弹框关不掉、切换筛选条件后列表不刷新）。
          // 索引模式 O(1) 定位；扫描模式全表找（小页面成本可忽略）。
          final idx = _parents;
          final parents = <String>[
            if (idx != null)
              ?idx[id]
            else
              for (final entry in nodes.entries)
                if (entry.value.childIds.contains(id) ||
                    entry.value.propChildIds.containsValue(id) ||
                    entry.value.propChildLists.values.any(
                      (ids) => ids.contains(id),
                    ))
                  entry.key,
          ];
          _unlink(id);
          _removeSubtree(id);
          touched.remove(id);
          touched.addAll(parents);
        default:
          // 未知 op：JS 侧下发了宿主不认识的指令。静默丢弃会让 JS 状态与
          // 宿主渲染悄悄分叉（与「未注册组件」同性质）——必须留痕。
          HotPatchLog.warn('js_ui: unknown op "${raw['op']}" dropped');
      }
    }
    for (final id in touched) {
      _rebuilders[id]?.call();
    }
    _syncParentIndex();
  }

  /// 批量 op 应用完后按当前结点规模升/降级父索引（见 [_parents] 注释）。
  /// 升级 O(N) 一次建表；降级直接丢弃。批末同步：跨阈值那一批内的 remove
  /// 走的还是旧模式，语义不变、成本可忽略。
  void _syncParentIndex() {
    final idx = _parents;
    if (idx == null && nodes.length >= _parentIndexThreshold) {
      final built = <String, String>{};
      for (final e in nodes.entries) {
        for (final c in e.value.childIds) {
          built[c] = e.key;
        }
        e.value.propChildIds.forEach((_, c) => built[c] = e.key);
        for (final ids in e.value.propChildLists.values) {
          for (final c in ids) {
            built[c] = e.key;
          }
        }
      }
      _parents = built;
    } else if (idx != null && nodes.length < _parentIndexThreshold) {
      _parents = null;
    }
  }

  static int _index(Object? v, int length) {
    final i = v is num ? v.toInt() : 0;
    return i.clamp(0, length);
  }

  static Map<String, dynamic> _props(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

  void _unlink(String id) {
    // 索引模式：只从已知父结点摘除（O(父度)）；扫描模式：全表找父（树不变式
    // 保证最多一个父，找到即止的效果与全扫等价）。
    final idx = _parents;
    if (idx != null) {
      final p = idx.remove(id);
      final parent = p == null ? null : nodes[p];
      if (parent != null) {
        parent.childIds.remove(id);
        parent.propChildIds.removeWhere((_, childId) => childId == id);
        for (final ids in parent.propChildLists.values) {
          ids.remove(id);
        }
      }
      return;
    }
    for (final node in nodes.values) {
      node.childIds.remove(id);
      node.propChildIds.removeWhere((_, childId) => childId == id);
      for (final ids in node.propChildLists.values) {
        ids.remove(id);
      }
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
    for (final ids in node?.propChildLists.values ?? const <List<String>>[]) {
      for (final child in ids) {
        _removeSubtree(child);
      }
    }
    _parents?.remove(id);
    nodes.remove(id);
  }
}

/// 页面 key → 该页面的 [JsUiStore]（全局注册表）。
///
/// 多 JsUiWidget 共用单 runtime 时，`jsuiCommit` 补丁带页面 key 下发；宿主
/// 的 `jsuiCommit` 处理器据此表把补丁路由到对应页面。JsUiWidget 在 initState
/// 登记、dispose 移除——这是「页面级路由」的唯一落点。
final Map<String, JsUiStore> jsUiPageStores = {};