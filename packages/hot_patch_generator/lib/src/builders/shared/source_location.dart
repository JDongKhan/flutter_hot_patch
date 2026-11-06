/// 构建期日志的源码定位：把 `(文件, AST 结点)` 格式化成
/// `<文件>:<行>  |  <该行源码>`。
///
/// 行号来自**解析结果**（[registerSource] 在解析处登记 `LineInfo` + 原文），
/// 不在日志点重复解析 / 猜行号。拿不到定位信息时退回只带文件路径，绝不伪造
/// 行号。片段只取该行原文（去掉行首缩进），用于在终端里直接认出问题代码。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

/// 源文件身份（`lib/...` / `package:foo/...` / 绝对路径）→ 解析期信息。
final Map<String, _SourceInfo> _sources = {};

class _SourceInfo {
  _SourceInfo(this.lineInfo, this.lines);

  final LineInfo lineInfo;
  final List<String> lines;
}

/// 登记一个已解析文件的定位信息（解析处调用一次即可）。
///
/// [path] 必须与日志里使用的路径**同一身份**（如 builder 的 `inputId.path`、
/// `parseUnitFile` 的入参）。
void registerSource(String path, String content, LineInfo lineInfo) {
  _sources[path] = _SourceInfo(lineInfo, content.split('\n'));
}

/// 产物中间态（元素结点 Map / 值 Map）→ 生成它的 AST 结点。
///
/// 渲染阶段（element2js）拿到的只有中立描述 Map、没有 AST；由生产处
/// （element_json / value_forms）登记一次，告警时按 Map 身份取回源码位置。
/// 只影响构建期日志，不进任何产物。
final Expando<AstNode> _nodeSources = Expando<AstNode>();

/// 登记「这份中间态描述来自哪个 AST 结点」。
void registerNodeSource(Object node, AstNode? source) {
  if (source != null) _nodeSources[node] = source;
}

/// 取回 [registerNodeSource] 登记过的 AST 结点；未登记返回 null。
AstNode? nodeSourceOf(Object? node) => node == null ? null : _nodeSources[node];

/// 构建期日志前缀：`<path>:<line>  |  <code>`（无定位时只返回 [path]）。
///
/// [node] 为触发的 AST 结点（表达式 / 语句 / 声明均可）。
String sourceAt(String path, AstNode? node) {
  final info = _sources[path];
  if (node == null || info == null) return path;
  // 定位到**声明本体**而不是文档注释 / 注解：带 `///` 的声明里，
  // `node.offset` 指向注释首行，看日志时对不上代码。
  final offset = node is AnnotatedNode
      ? node.firstTokenAfterCommentAndMetadata.offset
      : node.beginToken.offset;
  final line = info.lineInfo.getLocation(offset).lineNumber;
  if (line <= 0 || line > info.lines.length) return '$path:$line';
  final code = info.lines[line - 1].trim();
  return code.isEmpty ? '$path:$line' : '$path:$line  |  $code';
}
