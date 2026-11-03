/// 当前代码是否运行在 JS 热更产物里。
///
/// 与 `kDebugMode` / `kReleaseMode` 同类的**环境标志**：
///   - 生成器把对它的引用原样下发成同名 JS 标识符（见生成器 `globalFlagJs`），
///     不在产物里声明；
///   - 宿主求值 `runtime.js` 之前注入同名全局，JS 侧恒为 `true`
///     （见 JsRuntimeManager 的环境变量注入）；
///   - 本文件里的声明值是**原生侧**的取值，恒为 `false`。
///
/// 因此同一份 Dart 源码可以在两端走各自的分支，例如 GlobalKey 量测：
/// JS 侧 `findRenderObject()` 返回 KeyRef 代理（`measure()` 经宿主异步桥回填），
/// 原生侧返回真实 RenderObject（按 RenderBox 的同步属性计算）。
const bool kInJsRuntime = false;
