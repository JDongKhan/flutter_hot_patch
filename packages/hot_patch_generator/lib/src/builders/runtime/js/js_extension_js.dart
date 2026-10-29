// Dart `extension` 的运行时注册机制（能力内聚，与其它 `*_js.dart` 同目录）。
//
// **调用面与 Dart 完全一致**：扩展方法在 Dart 里就是目标类型上的成员，
// 产物里的调用点因此**原样**写成 `x.logText(...)`——生成器不为扩展做任何
// 名字映射，注册在这里把成员装到目标类型的原型上。
//
// 生成器在**扩展声明处**发射一行注册（模块求值时执行一次）：
//
//   export const StringLogExtension = __jsExtension("String",
//     (function () { "use strict"; return {
//       logText: function (tag) { ... }
//     }; })(),
//     { id: "lib/src/string_log_extension.dart#StringLogExtension" });
//
//   严格模式包装见生成器（extension_support.dart）：脚本里以原始值作接收者时
//   `this` 才会是那个值本身，而不是装箱后的 `new String(...)`。
//
//   - target：Dart 目标类型名（字符串，由 [__jsExtensionTargetOf] 解析），或
//     直接给构造函数（跨产物 import 到的类；同一模块表保证是同一个类）；
//   - members：原型成员表——函数 = 方法，`{ get }` / `{ set }` = 访问器；
//   - opts.id：稳定标识（`<源文件>#<扩展名>`）。**同 id 再注册 = 热更自愈**：
//     先卸掉上一次装上的成员再按最新定义重装（模块被重新求值时不会残留旧实现，
//     也不会因「原型上已有」而被误判为冲突）；
//   - opts.statics：扩展的静态成员（返回值，`ExtName.foo()` 用）。
//
// **成员可见性**与 Dart 一致：目标类型上已有同名成员（内建 / 继承 / 类自身）
// 时扩展成员**被遮蔽**，这里静默跳过；被**别的扩展**占用则 warn（先注册者
// 生效）。成员全部非枚举定义（不污染 for...in / Object.keys / JSON.stringify）。
const String jsExtensionJsSource = r'''
  // 类型名 → 构造函数：语言核心映射 → 运行时别名表 → G[name]。
  // 三者都取不到时返回 null（调用方 console.error，不静默吞掉）。
  function __jsExtensionTargetOf(target) {
    if (typeof target !== 'string') return target || null;
    switch (target) {
      case 'int':
      case 'num':
      case 'double': return Number;
      case 'String': return String;
      case 'bool': return Boolean;
      case 'List':
      case 'Iterable': return Array;
      case 'Set': return Set;
    }
    if (Object.prototype.hasOwnProperty.call(__jsTypeAliases, target)) {
      return __jsTypeAliases[target];
    }
    var g = G[target];
    return typeof g === 'function' ? g : null;
  }

  // 原型上的扩展登记簿（owners: 成员名 → 扩展 id）。非枚举挂在原型自身，
  // 用来区分「类/内建本来就有」（静默跳过）与「另一个扩展占了」（warn）。
  function __jsExtensionMeta(proto) {
    if (!Object.prototype.hasOwnProperty.call(proto, '__jsExtensionMeta')) {
      Object.defineProperty(proto, '__jsExtensionMeta', {
        value: { owners: {} },
        writable: true,
        enumerable: false,
        configurable: true
      });
    }
    return proto.__jsExtensionMeta;
  }

  // id -> { proto, names }：同 id 再注册时据此卸载上一次的成员。
  var __jsExtensionRecords = {};
  var __jsExtensionSeq = 0;

  function __jsExtensionUninstall(id) {
    var rec = __jsExtensionRecords[id];
    if (!rec) return;
    var meta = __jsExtensionMeta(rec.proto);
    for (var i = 0; i < rec.names.length; i++) {
      var name = rec.names[i];
      if (meta.owners[name] === id) {
        delete meta.owners[name];
        // 成员一律 configurable，删除不会抛错；引擎实现差异用 try 兜住。
        try { delete rec.proto[name]; } catch (e) {}
      }
    }
    delete __jsExtensionRecords[id];
  }

  G.__jsExtension = function (target, members, opts) {
    opts = opts || {};
    var id = opts.id == null ? '' : String(opts.id);
    var statics = opts.statics || {};
    var ctor = __jsExtensionTargetOf(target);
    if (!ctor) {
      console.error('jsui: extension target not found: ' + String(target) +
        (id ? ' (' + id + ')' : ''));
      return statics;
    }
    var proto = ctor.prototype;
    if (!proto) {
      console.error('jsui: extension target has no prototype: ' + String(target));
      return statics;
    }
    if (id) __jsExtensionUninstall(id);
    var meta = __jsExtensionMeta(proto);
    var record = { proto: proto, names: [] };
    for (var name in members) {
      if (!Object.prototype.hasOwnProperty.call(members, name)) continue;
      // 目标上已有同名成员（含继承）：Dart 里显式成员优先于扩展，静默跳过。
      if (name in proto) {
        if (id && meta.owners[name] && meta.owners[name] !== id) {
          console.warn('jsui: extension member conflict: ' + name +
            ' already provided by ' + meta.owners[name] +
            ' (later registration ignored)');
        }
        continue;
      }
      var member = members[name];
      if (typeof member === 'function') {
        Object.defineProperty(proto, name, {
          value: member,
          writable: true,
          enumerable: false,
          configurable: true
        });
      } else {
        Object.defineProperty(proto, name, {
          get: member.get,
          set: member.set,
          enumerable: false,
          configurable: true
        });
      }
      __jsExtensionSeq += 1;
      meta.owners[name] = id || ('@' + __jsExtensionSeq);
      record.names.push(name);
    }
    if (id) __jsExtensionRecords[id] = record;
    return statics;
  };
''';
