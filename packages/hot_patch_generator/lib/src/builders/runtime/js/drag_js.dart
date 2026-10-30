// ===== 能力：拖拽（JS 侧片段）=====
//
// 拖拽的语义是「把**任意 JS 值**从一个结点搬到另一个结点」：`Draggable.data`
// 可以是模型实例、闭包、数组。跨桥只有 JSON，这些值传过去就只剩一份快照
// （身份、闭包、方法全丢）。因此本片段建一张按**身份**索引的引用表：
//   - 元素构造时 `data` → `jsui_drag_N`，宿主只看到这个 id（它的唯一用途是与
//     Flutter 原生拖动系统对齐，宿主不需要认识数据内容）；
//   - 事件（onDragEnd / onAcceptWithDetails / onDragUpdate…）回到 JS 时按 id
//     换回原引用，于是 `details.data` 与 Dart 里 `draggable.data` 是**同一个
//     对象**，`details.data.name` / 方法调用 / 身份比较全部成立。
//
// 表按值只登记一次（对象按身份、标量按相等），体积 = 不同 data 值的个数，
// 不随拖动次数增长。
//
// 本片段与它的两个使用者（Draggable / LongPressDraggable / DragTarget 的组件类）
// 同属基础包 `patch/flutter.js`，故这里用模块级函数而非全局出口。
const String dragJsSource = r'''
  // ── data 身份表：任意 JS 值 ⇄ 跨桥 id ──
  var __dragDataSeq = 0;
  var __dragDataIds = new Map();
  var __dragDataRefs = new Map();

  function __dragRef(value) {
    if (value == null) { return null; }
    var id = __dragDataIds.get(value);
    if (id) { return id; }
    id = 'jsui_drag_' + (++__dragDataSeq);
    __dragDataIds.set(value, id);
    __dragDataRefs.set(id, value);
    return id;
  }

  function __dragData(id) {
    if (id == null) { return null; }
    return __dragDataRefs.has(id) ? __dragDataRefs.get(id) : id;
  }

  function __dragDataList(ids) {
    var out = [];
    if (!ids) { return out; }
    for (var i = 0; i < ids.length; i++) { out.push(__dragData(ids[i])); }
    return out;
  }

  // ── 事件详情还原：宿主只发 JSON（位置 → {dx, dy}，速度 → {pxPerSecond}）──
  function __dragOffset(json) {
    json = json || {};
    return new Offset({
      dx: json.dx == null ? 0 : json.dx,
      dy: json.dy == null ? 0 : json.dy,
    });
  }

  function __dragUpdateDetails(json) {
    json = json || {};
    return {
      globalPosition: __dragOffset(json.globalPosition),
      localPosition: __dragOffset(json.localPosition),
      delta: __dragOffset(json.delta),
      primaryDelta: json.primaryDelta == null ? null : json.primaryDelta,
      sourceTimeStamp: json.sourceTimeStampUs == null
        ? null
        : new Duration({ microseconds: json.sourceTimeStampUs }),
    };
  }

  // `DraggableDetails`：字段与 Flutter 一致（**没有** `data`——负载要用用户
  // 自己的闭包变量），`velocity` 是 Velocity 实例。
  function __draggableDetails(json) {
    json = json || {};
    return {
      wasAccepted: json.wasAccepted === true,
      offset: __dragOffset(json.offset),
      velocity: new Velocity({
        pixelsPerSecond: __dragOffset(json.velocity && json.velocity.pxPerSecond),
      }),
    };
  }

  function __dragTargetDetails(json) {
    json = json || {};
    return { data: __dragData(json.data), offset: __dragOffset(json.offset) };
  }

  // ── Draggable / LongPressDraggable 共用的 props 折算 ──
  // `data` 换成 id、四个事件换成句柄（用户回调留在本侧，宿主只回传 id / 位置）。
  // 两个类共用本函数、各自给出宿主 type 名（不做「是不是某个类」的判断）。
  function __dragSourceProps(self) {
    var p = self.props || {};
    var props = {};
    for (var k in p) {
      if (k === 'data' || k === 'onDragStarted' || k === 'onDragUpdate' ||
          k === 'onDragEnd' || k === 'onDragCompleted') { continue; }
      props[k] = p[k];
    }
    props.data = __dragRef(p.data);
    // 同一位点复用同一句柄：重建不新增跨语言句柄，卸载随实例释放。
    props.onDragStarted = self.__bindFn(0, [], function () {
      var f = self.props.onDragStarted;
      if (typeof f === 'function') { f(); }
    });
    props.onDragUpdate = self.__bindFn(1, [], function (json) {
      var f = self.props.onDragUpdate;
      if (typeof f === 'function') { f(__dragUpdateDetails(json)); }
    });
    props.onDragEnd = self.__bindFn(2, [], function (json) {
      var f = self.props.onDragEnd;
      if (typeof f === 'function') { f(__draggableDetails(json)); }
    });
    props.onDragCompleted = self.__bindFn(3, [], function () {
      var f = self.props.onDragCompleted;
      if (typeof f === 'function') { f(); }
    });
    return props;
  }

  // ── DragTarget 的 props 折算 ──
  // `builder(context, candidateData, rejectedData)` 只能在 JS 里执行（候选/被拒
  // 数据只在悬停时由宿主产生），与 LayoutBuilder 同一方案：登记成句柄，宿主
  // 回调时把**id 列表**带回来，本侧换回原值后执行 builder，结果作为 `child`
  // 插槽随下一次 patch 回填。
  //
  // `onWillAccept` / `onWillAcceptWithDetails` 需要**同步**返回 bool，跨语言只能
  // 异步，故不接（宿主侧恒接受），并用一条警告把这件事说清楚。
  function __dragTargetProps(self, context) {
    var p = self.props || {};
    var builder = p.builder;
    if (typeof builder !== 'function') {
      console.warn('[DragTarget] builder 不是闭包');
      return null;
    }
    if (typeof p.onWillAccept === 'function' ||
        typeof p.onWillAcceptWithDetails === 'function') {
      console.warn(
        '[DragTarget] onWillAccept / onWillAcceptWithDetails 需要同步返回值，' +
        '跨语言只能异步，已忽略（目标恒接受）'
      );
    }
    var props = {};
    for (var k in p) {
      if (k === 'builder' || k === 'onWillAccept' || k === 'onWillAcceptWithDetails' ||
          k === 'onAccept' || k === 'onAcceptWithDetails' ||
          k === 'onMove' || k === 'onLeave') { continue; }
      props[k] = p[k];
    }
    // 悬停时宿主会反复回调：同一次候选集合只重建一次子树（id 列表即身份签名）。
    props.builder = self.__bindFn(0, [], function (json) {
      json = json || {};
      var sig = (json.candidate || []).join('|') + '#' + (json.rejected || []).join('|');
      if (sig === self.__dragSig) { return; }
      self.__dragSig = sig;
      // 字段名不能叫 `__child`：那是 reconciler 记录本实例挂出的子宿主结点的
      // 内部字段，props 里再塞它会成环。
      self.__dragTargetChild = builder(
        context, __dragDataList(json.candidate), __dragDataList(json.rejected));
      self.setState(function () {});
    });
    props.onAccept = self.__bindFn(1, [], function (id) {
      var f = self.props.onAccept;
      if (typeof f === 'function') { f(__dragData(id)); }
    });
    props.onAcceptWithDetails = self.__bindFn(2, [], function (json) {
      var f = self.props.onAcceptWithDetails;
      if (typeof f === 'function') { f(__dragTargetDetails(json)); }
    });
    props.onMove = self.__bindFn(3, [], function (json) {
      var f = self.props.onMove;
      if (typeof f === 'function') { f(__dragTargetDetails(json)); }
    });
    props.onLeave = self.__bindFn(4, [], function (id) {
      var f = self.props.onLeave;
      if (typeof f === 'function') { f(__dragData(id)); }
    });
    if (self.__dragTargetChild != null) { props.child = self.__dragTargetChild; }
    return props;
  }
''';
